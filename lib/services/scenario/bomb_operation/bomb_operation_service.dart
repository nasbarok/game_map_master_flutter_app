import 'dart:async';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_scenario.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_state.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_team.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_site.dart';
import 'package:airsoft_game_map/services/api_service.dart';
import 'package:airsoft_game_map/services/websocket/bomb_operation_web_socket_handler.dart';
import 'package:airsoft_game_map/services/websocket/web_socket_game_session_handler.dart';

/// Service pour gérer l'état du scénario Opération Bombe
class BombOperationService {
  final ApiService _apiService;
  final BombOperationWebSocketHandler _bombOperationWebSocketHandler;

  // État actuel du scénario
  BombOperationState _currentState = BombOperationState.waiting;
  BombOperationState get currentState => _currentState;

  // Scénario actif
  BombOperationScenario? _activeScenario;
  BombOperationScenario? get activeScenario => _activeScenario;

  // Rôles des équipes (teamId -> rôle)
  final Map<int, BombOperationTeam> _teamRoles = {};
  Map<int, BombOperationTeam> get teamRoles => Map.unmodifiable(_teamRoles);

  // Sites de bombe actifs pour le round actuel
  final Set<int> _activeBombSites = {};
  Set<int> get activeBombSites => Set.unmodifiable(_activeBombSites);

  // Sites où une bombe est plantée
  final Set<int> _plantedBombSites = {};
  Set<int> get plantedBombSites => Set.unmodifiable(_plantedBombSites);

  // Temps restant pour la bombe active (en secondes)
  int _bombTimeRemaining = 0;
  int get bombTimeRemaining => _bombTimeRemaining;

  // Stream pour les mises à jour d'état
  final _stateStreamController = StreamController<BombOperationState>.broadcast();
  Stream<BombOperationState> get stateStream => _stateStreamController.stream;

  // Stream pour les mises à jour des sites de bombe
  final _bombSitesStreamController = StreamController<void>.broadcast();
  Stream<void> get bombSitesStream => _bombSitesStreamController.stream;

  // Timer pour le compte à rebours de la bombe
  Timer? _bombTimer;

  BombOperationService( this._apiService, this._bombOperationWebSocketHandler);

  /// Initialise le service avec le scénario actif
  Future<void> initialize(int gameSessionId) async {
    try {
      // Récupérer le scénario actif
      final response = await _apiService.get('game-sessions/$gameSessionId/bomb-operation');

      // Initialiser le scénario
      _activeScenario = BombOperationScenario.fromJson(response['scenario']);

      // Initialiser les rôles des équipes
      final teamRolesJson = response['teamRoles'] as Map<String, dynamic>;
      teamRolesJson.forEach((teamIdStr, roleStr) {
        final teamId = int.parse(teamIdStr);
        final role = BombOperationTeamExtension.fromString(roleStr);
        _teamRoles[teamId] = role;
      });

      // Initialiser les sites actifs
      final activeSitesJson = response['activeBombSites'] as List;
      _activeBombSites.clear();
      for (final siteId in activeSitesJson) {
        _activeBombSites.add(siteId as int);
      }

      // Initialiser l'état
      _currentState = BombOperationStateExtension.fromString(response['state']);

      // Initialiser les bombes plantées
      final plantedSitesJson = response['plantedBombSites'] as List;
      _plantedBombSites.clear();
      for (final siteId in plantedSitesJson) {
        _plantedBombSites.add(siteId as int);
      }

      // Initialiser le temps restant
      _bombTimeRemaining = response['bombTimeRemaining'] ?? 0;

      // Démarrer le timer si une bombe est plantée
      if (_currentState == BombOperationState.bombPlanted && _bombTimeRemaining > 0) {
        _startBombTimer();
      }

      // Notifier les écouteurs
      _stateStreamController.add(_currentState);
      _bombSitesStreamController.add(null);

      print('🧨 BombOperationService initialisé - gameSessionId: $gameSessionId');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du BombOperationService: $e');
    }
  }

  /// Gère les mises à jour d'état reçues via WebSocket
  void _handleBombOperationUpdate(Map<String, dynamic> data) {
    try {
      // Mettre à jour l'état
      final newState = BombOperationStateExtension.fromString(data['state']);
      _currentState = newState;

      // Mettre à jour les sites actifs si présents
      if (data['activeBombSites'] != null) {
        final activeSites = data['activeBombSites'] as List;
        _activeBombSites.clear();
        for (final siteId in activeSites) {
          _activeBombSites.add(siteId as int);
        }
      }

      // Mettre à jour les bombes plantées si présentes
      if (data['plantedBombSites'] != null) {
        final plantedSites = data['plantedBombSites'] as List;
        _plantedBombSites.clear();
        for (final siteId in plantedSites) {
          _plantedBombSites.add(siteId as int);
        }
      }

      // Mettre à jour le temps restant si présent
      if (data['bombTimeRemaining'] != null) {
        _bombTimeRemaining = data['bombTimeRemaining'];

        // Démarrer ou arrêter le timer selon l'état
        if (_currentState == BombOperationState.bombPlanted && _bombTimeRemaining > 0) {
          _startBombTimer();
        } else {
          _stopBombTimer();
        }
      }

      // Notifier les écouteurs
      _stateStreamController.add(_currentState);
      _bombSitesStreamController.add(null);

      print('🧨 État du scénario Bombe mis à jour - état: ${_currentState.displayName}');
    } catch (e) {
      print('❌ Erreur lors du traitement de la mise à jour du scénario Bombe: $e');
    }
  }

  /// Démarre le timer pour le compte à rebours de la bombe
  void _startBombTimer() {
    // Arrêter tout timer existant
    _stopBombTimer();

    // Créer un nouveau timer qui s'exécute chaque seconde
    _bombTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_bombTimeRemaining > 0) {
        _bombTimeRemaining--;
        _bombSitesStreamController.add(null); // Notifier pour mettre à jour l'affichage
      } else {
        _stopBombTimer();
      }
    });
  }

  /// Arrête le timer pour le compte à rebours de la bombe
  void _stopBombTimer() {
    _bombTimer?.cancel();
    _bombTimer = null;
  }

  /// Envoie une action pour planter une bombe sur un site
  Future<void> plantBomb(int fieldId, int gameSessionId, int bombSiteId) async {
    try {
      // Envoyer l'action via WebSocket
      _bombOperationWebSocketHandler.sendBombOperationAction(
        fieldId: fieldId,
        gameSessionId: gameSessionId,
        action: 'PLANT_BOMB',
        payload: {'bombSiteId': bombSiteId},
      );

      print('🧨 Action envoyée: planter une bombe sur le site $bombSiteId');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de l\'action de plantation de bombe: $e');
    }
  }

  /// Envoie une action pour désamorcer une bombe sur un site
  Future<void> defuseBomb(int fieldId, int gameSessionId, int bombSiteId) async {
    try {
      _bombOperationWebSocketHandler.sendBombOperationAction(
        fieldId: fieldId,
        gameSessionId: gameSessionId,
        action: 'DEFUSE_BOMB',
        payload: {'bombSiteId': bombSiteId},
      );

      print('🧨 Action envoyée: désamorcer la bombe sur le site $bombSiteId');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de l\'action de désamorçage de bombe: $e');
    }
  }

  /// Obtient tous les sites de bombe du scénario
  List<BombSite> getAllBombSites() {
    if (_activeScenario == null || _activeScenario!.bombSites == null) {
      return [];
    }
    return _activeScenario!.bombSites!;
  }

  /// Obtient les sites de bombe actifs pour le round actuel
  List<BombSite> getActiveBombSites() {
    if (_activeScenario == null || _activeScenario!.bombSites == null) {
      return [];
    }
    return _activeScenario!.bombSites!
        .where((site) => _activeBombSites.contains(site.id))
        .toList();
  }

  /// Obtient les sites de bombe où une bombe est plantée
  List<BombSite> getPlantedBombSites() {
    if (_activeScenario == null || _activeScenario!.bombSites == null) {
      return [];
    }
    return _activeScenario!.bombSites!
        .where((site) => _plantedBombSites.contains(site.id))
        .toList();
  }

  void dispose() {
    _stopBombTimer();
    _stateStreamController.close();
    _bombSitesStreamController.close();
    print('🧨 BombOperationService dispose');
  }

}
