
import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';

class BombPlantedMessage extends WebSocketMessage {
  final int siteId;
  final int bombTimer;
  final String? playerName;
  final String? siteName;
  final DateTime plantedTimestamp;

  BombPlantedMessage({
    required int senderId,
    required this.siteId,
    required this.bombTimer,
    required this.plantedTimestamp,
    this.playerName,
    this.siteName,
  }) : super('BOMB_PLANTED', senderId);

  factory BombPlantedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] ?? {};
    return BombPlantedMessage(
      senderId: json['senderId'],
      siteId: payload['siteId'] ?? 0,
      bombTimer: payload['bombTimer'] ?? 0,
      plantedTimestamp: DateTime.fromMillisecondsSinceEpoch(payload['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      playerName: payload['playerName'],
      siteName: payload['siteName'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'timestamp': timestamp.toIso8601String(),
      'payload': {
        'siteId': siteId,
        'bombTimer': bombTimer,
        'timestamp': plantedTimestamp.millisecondsSinceEpoch,
        'playerName': playerName,
        'siteName': siteName,
      },
    };
  }
}
