import 'dart:ffi';

import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';

class TeamUpdateMessage extends WebSocketMessage {
  final String action;
  final int mapId;
  final int userId;
  final int? teamId;
  final String? teamName;
  final int? fieldId;
  final int senderId;

  TeamUpdateMessage({
    required this.action,
    required this.mapId,
    required this.userId,
    this.teamId,
    this.teamName,
    this.fieldId,
    required this.senderId,
  }) : super('TEAM_UPDATE', senderId);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'payload': {
        'action': action,
        'mapId': mapId,
        'userId': userId,
        'teamId': teamId,
        'teamName': teamName,
        'fieldId': fieldId,
      },
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory TeamUpdateMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;
    return TeamUpdateMessage(
      action: payload['action'],
      mapId: payload['mapId'],
      userId: payload['userId'],
      teamId: payload['teamId'],
      teamName: payload['teamName'],
      fieldId: payload['fieldId'],
      senderId: json['senderId'],
    );
  }
}
