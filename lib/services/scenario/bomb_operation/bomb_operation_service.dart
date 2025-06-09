import 'dart:async';
import 'dart:ui';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_scenario.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_state.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_team.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_site.dart';
import 'package:airsoft_game_map/services/api_service.dart';
import 'package:airsoft_game_map/services/websocket/bomb_operation_web_socket_handler.dart';
import 'package:airsoft_game_map/services/websocket/web_socket_game_session_handler.dart';
import 'package:airsoft_game_map/utils/logger.dart';
import 'package:flutter/material.dart';

import '../../../models/scenario/bomb_operation/bomb_operation_session.dart';
import '../../../models/scenario/bomb_operation/bomb_site_state.dart';

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
  final List<BombSite> _toActivateBombSites = [];
  List<BombSite> get toActivateBombSites => List.unmodifiable(_toActivateBombSites);

  final List<BombSite> _disableBombSites = [];
  List<BombSite> get disableBombSites => List.unmodifiable(_disableBombSites);

  final List<BombSite> _activeBombSites = [];
  List<BombSite> get activeBombSites => List.unmodifiable(_activeBombSites);

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
  Future<void> initialize(BombOperationSession bombOperationSession) async {
    try {
      logger.d('📡 [BombOperationService] [initialize] Récupération du scénario Bombe ');

      _sessionScenarioBomb = bombOperationSession;
      logger.d('✅ [BombOperationService] [initialize] Scénario initialisé: ${_sessionScenarioBomb?.id}');

      // Synchroniser les rôles dans la map locale
      _teamRoles
        ..clear()
        ..addAll(_sessionScenarioBomb?.teamRoles ?? {});
      logger.d('✅ [BombOperationService] [initialize] Rôles des équipes: $_teamRoles');

      // Synchroniser les sites a activer dans la liste locale
      _toActivateBombSites.clear();
      if (_sessionScenarioBomb?.toActiveBombSites != null) {
        for (final site in _sessionScenarioBomb!.toActiveBombSites) {
          _toActivateBombSites.add(site);
        }
        logger.d('✅ [BombOperationService] [initialize] Sites à activer: '
            '${_toActivateBombSites.map((s) => '${s.name} (ID=${s.id})').join(', ')}');
      } else {
        logger.d('ℹ️ [BombOperationService] [initialize] Aucun site à activer trouvé.');
      }

      _disableBombSites.clear();
      if (_sessionScenarioBomb?.disableBombSites != null) {
        for (final site in _sessionScenarioBomb!.disableBombSites) {
          _disableBombSites.add(site);
        }
        logger.d('✅ [BombOperationService] [initialize] Sites désactivés: '
            '${_disableBombSites.map((s) => '${s.name} (ID=${s.id})').join(', ')}');
      } else {
        logger.d('ℹ️ [BombOperationService] [initialize] Aucun site désactivé trouvé.');
      }

      _activeBombSites.clear();
      if (_sessionScenarioBomb?.activeBombSites != null) {
        for (final site in _sessionScenarioBomb!.activeBombSites) {
            _activeBombSites.add(site);
        }
        logger.d('✅ [BombOperationService] [initialize] Sites actifs: '
            '${_activeBombSites.map((s) => '${s.name} (ID=${s.id})').join(', ')}');
      } else {
        logger.d('ℹ️ [BombOperationService] [initialize] Aucun site actif détecté dans le scénario.');
      }

      // Initialiser l'état
      final stateStr = bombOperationSession.gameState;
      logger.d('✅ [BombOperationService] [initialize] État actuel: $_currentState');


      // Démarrer le timer si une bombe est plantée @todo: a changer pour plusieurs timer 1 par bombe
      if (_currentState == BombOperationState.bombPlanted &&
          _bombTimeRemaining > 0) {
        logger.d('⏲️ [BombOperationService] [initialize] Démarrage du timer de bombe...');
        _startBombTimer();
      }

      // Notifier les écouteurs
      _stateStreamController.add(_currentState);
      _bombSitesStreamController.add(null);
      logger.d('🧨 [BombOperationService] [initialize] BombOperationService initialisé - gameSessionId: $bombOperationSession.gameSessionId');
    } catch (e, stack) {
      logger.d('❌ [BombOperationService] [initialize] Erreur: $e');
      logger.t(stack);
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

  Future<BombOperationSession> createBombOperationSession({
    required int scenarioId,
    required int gameSessionId,
  }) async {
    logger.d('[BombOperationService] ➕ Création session Bombe pour gameSessionId=$gameSessionId');

    final response = await _apiService.post(
      'game-sessions/bomb-operation?scenarioId=$scenarioId&gameSessionId=$gameSessionId',
      {},
    );
    logger.d('[BombOperationService] 🔁 Réponse DTO reçue (découpée) :');
    response.forEach((key, value) {
      logger.d('   🔹 $key: $value');
    });

    _sessionScenarioBomb = BombOperationSession.fromJson(response);

    _sessionScenarioBomb!.bombOperationScenario?.bombSites?.forEach((site) {
      logger.d('📍 Site → ${site.name} (isActive: ${site.active})');
    });
    return _sessionScenarioBomb!;
  }
  void dispose() {
    _stopBombTimer();
    _stateStreamController.close();
    _bombSitesStreamController.close();
    logger.d('🧨 BombOperationService dispose');
  }


}
