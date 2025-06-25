import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';

import '../scenario/treasure_hunt/treasure_hunt_notification.dart';

class TreasureFoundMessage extends WebSocketMessage {
  final String message;
  final TreasureFoundData data;

  TreasureFoundMessage({
    required int senderId,
    required this.message,
    required this.data,
  }) : super('TREASURE_FOUND', senderId);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'payload': {
        'type': type,
        'message': message,
        'data': data.toJson(),
        'gameSessionId': data.gameSessionId,
      },
    };
  }

  factory TreasureFoundMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;
    final data = TreasureFoundData.fromJson(payload['data']);

    return TreasureFoundMessage(
      senderId: json['senderId'],
      message: payload['message'] ?? '',
      data: data,
    );
  }
}
