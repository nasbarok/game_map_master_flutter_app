// lib/models/websocket/game_session_started_message.dart
import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';

import 'package:game_map_master_flutter_app/models/field.dart';
import 'package:game_map_master_flutter_app/models/game_map.dart';
import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';
import 'package:game_map_master_flutter_app/models/game_session_participant.dart';
import 'package:game_map_master_flutter_app/models/game_session_scenario.dart';

class GameSessionStartedMessage extends WebSocketMessage {
  final int gameSessionId;
  final GameMap gameMap;
  final Field field;
  final DateTime startTime;
  final int durationMinutes;
  final List<GameSessionParticipant> participants;
  final List<GameSessionScenario> scenarios;

  GameSessionStartedMessage({
    required this.gameSessionId,
    required this.gameMap,
    required this.field,
    required this.startTime,
    required this.durationMinutes,
    required this.participants,
    required this.scenarios,
    required int senderId,
  }) : super('GAME_SESSION_STARTED', senderId);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'payload': {
        'id': gameSessionId,
        'gameMap': gameMap.toJson(),
        'field': field.toJson(),
        'startTime': startTime.toUtc().toIso8601String(),
        'durationMinutes': durationMinutes,
        'participants': participants.map((p) => p.toJson()).toList(),
        'scenarios': scenarios.map((s) => s.toJson()).toList(),
      },
    };
  }

  factory GameSessionStartedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>;

    final List<GameSessionParticipant> participants =
    (payload['participants'] as List)
        .map((e) => GameSessionParticipant.fromJson(e))
        .toList();

    final List<GameSessionScenario> scenarios =
    (payload['scenarios'] as List)
        .map((e) => GameSessionScenario.fromJson(e))
        .toList();

    return GameSessionStartedMessage(
      gameSessionId: payload['id'],
      gameMap: GameMap.fromJson(payload['gameMap']),
      field: Field.fromJson(payload['field']),
      startTime: DateTime.parse(payload['startTime']),
      durationMinutes: payload['durationMinutes'],
      participants: participants,
      scenarios: scenarios,
      senderId: json['senderId'],
    );
  }
}
