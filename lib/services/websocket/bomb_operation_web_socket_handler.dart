import 'package:airsoft_game_map/models/websocket/bomb_defused_message.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../models/websocket/bomb_exploded_message.dart';
import '../../models/websocket/bomb_operation_message.dart';
import '../../models/websocket/bomb_planted_message.dart';
import '../../models/websocket/websocket_message.dart';
import '../api_service.dart';
import '../auth_service.dart';
import '../scenario/bomb_operation/bomb_operation_service.dart';
import '../scenario/bomb_operation/bomb_proximity_detection_service.dart';
import '../websocket_service.dart';
import 'package:airsoft_game_map/utils/logger.dart';

class BombOperationWebSocketHandler {
  final WebSocketService _webSocketService;
  final AuthService _authService;
  final GlobalKey<NavigatorState> _navigatorKey;
  final ApiService _apiService;

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
    final requestBody = {
      'userId': userId,
      'bombSiteId': bombSiteId,
    };

    try {
      switch (action) {
        case 'PLANT_BOMB':
          await _apiService.post(
            'game-sessions/bomb-operation/$fieldId/$gameSessionId/bomb-armed',
            requestBody,
          );
          logger.d('✅ [BombOperationWebSocketHandler] [sendBombOperationAction] [PLANT_BOMB] Notification envoyée via HTTP → siteId=$bombSiteId');

          bombOperationService.activateSite(bombSiteId);
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

    // Met à jour l'état local du site comme armé
    _proximityService.updateSiteState(msg.siteId, BombSiteState.armed);

    final _bombOperationService = GetIt.I<BombOperationService>();
    _bombOperationService.activateSite(msg.siteId);

    // Affiche une notification snack + dialog court
    showNotification('💣 Bombe plantée sur $siteName par $player');
  }

  /// Gère les notifications de bombe désarmée
  void handleBombDefused(Map<String, dynamic> message, BuildContext context) {
    final msg = BombDefusedMessage.fromJson(message);
    logger.d('✅ [BombOperationWebSocket] Bombe désarmée: ${msg.siteName} par ${msg.playerName}');

    // Mettre à jour l'état dans le service de proximité
    _proximityService.updateSiteState(msg.siteId, BombSiteState.disarmed);

    // Optionnel : message visuel
    showNotification('✅ Bombe désarmée sur ${msg.siteName} par ${msg.playerName}');
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

}
