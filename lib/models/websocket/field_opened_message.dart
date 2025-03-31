// lib/models/websocket/field_closed_message.dart
import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class FieldOpenedMessage extends WebSocketMessage {
  final int fieldId;

  FieldOpenedMessage({
    required this.fieldId,
  }) : super('FIELD_OPENED');

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

  factory FieldOpenedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;
    return FieldOpenedMessage(
      fieldId: payload['fieldId'],
    );
  }
}