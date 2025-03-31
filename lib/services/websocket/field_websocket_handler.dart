// lib/services/websocket/field_websocket_handler.dart
import 'package:flutter/material.dart';

import '../../models/websocket/field_closed_message.dart';
import '../auth_service.dart';
import '../game_state_service.dart';

class FieldWebSocketHandler {
  final GameStateService _gameStateService;
  final AuthService _authService;
  final GlobalKey<NavigatorState> _navigatorKey;

  FieldWebSocketHandler(this._gameStateService, this._authService, this._navigatorKey);

  void _handleFieldOpened(Map<String, dynamic> content) {
    final fieldId = content['fieldId'];
    final ownerId = content['ownerId'];
    final ownerUsername = content['ownerUsername'];

    print('🏟️ Terrain ouvert : ID=$fieldId par $ownerUsername');

    // Si l'utilisateur est le propriétaire, pas besoin de faire quoi que ce soit
    // car il a déjà mis à jour son état local

    // Pour les autres utilisateurs, afficher une notification
    if (_authService!.currentUser!.id != ownerId) {
      _showFieldOpenedNotification(ownerUsername);
    }
  }

  void handleFieldClosed(FieldClosedMessage message) {
    final fieldId = message.fieldId;
    final ownerId = message.ownerId;
    final ownerUsername = message.ownerUsername;
    print('🚪 Terrain fermé : ID=$fieldId');

    // Si l'utilisateur est le propriétaire, pas besoin de faire quoi que ce soit
    // car il a déjà mis à jour son état local

    // Pour les autres utilisateurs (gamers), réinitialiser l'état et naviguer vers l'écran principal
    if (_authService!.currentUser!.id != ownerId) {
      _gameStateService!.reset();
      _showFieldClosedNotification(ownerUsername);
      _navigateToMainScreen();
    }
  }

  void _showFieldOpenedNotification(String ownerUsername) {
    // Utiliser un GlobalKey<NavigatorState> pour accéder au Navigator
    if (_navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Le terrain de $ownerUsername est maintenant ouvert'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _showFieldClosedNotification(String ownerUsername) {
    // Utiliser un GlobalKey<NavigatorState> pour accéder au Navigator
    if (_navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Le terrain de $ownerUsername a été fermé'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _navigateToMainScreen() {
    // Utiliser un GlobalKey<NavigatorState> pour accéder au Navigator
    if (_navigatorKey.currentState != null) {
      _navigatorKey.currentState!.pushNamedAndRemoveUntil(
        '/gamer',
            (route) => false,
      );
    }
  }

}