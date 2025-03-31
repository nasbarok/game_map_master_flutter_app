// lib/models/websocket/player_connected_message.dart
import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class PlayerConnectedMessage extends WebSocketMessage {
  final Map<String, dynamic> player;
  final int fieldId;

  PlayerConnectedMessage({
    required this.player,
    required this.fieldId,
  }) : super('PLAYER_CONNECTED');

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'payload': {
        'player': player,
        'fieldId': fieldId,
      },
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory PlayerConnectedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;
    return PlayerConnectedMessage(
      player: payload['player'],
      fieldId: payload['fieldId'],
    );
  }
}