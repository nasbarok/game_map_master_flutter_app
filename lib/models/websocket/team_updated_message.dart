
// lib/models/websocket/team_updated_message.dart
import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class TeamUpdatedMessage extends WebSocketMessage {
  final int teamId;
  final int teamName;

  TeamUpdatedMessage({
    required this.teamId,
    required this.teamName,
  }) : super('TEAM_UPDATED');

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'payload': {
        'teamId': teamId,
        'teamName': teamName,
      },
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory TeamUpdatedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;
    return TeamUpdatedMessage(
      teamId: payload['teamId'],
      teamName: payload['teamName'],
    );
  }
}