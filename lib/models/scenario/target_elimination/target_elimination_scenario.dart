import '../../scenario.dart';

class TargetEliminationScenario {
  final int? id;
  final Scenario? scenario;
  final String size;
  final GameMode mode;
  final bool friendlyFire;
  final int pointsPerElimination;
  final int cooldownMinutes;
  final int maxTargets;
  final String announcementTemplate;
  final bool active;
  final bool scoresLocked;

  TargetEliminationScenario({
    this.id,
    this.scenario,
    this.size = 'SMALL',
    this.mode = GameMode.solo,
    this.friendlyFire = false,
    this.pointsPerElimination = 1,
    this.cooldownMinutes = 5,
    this.maxTargets = 50,
    this.announcementTemplate = '{killer} a sorti {victim}',
    this.active = false,
    this.scoresLocked = false,
  });

  factory TargetEliminationScenario.fromJson(Map<String, dynamic> json) {
    return TargetEliminationScenario(
      id: json['id'],
      scenario: json['scenario'] != null ? Scenario.fromJson(json['scenario']) : null,
      size: json['size'] ?? 'SMALL',
      mode: GameMode.values.firstWhere(
            (e) => e.toString().split('.').last.toUpperCase() == json['mode'],
        orElse: () => GameMode.solo,
      ),
      friendlyFire: json['friendlyFire'] ?? false,
      pointsPerElimination: json['pointsPerElimination'] ?? 1,
      cooldownMinutes: json['cooldownMinutes'] ?? 5,
      maxTargets: json['maxTargets'] ?? 50,
      announcementTemplate: json['announcementTemplate'] ?? '{killer} a sorti {victim}',
      active: json['active'] ?? false,
      scoresLocked: json['scoresLocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scenario': scenario?.toJson(),
      'size': size,
      'mode': mode.toString().split('.').last.toUpperCase(),
      'friendlyFire': friendlyFire,
      'pointsPerElimination': pointsPerElimination,
      'cooldownMinutes': cooldownMinutes,
      'maxTargets': maxTargets,
      'announcementTemplate': announcementTemplate,
      'active': active,
      'scoresLocked': scoresLocked,
    };
  }
}

enum GameMode { solo, team }