class GameSessionScenario {
  final int id;
  final int gameSessionId;
  final int scenarioId;
  final String scenarioName;
  final String scenarioType;
  final bool active;
  final bool isMainScenario;

  GameSessionScenario({
    required this.id,
    required this.gameSessionId,
    required this.scenarioId,
    required this.scenarioName,
    required this.scenarioType,
    required this.active,
    required this.isMainScenario,
  });

  factory GameSessionScenario.fromJson(Map<String, dynamic> json) {
    return GameSessionScenario(
      id: json['id'],
      gameSessionId: json['gameSessionId'],
      scenarioId: json['scenarioId'],
      scenarioName: json['scenarioName'],
      scenarioType: json['scenarioType'],
      active: json['active'] ?? false,
      isMainScenario: json['isMainScenario'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameSessionId': gameSessionId,
      'scenarioId': scenarioId,
      'scenarioName': scenarioName,
      'scenarioType': scenarioType,
      'active': active,
      'isMainScenario': isMainScenario,
    };
  }

  static GameSessionScenario placeholder(int scenarioId) {
    return GameSessionScenario(
      id: scenarioId,
      gameSessionId: 0,
      scenarioId: scenarioId,
      scenarioType: '',
      active: false,
      isMainScenario: false,
      scenarioName: '',
    );
  }
}