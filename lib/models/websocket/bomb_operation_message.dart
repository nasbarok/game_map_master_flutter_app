import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class BombOperationMessage extends WebSocketMessage {
  final int gameSessionId;
  final String action;
  final Map<String, dynamic> payload;

  BombOperationMessage({
    required int senderId,
    required this.gameSessionId,
    required this.action,
    required this.payload,
    DateTime? timestamp,
  }) : super('BOMB_OPERATION_ACTION', senderId);

  factory BombOperationMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] ?? {};
    return BombOperationMessage(
      senderId: json['senderId'],
      gameSessionId: payload['gameSessionId'] ?? 0,
      action: payload['action'] ?? '',
      payload: payload['actionPayload'] ?? {}
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'payload': {
        'gameSessionId': gameSessionId,
        'action': action,
        'actionPayload': payload,
      }
    };
  }
}
