// lib/models/websocket/websocket_message.dart
import 'package:airsoft_game_map/models/websocket/player_connected_message.dart';
import 'package:airsoft_game_map/models/websocket/player_disconnected_message.dart';
import 'package:airsoft_game_map/models/websocket/team_deleted_message.dart';
import 'package:airsoft_game_map/models/websocket/team_updated_message.dart';

import 'field_closed_message.dart';
import 'field_opened_message.dart';
import 'game_ended_message.dart';
import 'game_started_message.dart';

abstract class WebSocketMessage {
  final String type;
  final DateTime timestamp;

  WebSocketMessage(this.type) : timestamp = DateTime.now();

  Map<String, dynamic> toJson();

  static WebSocketMessage fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    switch (type) {
      case 'PLAYER_CONNECTED':
        return PlayerConnectedMessage.fromJson(json);
      case 'PLAYER_DISCONNECTED':
        return PlayerDisconnectedMessage.fromJson(json);
      case 'TEAM_UPDATED':
        return TeamUpdatedMessage.fromJson(json);
      case 'TEAM_DELETED':
        return TeamDeletedMessage.fromJson(json);
      case 'FIELD_CLOSED':
        return FieldClosedMessage.fromJson(json);
      case 'FIELD_OPENED':
        return FieldOpenedMessage.fromJson(json);
      case 'GAME_STARTED':
        return GameStartedMessage.fromJson(json);
      case 'GAME_ENDED':
        return GameEndedMessage.fromJson(json);
      default:
        throw Exception('Unknown message type: $type');
    }
  }
}
