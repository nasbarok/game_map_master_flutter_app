import 'dart:async';

import 'package:airsoft_game_map/services/websocket/player_websocket_handler.dart';
import 'package:airsoft_game_map/services/websocket/team_websocket_handler.dart';

import '../../models/websocket/field_closed_message.dart';
import '../../models/websocket/game_ended_message.dart';
import '../../models/websocket/game_session_started_message.dart';
import '../../models/websocket/player_connected_message.dart';
import '../../models/websocket/player_disconnected_message.dart';
import '../../models/websocket/team_deleted_message.dart';
import '../../models/websocket/team_update_message.dart';
import '../../models/websocket/websocket_message.dart';
import '../websocket_service.dart';
import 'field_websocket_handler.dart';
import 'package:airsoft_game_map/utils/logger.dart';
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
    if (message is Map<String, dynamic>) {
      logger.d(
          '[websocket_manager] [_handleMessage] non utilisé Received message: $message');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
