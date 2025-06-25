import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';

class PlayerLeftMessage extends WebSocketMessage {
  final int fieldId;

  PlayerLeftMessage({
    required int senderId,
    required this.fieldId,
  }) : super('PLAYER_LEFT', senderId);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'timestamp': timestamp.toIso8601String(),
      'fieldId': fieldId,
    };
  }

  static PlayerLeftMessage fromJson(Map<String, dynamic> json) {
    return PlayerLeftMessage(
      senderId: json['senderId'],
      fieldId: json['fieldId'],
    );
  }
}
