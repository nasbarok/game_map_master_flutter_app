import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class ScenarioDeactivatedMessage extends WebSocketMessage {
  final int gameSessionId;
  final int scenarioId;

  ScenarioDeactivatedMessage({
    required this.gameSessionId,
    required this.scenarioId,
    required int senderId,
  }) : super('SCENARIO_DEACTIVATED', senderId);

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

  factory ScenarioDeactivatedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    return ScenarioDeactivatedMessage(
      gameSessionId: payload['gameSessionId'],
      scenarioId: payload['scenarioId'],
      senderId: json['senderId'],
    );
  }
}
