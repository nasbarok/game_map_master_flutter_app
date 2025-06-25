
import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';

class BombOperationMessage extends WebSocketMessage {
  final int gameSessionId;
  final String action;
  final int bombSiteId;

  BombOperationMessage({
    required int senderId,
    required this.gameSessionId,
    required this.action,
    required this.bombSiteId,
    DateTime? timestamp,
  }) : super('BOMB_OPERATION_ACTION', senderId);

  factory BombOperationMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] ?? {};
    return BombOperationMessage(
      senderId: json['senderId'],
      gameSessionId: payload['gameSessionId'] ?? 0,
      action: payload['action'] ?? '',
      bombSiteId: payload['bombSiteId'] ?? 0,
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
        'bombSiteId': bombSiteId,
      }
    };
  }
}
