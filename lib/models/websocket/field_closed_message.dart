// lib/models/websocket/field_closed_message.dart
import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class FieldClosedMessage extends WebSocketMessage {
  final int fieldId;
  final int ownerId;
  final String ownerUsername;
  final int senderId;

  FieldClosedMessage({
    required this.fieldId,
    required this.ownerId,
    required this.ownerUsername,
    required this.senderId,
  }) : super('FIELD_CLOSED', senderId);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'payload': {
        'fieldId': fieldId,
        'ownerId': ownerId,
        'ownerUsername': ownerUsername,
      },
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory FieldClosedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;
    return FieldClosedMessage(
      fieldId: payload['fieldId'],
      ownerId: payload['ownerId'],
      ownerUsername: payload['ownerUsername'],
      senderId: json['senderId'],
    );
  }
}
