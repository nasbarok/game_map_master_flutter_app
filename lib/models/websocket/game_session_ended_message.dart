import 'package:airsoft_game_map/models/websocket/websocket_message.dart';
import 'package:airsoft_game_map/models/field.dart';
import 'package:airsoft_game_map/models/game_map.dart';

class GameSessionEndedMessage extends WebSocketMessage {
  final int gameSessionId;
  final DateTime endTime;
  final Field field;
  final GameMap gameMap;

  GameSessionEndedMessage({
    required this.gameSessionId,
    required this.endTime,
    required this.field,
    required this.gameMap,
    required int senderId,
  }) : super('GAME_SESSION_ENDED', senderId);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'payload': {
        'id': gameSessionId,
        'endTime': endTime.toIso8601String(),
        'field': field.toJson(),
        'gameMap': gameMap.toJson(),
      }
    };
  }

  factory GameSessionEndedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;

    return GameSessionEndedMessage(
      gameSessionId: payload['id'],
      endTime: DateTime.parse(payload['endTime']),
      field: Field.fromJson(payload['field']),
      gameMap: GameMap.fromJson(payload['gameMap']),
      senderId: json['senderId'],
    );
  }
}
