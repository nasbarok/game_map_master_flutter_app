import 'dart:async';

import 'package:airsoft_game_map/services/websocket/player_websocket_handler.dart';
import 'package:airsoft_game_map/services/websocket/team_websocket_handler.dart';

import '../../models/websocket/field_closed_message.dart';
import '../../models/websocket/game_ended_message.dart';
import '../../models/websocket/game_started_message.dart';
import '../../models/websocket/player_connected_message.dart';
import '../../models/websocket/player_disconnected_message.dart';
import '../../models/websocket/team_deleted_message.dart';
import '../../models/websocket/team_updated_message.dart';
import '../../models/websocket/websocket_message.dart';
import '../websocket_service.dart';
import 'field_websocket_handler.dart';

class WebSocketManager {
  final WebSocketService _webSocketService;
  final PlayerWebSocketHandler _playerHandler;
  final TeamWebSocketHandler _teamHandler;
  final FieldWebSocketHandler _fieldHandler;

  StreamSubscription<WebSocketMessage>? _subscription;

  WebSocketManager(
      this._webSocketService,
      this._playerHandler,
      this._teamHandler,
      this._fieldHandler,
      ) {
    _subscription = _webSocketService.messageStream.listen(_handleMessage);
  }

  void _handleMessage(dynamic message) {
    if (message is PlayerConnectedMessage) {
      _playerHandler.handlePlayerConnected(message);
    } else if (message is PlayerDisconnectedMessage) {
      _playerHandler.handlePlayerDisconnected(message);
    } else if (message is TeamUpdatedMessage) {
      _teamHandler.handleTeamUpdated(message);
    } else if (message is TeamDeletedMessage) {
      _teamHandler.handleTeamDeleted(message);
    } else if (message is FieldClosedMessage) {
      _fieldHandler.handleFieldClosed(message);
    } else if (message is GameStartedMessage) {
      // Gérer le début de partie
    } else if (message is GameEndedMessage) {
      // Gérer la fin de partie
    } else if (message is Map<String, dynamic>) {
      // Gérer les messages non typés (pour la rétrocompatibilité)
      _handleLegacyMessage(message);
    }
  }

  void _handleLegacyMessage(Map<String, dynamic> message) {
    final type = message['type'];
    final payload = message['payload'];

    switch (type) {
      case 'PLAYER_CONNECTED':
        final playerMessage = PlayerConnectedMessage(
          player: payload['player'],
          fieldId: payload['fieldId'],
        );
        _playerHandler.handlePlayerConnected(playerMessage);
        break;
      case 'PLAYER_DISCONNECTED':
        final playerMessage = PlayerDisconnectedMessage(
          playerId: payload['playerId'],
          fieldId: payload['fieldId'],
        );
        _playerHandler.handlePlayerDisconnected(playerMessage);
        break;
    // Autres cas...
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}