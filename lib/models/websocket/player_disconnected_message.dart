// lib/models/websocket/player_disconnected_message.dart
import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class PlayerDisconnectedMessage extends WebSocketMessage {
  final int playerId;
  final String playerUsername;
  final int fieldId;
  final int senderId;

  PlayerDisconnectedMessage({
    required this.playerId,
    required this.fieldId,
    required this.senderId,
    required this.playerUsername,
  }) : super('PLAYER_DISCONNECTED', senderId);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'payload': {
        'playerId': playerId,
        'fieldId': fieldId,
        'playerUsername': playerUsername,
      },
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory PlayerDisconnectedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;
    return PlayerDisconnectedMessage(
      playerId: payload['playerId'],
      fieldId: payload['fieldId'],
      senderId: json['senderId'],
      playerUsername: payload['playerUsername'],
    );
  }
}