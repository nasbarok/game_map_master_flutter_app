// lib/models/websocket/game_ended_message.dart
import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';

class GameEndedMessage extends WebSocketMessage {
  final int fieldId;
  final int senderId;

  GameEndedMessage({
    required this.fieldId,
    required this.senderId,
  }) : super('GAME_ENDED',senderId);

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

  factory GameEndedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;
    return GameEndedMessage(
      fieldId: payload['fieldId'],
      senderId: json['senderId'],
    );
  }
}