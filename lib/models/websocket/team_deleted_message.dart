import 'websocket_message.dart';

class TeamDeletedMessage extends WebSocketMessage {
  final int mapId;
  final int teamId;

  TeamDeletedMessage({
    required this.mapId,
    required this.teamId,
    required int senderId,
  }) : super('TEAM_DELETED', senderId);

  factory TeamDeletedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;

    return TeamDeletedMessage(
      mapId: payload['mapId'] as int,
      teamId: payload['teamId'] as int,
      senderId: json['senderId'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'payload': {
        'mapId': mapId,
        'teamId': teamId,
      },
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
