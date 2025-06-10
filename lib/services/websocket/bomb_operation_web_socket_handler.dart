import 'package:airsoft_game_map/models/websocket/bomb_defused_message.dart';
import 'package:flutter/material.dart';
import '../../models/websocket/bomb_exploded_message.dart';
import '../../models/websocket/bomb_operation_message.dart';
import '../../models/websocket/bomb_planted_message.dart';
import '../../models/websocket/websocket_message.dart';
import '../auth_service.dart';
import '../scenario/bomb_operation/bomb_proximity_detection_service.dart';
import '../websocket_service.dart';
import 'package:airsoft_game_map/utils/logger.dart';

class BombOperationWebSocketHandler {
  final WebSocketService _webSocketService;
  final AuthService _authService;
  final GlobalKey<NavigatorState> _navigatorKey;

  BombOperationWebSocketHandler(
    this._authService,
    this._webSocketService,
    this._navigatorKey,
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
    required Map<String, dynamic> payload,
  }) {
    if (!_webSocketService.isConnected ||
        _authService.currentUser?.id == null) {
      logger.d(
          '❌ Impossible d\'envoyer l\'action, WebSocket non connecté ou utilisateur non authentifié');
      return;
    }

    final userId = _authService.currentUser!.id!;
    final message = BombOperationMessage(
      senderId: userId,
      gameSessionId: gameSessionId,
      action: action,
      payload: payload,
    );

    final destination = '/app/field/$fieldId';

    try {
      _webSocketService.sendMessage(destination, message);
      logger.d('🧨 Action Bombe envoyée: $action → fieldId=$fieldId');
    } catch (e) {
      logger.d('❌ Erreur d\'envoi action Bombe: $e');
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
    logger.d('🧨 [BombOperationWebSocket] Bombe plantée: ${msg.siteName} par ${msg.playerName}');

    final siteName = msg.siteName;
    final player = msg.playerName;

    // Met à jour l'état local du site comme armé
    _proximityService.updateSiteState(msg.siteId, BombSiteState.armed);

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

    // Optionnel : message visuel
    showNotification('💥 Explosion sur ${msg.siteName} !');
  }

}
