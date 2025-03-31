// lib/models/websocket/team_deleted_message.dart
import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class TeamDeletedMessage extends WebSocketMessage {
  final int teamId;
  final int fieldId;

  TeamDeletedMessage({
    required this.teamId,
    required this.fieldId,
  }) : super('TEAM_DELETED');

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'payload': {
        'teamId': teamId,
        'fieldId': fieldId,
      },
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory TeamDeletedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;
    return TeamDeletedMessage(
      teamId: payload['teamId'],
      fieldId: payload['fieldId'],
    );
  }
}