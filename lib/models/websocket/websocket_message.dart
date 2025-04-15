// lib/models/websocket/websocket_message.dart
import 'dart:ffi';

import 'package:airsoft_game_map/models/websocket/invitation_response_message.dart';
import 'package:airsoft_game_map/models/websocket/player_connected_message.dart';
import 'package:airsoft_game_map/models/websocket/player_disconnected_message.dart';
import 'package:airsoft_game_map/models/websocket/player_kicked_message.dart';
import 'package:airsoft_game_map/models/websocket/scenario_update_message.dart';
import 'package:airsoft_game_map/models/websocket/team_created_message.dart';
import 'package:airsoft_game_map/models/websocket/team_deleted_message.dart';
import 'package:airsoft_game_map/models/websocket/team_update_message.dart';

import 'field_closed_message.dart';
import 'field_opened_message.dart';
import 'game_ended_message.dart';
import 'game_invitation_message.dart';
import 'game_started_message.dart';
import 'invitation_received_message.dart';

abstract class WebSocketMessage {
  final String type;
  final int senderId;
  final DateTime timestamp;

  WebSocketMessage(this.type, this.senderId) : timestamp = DateTime.now();

  Map<String, dynamic> toJson();

  static WebSocketMessage fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    switch (type) {
      case 'GAME_INVITATION':
        return GameInvitationMessage.fromJson(json);
      case 'INVITATION_RESPONSE':
        return InvitationResponseMessage.fromJson(json);
      case 'INVITATION_RECEIVED':
        return InvitationReceivedMessage.fromJson(json);
      case 'PLAYER_CONNECTED':
        return PlayerConnectedMessage.fromJson(json);
      case 'PLAYER_DISCONNECTED':
        return PlayerDisconnectedMessage.fromJson(json);
      case 'PLAYER_KICKED':
        return PlayerKickedMessage.fromJson(json);
      case 'TEAM_UPDATE':
        return TeamUpdateMessage.fromJson(json);
      case 'TEAM_DELETED':
        return TeamDeletedMessage.fromJson(json);
      case 'TEAM_CREATED':
        return TeamCreatedMessage.fromJson(json);
      case 'TEAM_DELETED':
        return TeamDeletedMessage .fromJson(json);
      case 'FIELD_CLOSED':
        return FieldClosedMessage.fromJson(json);
      case 'FIELD_OPENED':
        return FieldOpenedMessage.fromJson(json);
      case 'SCENARIO_UPDATE':
        return ScenarioUpdateMessage.fromJson(json);
      case 'GAME_STARTED':
        return GameStartedMessage.fromJson(json);
      case 'GAME_ENDED':
        return GameEndedMessage.fromJson(json);
      default:
        throw Exception('Unknown message type: $type');
    }
  }
}
