class TreasureHuntScenario {
  final int id;
  final int? scenarioId;
  final String? scenarioName;
  final int totalTreasures;
  final int? requiredTreasures;
  final String size;
  final int defaultValue;
  final String defaultSymbol;
  final bool scoresLocked;
  final bool active;

  TreasureHuntScenario({
    required this.id,
    this.scenarioId,
    this.scenarioName,
    required this.totalTreasures,
    this.requiredTreasures,
    required this.size,
    required this.defaultValue,
    required this.defaultSymbol,
    required this.scoresLocked,
    required this.active,
  });

  factory TreasureHuntScenario.fromJson(Map<String, dynamic> json) {
    final scenarioJson = json['scenario'];
    return TreasureHuntScenario(
      id: json['id'] ?? 0, // <= protection ici : si pas d'id, mettre 0 par défaut
      scenarioId: scenarioJson != null ? scenarioJson['id'] : json['scenarioId'],
      scenarioName: scenarioJson != null ? scenarioJson['name'] : json['scenarioName'],
      totalTreasures: json['totalTreasures'] ?? 0,
      requiredTreasures: json['requiredTreasures'],
      size: json['size'] ?? "SMALL",
      defaultValue: json['defaultValue'] ?? 0,
      defaultSymbol: json['defaultSymbol'] ?? "",
      scoresLocked: json['scoresLocked'] ?? false,
      active: json['active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scenarioId': scenarioId,
      'scenarioName': scenarioName,
      'totalTreasures': totalTreasures,
      'requiredTreasures': requiredTreasures,
      'size': size,
      'defaultValue': defaultValue,
      'defaultSymbol': defaultSymbol,
      'scoresLocked': scoresLocked,
      'active': active,
    };
  }
}
