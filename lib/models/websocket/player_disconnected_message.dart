// lib/models/websocket/player_disconnected_message.dart
import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class PlayerDisconnectedMessage extends WebSocketMessage {
  final int playerId;
  final int fieldId;

  PlayerDisconnectedMessage({
    required this.playerId,
    required this.fieldId,
  }) : super('PLAYER_DISCONNECTED');

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'payload': {
        'playerId': playerId,
        'fieldId': fieldId,
      },
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory PlayerDisconnectedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;
    return PlayerDisconnectedMessage(
      playerId: payload['playerId'],
      fieldId: payload['fieldId'],
    );
  }
}