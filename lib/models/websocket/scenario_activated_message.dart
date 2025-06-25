import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';

class ScenarioActivatedMessage extends WebSocketMessage {
  final int gameSessionId;
  final int scenarioId;

  ScenarioActivatedMessage({
    required this.gameSessionId,
    required this.scenarioId,
    required int senderId,
  }) : super('SCENARIO_ACTIVATED', senderId);

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'senderId': senderId,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'payload': {
      'gameSessionId': gameSessionId,
      'scenarioId': scenarioId,
    }
  };

  factory ScenarioActivatedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    return ScenarioActivatedMessage(
      gameSessionId: payload['gameSessionId'],
      scenarioId: payload['scenarioId'],
      senderId: json['senderId'],
    );
  }
}
