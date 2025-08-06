
import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';

class BombDefusedMessage extends WebSocketMessage {
  final int siteId;
  final String? playerName;
  final String? siteName;

  BombDefusedMessage({
    required int senderId,
    required this.siteId,
    this.playerName,
    this.siteName,
  }) : super('BOMB_DEFUSED', senderId);

  factory BombDefusedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] ?? {};
    return BombDefusedMessage(
      senderId: json['senderId'],
      siteId: payload['siteId'] ?? 0,
      playerName: payload['playerName'],
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
        'playerName': playerName,
        'siteName': siteName,
      },
    };
  }
}
