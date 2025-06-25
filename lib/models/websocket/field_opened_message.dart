// lib/models/websocket/field_closed_message.dart
import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';

class FieldOpenedMessage extends WebSocketMessage {
  final int fieldId;
  final int senderId;

  FieldOpenedMessage({
    required this.fieldId,
    required this.senderId,
  }) : super('FIELD_OPENED',senderId);

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

  factory FieldOpenedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;
    return FieldOpenedMessage(
      fieldId: payload['fieldId'],
      senderId: json['senderId'],
    );
  }
}