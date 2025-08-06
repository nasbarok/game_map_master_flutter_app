
import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';

class BombExplodedMessage extends WebSocketMessage {
  final int siteId;
  final String? siteName;

  BombExplodedMessage({
    required int senderId,
    required this.siteId,
    this.siteName,
  }) : super('BOMB_EXPLODED', senderId);

  factory BombExplodedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] ?? {};
    return BombExplodedMessage(
      senderId: json['senderId'],
      siteId: payload['siteId'] ?? 0,
      siteName: payload['siteName'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'payload': {
        'siteId': siteId,
        'siteName': siteName,
      },
    };
  }
}