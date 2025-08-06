import 'package:game_map_master_flutter_app/models/websocket/bomb_defused_message.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/scenario/bomb_operation/bomb_operation_team.dart';
import '../../models/websocket/bomb_exploded_message.dart';
import '../../models/websocket/bomb_operation_message.dart';
import '../../models/websocket/bomb_planted_message.dart';
import '../../models/websocket/websocket_message.dart';
import '../api_service.dart';
import '../audio/bomb_defender_audio_manager.dart';
import '../audio/bomb_terrorist_audio_manager.dart';
import '../auth_service.dart';
import '../game_state_service.dart';
import '../scenario/bomb_operation/bomb_operation_service.dart';
import '../scenario/bomb_operation/bomb_proximity_detection_service.dart';
import '../websocket_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

class BombOperationWebSocketHandler {
  final WebSocketService _webSocketService;
  final AuthService _authService;
  final GlobalKey<NavigatorState> _navigatorKey;
  final ApiService _apiService;

  final BombTerroristAudioManager _audioManager = BombTerroristAudioManager();
  final BombDefenderAudioManager _defenderAudioManager = BombDefenderAudioManager();

  BombOperationWebSocketHandler(
    this._authService,
    this._webSocketService,
    this._navigatorKey,
    this._apiService,
  );

  late BombProximityDetectionService _proximityService;

  void setProximityService(BombProximityDetectionService service) {
    _proximityService = service;
  }
  /// Envoie une action liée au scénario Bombe via WebSocket
  void sendBombOperationAction({
    required int fieldId,
    required int gameSessionId,
    required String action,
    required int bombSiteId,
  }) async {
    if (_authService.currentUser?.id == null) {
      logger.d('❌ Utilisateur non authentifié');
      return;
    }
    final bombOperationService = GetIt.I<BombOperationService>();
    final userId = _authService.currentUser!.id!;
    final now = DateTime.now().toUtc().toUtc().toIso8601String();
    final requestBody = {
      'userId': userId,
      'bombSiteId': bombSiteId,
      'action': action,
      'actionTime': now,
    };

    try {
      switch (action) {
        case 'PLANT_BOMB':
          await _apiService.post(
            'game-sessions/bomb-operation/$fieldId/$gameSessionId/bomb-armed',
            requestBody,
          );
          logger.d('✅ [BombOperationWebSocketHandler] [sendBombOperationAction] [PLANT_BOMB] Notification envoyée via HTTP → siteId=$bombSiteId');

          break;

        case 'DEFUSE_BOMB':
          await _apiService.post(
            'game-sessions/bomb-operation/$fieldId/$gameSessionId/bomb-disarmed',
            requestBody,
          );
          logger.d('✅ [BombOperationWebSocketHandler] [sendBombOperationAction] [BOMB_DISARMED] Notification envoyée via HTTP → siteId=$bombSiteId');
          break;

        default:
        // fallback → WebSocket
          logger.d('❌Erreur Envoi de l\'action Bombe ($action) pour le site $bombSiteId via POST');
          final message = BombOperationMessage(
            senderId: userId,
            gameSessionId: gameSessionId,
            action: action,
            bombSiteId: bombSiteId,
          );
      }
    } catch (e) {
      logger.e('❌ Erreur lors de l\'envoi de l\'action Bombe ($action) : $e');
    }
  }


  /// gestion d'affichage de notifications ou navigation
  void showNotification(String message) {
    if (_navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blueAccent,
        ),
      );
    }
  }

  /// Gère les notifications de bombe plantée
  void handleBombPlanted(Map<String, dynamic> message, BuildContext context) {
    final msg = BombPlantedMessage.fromJson(message);
    logger.d('🧨 [BombOperationWebSocket] Bombe plantée: ${msg.siteName} par userId ${msg.senderId}');

    final siteName = msg.siteName;
    final player = msg.playerName;
    final bombSiteId = msg.siteId;
    final bombTimer = msg.bombTimer;
    final plantedTimestamp = msg.plantedTimestamp;
    final senderId = msg.senderId;
    final l10n = AppLocalizations.of(context)!;
    final playerName = getPlayerName(l10n,senderId);
    // Met à jour l'état local du site comme armé
    _proximityService.updateSiteState(msg.siteId, BombSiteState.armed);

    final _bombOperationService = GetIt.I<BombOperationService>();
    _bombOperationService.activateSite(msg.siteId, bombTimer, plantedTimestamp, playerName);

    // Déclencher l'audio selon le rôle
    final currentUserId = _authService.currentUser?.id;
    if (currentUserId != null) {
      final role = _bombOperationService.getPlayerRoleBombOperation(currentUserId);

      if (role == BombOperationTeam.attack) {
        // Pour les terroristes : confirmation d'armement
        _audioManager.playBombArmedAudio(siteName!);
      } else if (role == BombOperationTeam.defense) {
        // Pour les défenseurs : alerte d'intervention
        _defenderAudioManager.playBombActiveAlert(siteName!);
      }
    }

    // Affiche une notification snack + dialog court
    showNotification('💣 Bombe plantée sur $siteName par $playerName');
  }

  /// Gère les notifications de bombe désarmée
  void handleBombDefused(Map<String, dynamic> message, BuildContext context) {
    final msg = BombDefusedMessage.fromJson(message);
    logger.d('✅ [BombOperationWebSocket] Bombe désarmée: ${msg.siteName} par ${msg.senderId}');
    final l10n = AppLocalizations.of(context)!;
    final siteId = msg.siteId;
    final siteName = msg.siteName;
    final playerName = getPlayerName(l10n,msg.senderId);

    // 1. Mise à jour de l'état dans le service de proximité
    _proximityService.updateSiteState(siteId, BombSiteState.disarmed);

    // 2. Mise à jour dans le BombOperationService : désactivation du site
    final bombOperationService = GetIt.I<BombOperationService>();
    bombOperationService.deactivateSite(siteId);

    // Déclencher l'audio de succès pour les défenseurs
    final currentUserId = _authService.currentUser?.id;
    if (currentUserId != null) {
      final role = bombOperationService.getPlayerRoleBombOperation(currentUserId);

      if (role == BombOperationTeam.defense) {
        // Pour les défenseurs : confirmation de succès
        _defenderAudioManager.playBombDefusedAudio(siteName!);
      }
    }

    // 3. Notification visuelle
    showNotification('✅ Bombe désarmée sur $siteName par $playerName');
  }

  /// Gère les notifications de bombe explosée
  void handleBombExploded(Map<String, dynamic> message, BuildContext context) {
    final msg = BombExplodedMessage.fromJson(message);
    logger.d('💥 [BombOperationWebSocket] Bombe explosée: ${msg.siteName}');

    // Mettre à jour l'état dans le service de proximité
    _proximityService.updateSiteState(msg.siteId, BombSiteState.exploded);

    // ✨ Mettre à jour la liste des sites explosés dans le service principal
    _proximityService.moveSiteToExploded(msg.siteId);

    // Optionnel : message visuel
    showNotification('💥 Explosion sur ${msg.siteName} !');
  }

  String getPlayerName(AppLocalizations l10n,int userId) {

    final gameStateService = GetIt.I<GameStateService>();

    final player = gameStateService.connectedPlayersList.firstWhere(
          (p) => p['id'] == userId,
      orElse: () {
        logger.w('[getPlayerName] AUCUN joueur trouvé pour userId=$userId');
        return {};
      },
    );
    if (player.isEmpty) {
      return l10n.playerMarkerLabel(userId);
    }

    final username = player['username'];
    if (username == null) {
      logger.w('[getPlayerName] Joueur trouvé mais "username" est null → player=$player');
      return l10n.playerMarkerLabel(userId);
    }
    return username;
  }

}
