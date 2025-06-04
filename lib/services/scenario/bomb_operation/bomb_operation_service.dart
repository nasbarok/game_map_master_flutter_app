import 'dart:async';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_scenario.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_state.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_team.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_site.dart';
import 'package:airsoft_game_map/services/api_service.dart';
import 'package:airsoft_game_map/services/websocket/bomb_operation_web_socket_handler.dart';
import 'package:airsoft_game_map/services/websocket/web_socket_game_session_handler.dart';
import 'package:airsoft_game_map/utils/logger.dart';

import '../../../models/scenario/bomb_operation/bomb_operation_session.dart';

/// Service pour gérer l'état du scénario Opération Bombe
class BombOperationService {
  final ApiService _apiService;
  final BombOperationWebSocketHandler _bombOperationWebSocketHandler;

  // État actuel du scénario
  BombOperationState _currentState = BombOperationState.waiting;

  BombOperationState get currentState => _currentState;

  // Scénario actif
  BombOperationSession? _sessionScenarioBomb;

  BombOperationSession? get activeSessionScenarioBomb => _sessionScenarioBomb;

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
  final _stateStreamController =
      StreamController<BombOperationState>.broadcast();

  Stream<BombOperationState> get stateStream => _stateStreamController.stream;

  // Stream pour les mises à jour des sites de bombe
  final _bombSitesStreamController = StreamController<void>.broadcast();

  Stream<void> get bombSitesStream => _bombSitesStreamController.stream;

  // Timer pour le compte à rebours de la bombe
  Timer? _bombTimer;

  BombOperationService(this._apiService, this._bombOperationWebSocketHandler);

  /// Initialise le service avec le scénario actif
  Future<void> initialize(int gameSessionId) async {
    try {
      logger.d('📡 [BombOperationService] [initialize] Récupération du scénario Bombe pour gameSessionId: $gameSessionId');

      final response = await _apiService.get(
        'game-sessions/bomb-operation/by-game-session/$gameSessionId',
      );

      logger.d('📥 [BombOperationService] [initialize] Réponse brute reçue: $response');


      _sessionScenarioBomb = BombOperationSession.fromJson(response);
      logger.d('✅ [BombOperationService] [initialize] Scénario initialisé: ${_sessionScenarioBomb?.id}');

      // Initialiser les rôles des équipes
      final teamRolesJson = response['teamRoles'];
      if (teamRolesJson == null) {
        throw Exception('Le champ "teamRoles" est nul ou absent');
      }
      teamRolesJson.forEach((teamIdStr, roleStr) {
        final teamId = int.parse(teamIdStr);
        final role = BombOperationTeamExtension.fromString(roleStr);
        _teamRoles[teamId] = role;
      });
      logger.d('✅ [BombOperationService] [initialize] Rôles des équipes: $_teamRoles');

      // Initialiser les sites actifs
      final activeSitesJson = response['activeBombSites'] as List? ?? [];
      _activeBombSites
        ..clear()
        ..addAll(activeSitesJson.cast<int>());
      logger.d('✅ [BombOperationService] [initialize] Sites actifs: $_activeBombSites');

      // Initialiser l'état
      final stateStr = response['state'];
      _currentState = BombOperationStateExtension.fromString(stateStr);
      logger.d('✅ [BombOperationService] [initialize] État actuel: $_currentState');

      // Initialiser les bombes plantées
      final plantedSitesJson = response['plantedBombSites'] as List? ?? [];
      _plantedBombSites
        ..clear()
        ..addAll(plantedSitesJson.cast<int>());
      logger.d('✅ [BombOperationService] [initialize] Bombes plantées: $_plantedBombSites');

      // Initialiser le temps restant
      _bombTimeRemaining = response['bombTimeRemaining'] ?? 0;
      logger.d('⏱️ [BombOperationService] [initialize] Temps restant: $_bombTimeRemaining sec');

      // Démarrer le timer si une bombe est plantée
      if (_currentState == BombOperationState.bombPlanted &&
          _bombTimeRemaining > 0) {
        logger.d('⏲️ [BombOperationService] [initialize] Démarrage du timer de bombe...');
        _startBombTimer();
      }

      // Notifier les écouteurs
      _stateStreamController.add(_currentState);
      _bombSitesStreamController.add(null);
      logger.d('🧨 [BombOperationService] [initialize] BombOperationService initialisé - gameSessionId: $gameSessionId');
    } catch (e, stack) {
      logger.d('❌ [BombOperationService] [initialize] Erreur: $e');
      logger.t(stack);
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
        if (_currentState == BombOperationState.bombPlanted &&
            _bombTimeRemaining > 0) {
          _startBombTimer();
        } else {
          _stopBombTimer();
        }
      }

      // Notifier les écouteurs
      _stateStreamController.add(_currentState);
      _bombSitesStreamController.add(null);

      logger.d(
          '🧨 État du scénario Bombe mis à jour - état: ${_currentState.displayName}');
    } catch (e) {
      logger.d(
          '❌ Erreur lors du traitement de la mise à jour du scénario Bombe: $e');
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
        _bombSitesStreamController
            .add(null); // Notifier pour mettre à jour l'affichage
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

      logger.d('🧨 Action envoyée: planter une bombe sur le site $bombSiteId');
    } catch (e) {
      logger.d(
          '❌ Erreur lors de l\'envoi de l\'action de plantation de bombe: $e');
    }
  }

  /// Envoie une action pour désamorcer une bombe sur un site
  Future<void> defuseBomb(
      int fieldId, int gameSessionId, int bombSiteId) async {
    try {
      _bombOperationWebSocketHandler.sendBombOperationAction(
        fieldId: fieldId,
        gameSessionId: gameSessionId,
        action: 'DEFUSE_BOMB',
        payload: {'bombSiteId': bombSiteId},
      );

      logger
          .d('🧨 Action envoyée: désamorcer la bombe sur le site $bombSiteId');
    } catch (e) {
      logger.d(
          '❌ Erreur lors de l\'envoi de l\'action de désamorçage de bombe: $e');
    }
  }

  /// Obtient tous les sites de bombe du scénario
  List<BombSite>? getAllBombSites() {
    if (_sessionScenarioBomb == null || _sessionScenarioBomb!.bombOperationScenario?.bombSites == null) {
      return [];
    }
    return _sessionScenarioBomb!.bombOperationScenario?.bombSites;
  }

  /// Obtient les sites de bombe actifs pour le round actuel
  /// Retourne les sites de bombe actifs pour le round en cours
  List<BombSite> getActiveBombSites() {
    final sessionScenarioBomb = _sessionScenarioBomb;
    if (sessionScenarioBomb == null) return [];

    final bombOperationScenario = sessionScenarioBomb.bombOperationScenario;
    if (bombOperationScenario == null) return [];

    final bombSites = bombOperationScenario.bombSites;
    if (bombSites == null || bombSites.isEmpty) return [];

    return bombSites.where((site) => _activeBombSites.contains(site.id)).toList();
  }
  /// Obtient les sites de bombe où une bombe est plantée
  /// Retourne les sites de bombe où une bombe est actuellement plantée
  List<BombSite> getPlantedBombSites() {
    final sessionScenarioBomb = _sessionScenarioBomb;
    if (sessionScenarioBomb == null) return [];

    final bombOperationScenario = sessionScenarioBomb.bombOperationScenario;
    if (bombOperationScenario == null || bombOperationScenario.bombSites == null) return [];

    final allBombSites = bombOperationScenario.bombSites!;
    return allBombSites
        .where((site) => _plantedBombSites.contains(site.id))
        .toList();
  }


  /// Sauvegarde les rôles des équipes pour une session de jeu
  Future<void> saveTeamRoles(
      int gameSessionId, Map<int, BombOperationTeam> teamRoles) async {
    try {
      // Convertir les rôles en format API
      final Map<String, String> rolesForApi = {};
      teamRoles.forEach((teamId, role) {
        rolesForApi[teamId.toString()] = role.toString().split('.').last;
      });

      try {
        // Essayer d'envoyer au serveur
        await _apiService.post(
          'game-sessions/bomb-operation/$gameSessionId/team-roles',
          rolesForApi,
        );
      } catch (e) {
        // Si l'API n'est pas disponible, stocker localement uniquement
        logger.d(
            '⚠️ [BombOperationService] [saveTeamRoles] API non disponible pour sauvegarder les rôles des équipes: $e');
        logger.d('⚠️ [BombOperationService] [saveTeamRoles] Les rôles seront stockés uniquement localement');
      }
      // Mettre à jour l'état local
      _teamRoles.clear();
      _teamRoles.addAll(teamRoles);

      logger
          .d('🧨 [BombOperationService] [saveTeamRoles] Rôles des équipes sauvegardés pour la session $gameSessionId');
    } catch (e) {
      logger.d('❌ [BombOperationService] [saveTeamRoles] Erreur lors de la sauvegarde des rôles des équipes: $e');
      rethrow;
    }
  }

  /// Sélectionne automatiquement des sites de bombe actifs pour une session de jeu
  Future<void> selectRandomBombSites(int gameSessionId) async {
    try {
      final sessionScenarioBomb = _sessionScenarioBomb;
      if (sessionScenarioBomb == null) {
        logger.e('❌ [BombOperationService] [selectRandomBombSites] Session Bombe non initialisée');
        return;
      }

      final bombOperationScenario = sessionScenarioBomb.bombOperationScenario;
      if (bombOperationScenario == null || bombOperationScenario.bombSites == null || bombOperationScenario.bombSites!.isEmpty) {
        logger.e('❌ [BombOperationService] [selectRandomBombSites] Aucun site de bombe défini dans le scénario');
        return;
      }

      final int? sitesToActivate = bombOperationScenario.activeSites;
      if (sitesToActivate == null) {
        logger.e('❌ [BombOperationService] [selectRandomBombSites] Nombre de sites à activer non défini dans le scénario');
        return;
      }

      // Appel au backend pour qu’il sélectionne les sites
      final List<dynamic> activeSiteData = await _apiService.post(
        'game-sessions/bomb-operation/$gameSessionId/active-bomb-sites',
        {}, // aucun body nécessaire
      );

      // Conversion explicite en liste d'IDs
      final List<BombSite> activeSites = activeSiteData
          .map((json) => BombSite.fromJson(json))
          .toList();

      _activeBombSites
        ..clear()
        ..addAll(activeSites.map((site) => site.id!).toList());


      _bombSitesStreamController.add(null);

      logger.d('🧨 [BombOperationService] [selectRandomBombSites] Sites actifs sélectionnés pour session $gameSessionId: $_activeBombSites');
    } catch (e) {
      logger.e('❌ [BombOperationService] [selectRandomBombSites] Erreur lors de la sélection aléatoire des sites de bombe: $e');
      rethrow;
    }
  }



  Future<void> createBombOperationSession({
    required int scenarioId,
    required int gameSessionId,
  }) async {
    await _apiService.post(
      'game-sessions/bomb-operation?scenarioId=$scenarioId&gameSessionId=$gameSessionId',
      {},
    );
  }

  void dispose() {
    _stopBombTimer();
    _stateStreamController.close();
    _bombSitesStreamController.close();
    logger.d('🧨 BombOperationService dispose');
  }

}
