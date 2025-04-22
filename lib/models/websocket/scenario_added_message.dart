import 'package:airsoft_game_map/models/websocket/websocket_message.dart';
import 'package:airsoft_game_map/models/game_session_scenario.dart';

class ScenarioAddedMessage extends WebSocketMessage {
  final int gameSessionId;
  final GameSessionScenario scenario;

  ScenarioAddedMessage({
    required this.gameSessionId,
    required this.scenario,
    required int senderId,
  }) : super('SCENARIO_ADDED', senderId);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'payload': {
        'gameSessionId': gameSessionId,
        'scenario': scenario.toJson(),
      }
    };
  }

  factory ScenarioAddedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    return ScenarioAddedMessage(
      gameSessionId: payload['gameSessionId'],
      scenario: GameSessionScenario.fromJson(payload['scenario']),
      senderId: json['senderId'],
    );
  }
}
