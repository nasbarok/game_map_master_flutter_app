import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';

class PlayerPositionMessage extends WebSocketMessage {
  final double latitude;
  final double longitude;
  final int gameSessionId;
  final int? teamId;
  final DateTime positionTimestamp;

  PlayerPositionMessage({
    required int senderId,
    required this.latitude,
    required this.longitude,
    required this.gameSessionId,
    this.teamId,
    DateTime? timestamp,
  }) : positionTimestamp = timestamp ?? DateTime.now(),
       super('PLAYER_POSITION', senderId);

  factory PlayerPositionMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] ?? {};
    return PlayerPositionMessage(
      senderId: json['senderId'],
      latitude: payload['latitude'] ?? 0.0,
      longitude: payload['longitude'] ?? 0.0,
      gameSessionId: payload['gameSessionId'] ?? 0,
      teamId: payload['teamId'],
      timestamp: payload['timestamp'] != null 
          ? DateTime.parse(payload['timestamp']) 
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'timestamp': timestamp.toIso8601String(),
      'payload': {
        'latitude': latitude,
        'longitude': longitude,
        'gameSessionId': gameSessionId,
        'teamId': teamId,
        'timestamp': positionTimestamp.toIso8601String(),
      }
    };
  }
}
