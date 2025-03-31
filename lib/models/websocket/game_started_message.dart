// lib/models/websocket/game_started_message.dart
import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class GameStartedMessage extends WebSocketMessage {
  final int fieldId;

  GameStartedMessage({
    required this.fieldId,
  }) : super('GAME_STARTED');

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
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
    );
  }
}