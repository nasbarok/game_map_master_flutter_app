import 'package:airsoft_game_map/models/game_map.dart';
import 'package:airsoft_game_map/models/websocket/game_session_started_message.dart';

import 'field.dart';
import 'game_session_participant.dart';
import 'game_session_scenario.dart';

class GameSession {
  final int? id;
  final GameMap? gameMap;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final Field? field;
  final bool active;
  final List<GameSessionParticipant> participants;
  final List<GameSessionScenario> scenarios;

  GameSession({
    required this.id,
    required this.gameMap,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 0,
    required this.field,
    required this.active,
    this.participants = const [],
    this.scenarios = const [],
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    List<GameSessionParticipant> participants = [];
    if (json['participants'] != null) {
      participants = (json['participants'] as List)
          .map((p) => GameSessionParticipant.fromJson(p))
          .toList();
    }

    List<GameSessionScenario> scenarios = [];
    if (json['scenarios'] != null) {
      scenarios = (json['scenarios'] as List)
          .map((s) => GameSessionScenario.fromJson(s))
          .toList();
    }
    return GameSession(
      id: json['id'] as int?,
      gameMap:
          json['gameMap'] != null ? GameMap.fromJson(json['gameMap']) : null,
      field: json['field'] != null ? Field.fromJson(json['field']) : null,
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      durationMinutes: json['durationMinutes'] as int,
      active: json['active'] as bool,
      participants: participants,
      scenarios: scenarios,
    );
  }

  factory GameSession.fromWebSocketMessage(GameSessionStartedMessage msg) {
    return GameSession(
      id: msg.gameSessionId,
      gameMap: msg.gameMap,
      field: msg.field,
      startTime: msg.startTime,
      endTime: null,
      // sera défini plus tard si besoin
      durationMinutes: msg.durationMinutes,
      active: true,
      participants: msg.participants,
      scenarios: msg.scenarios,
    );
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'id': id,
      'gameMap': gameMap?.toJson(),
      'field': field?.toJson(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'active': active,
      'participants': participants.map((p) => p.toJson()).toList(),
      'scenarios': scenarios.map((s) => s.toJson()).toList(),
    };
  }

  int getRemainingTimeInSeconds() {
    if (!active || endTime != null) {
      return 0;
    }

    final expirationTime = startTime.add(Duration(minutes: durationMinutes));
    final now = DateTime.now();

    if (now.isAfter(expirationTime)) {
      return 0;
    }

    return expirationTime.difference(now).inSeconds;
  }

  bool isExpired() {
    if (!active || endTime != null) {
      return true;
    }

    final expirationTime = startTime.add(Duration(minutes: durationMinutes));
    return DateTime.now().isAfter(expirationTime);
  }

  GameSession copyWith({
    int? id,
    GameMap? gameMap,
    Field? field,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    bool? active,
    List<GameSessionParticipant>? participants,
    List<GameSessionScenario>? scenarios,
  }) {
    return GameSession(
      id: id ?? this.id,
      gameMap: gameMap ?? this.gameMap,
      field: field ?? this.field,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      active: active ?? this.active,
      participants: participants ?? this.participants,
      scenarios: scenarios ?? this.scenarios,
    );
  }

}
