import 'package:flutter/material.dart';
import '../../models/websocket/bomb_operation_message.dart';
import '../auth_service.dart';
import '../websocket_service.dart';

class BombOperationWebSocketHandler {
  final WebSocketService _webSocketService;
  final AuthService _authService;
  final GlobalKey<NavigatorState> _navigatorKey;

  BombOperationWebSocketHandler(
      this._webSocketService,
      this._authService,
      this._navigatorKey,
      );

  /// Envoie une action liée au scénario Bombe via WebSocket
  void sendBombOperationAction({
    required int fieldId,
    required int gameSessionId,
    required String action,
    required Map<String, dynamic> payload,
  }) {
    if (!_webSocketService.isConnected || _authService.currentUser?.id == null) {
      print('❌ Impossible d\'envoyer l\'action, WebSocket non connecté ou utilisateur non authentifié');
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
      print('🧨 Action Bombe envoyée: $action → fieldId=$fieldId');
    } catch (e) {
      print('❌ Erreur d\'envoi action Bombe: $e');
    }
  }

  /// Optionnel : gestion d'affichage de notifications ou navigation
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
}
