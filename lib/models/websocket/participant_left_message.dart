import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';

class ParticipantLeftMessage extends WebSocketMessage {
  final int gameSessionId;
  final int userId;
  final String username;

  ParticipantLeftMessage({
    required this.gameSessionId,
    required this.userId,
    required this.username,
    required int senderId,
  }) : super('PARTICIPANT_LEFT', senderId);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'payload': {
        'gameSessionId': gameSessionId,
        'userId': userId,
        'username': username,
      },
    };
  }

  factory ParticipantLeftMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    return ParticipantLeftMessage(
      gameSessionId: payload['gameSessionId'],
      userId: payload['userId'],
      username: payload['username'] ?? 'Joueur inconnu',
      senderId: json['senderId'],
    );
  }
}