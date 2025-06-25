// lib/models/websocket/team_deleted_message.dart
import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';
class TeamCreatedMessage extends WebSocketMessage {
  final int mapId;
  final Map<String, dynamic> team;

  TeamCreatedMessage({
    required this.mapId,
    required this.team,
    required int senderId,
  }) : super('TEAM_CREATED', senderId);

  factory TeamCreatedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;
    return TeamCreatedMessage(
      mapId: payload['mapId'],
      team: payload['team'],
      senderId: json['senderId'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'payload': {
        'mapId': mapId,
        'team': team,
      },
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
