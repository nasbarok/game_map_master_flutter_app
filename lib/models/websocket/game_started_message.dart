// lib/models/websocket/game_started_message.dart
import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class GameStartedMessage extends WebSocketMessage {
  final int fieldId;
  final int senderId;

  GameStartedMessage({
    required this.fieldId,
    required this.senderId,
  }) : super('GAME_STARTED', senderId);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'payload': {
        'fieldId': fieldId,
      },
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory GameStartedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;
    return GameStartedMessage(
      fieldId: payload['fieldId'],
      senderId: json['senderId'],
    );
  }
}