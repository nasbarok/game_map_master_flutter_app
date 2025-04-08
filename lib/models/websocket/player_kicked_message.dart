import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class PlayerKickedMessage extends WebSocketMessage {
  final int userId;
  final String username;
  final int fieldId;
  final int senderId;

  PlayerKickedMessage({
    required this.userId,
    required this.username,
    required this.fieldId,
    required this.senderId,
  }) : super('PLAYER_KICKED', senderId);

  factory PlayerKickedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] ?? {};
    return PlayerKickedMessage(
      userId: payload['userId'],
      username: payload['username'],
      fieldId: payload['fieldId'],
      senderId: json['senderId'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'payload': {
        'userId': userId,
        'username': username,
        'fieldId': fieldId,
      },
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
