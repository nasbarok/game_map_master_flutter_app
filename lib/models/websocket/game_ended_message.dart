// lib/models/websocket/game_ended_message.dart
import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class GameEndedMessage extends WebSocketMessage {
  final int fieldId;

  GameEndedMessage({
    required this.fieldId,
  }) : super('GAME_ENDED');

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

  factory GameEndedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;
    return GameEndedMessage(
      fieldId: payload['fieldId'],
    );
  }
}