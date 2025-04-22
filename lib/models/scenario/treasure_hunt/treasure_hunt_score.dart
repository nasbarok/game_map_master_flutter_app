class TreasureHuntScore {
  final int? id;
  final int? treasureHuntScenarioId;
  final int? userId;
  final String? username;
  final int? teamId;
  final String? teamName;
  final int score;
  final int treasuresFound;
  final DateTime lastUpdated;

  TreasureHuntScore({
    this.id,
    this.treasureHuntScenarioId,
    this.userId,
    this.username,
    this.teamId,
    this.teamName,
    required this.score,
    required this.treasuresFound,
    required this.lastUpdated,
  });

  factory TreasureHuntScore.fromJson(Map<String, dynamic> json) {
    return TreasureHuntScore(
      id: json['id'],
      treasureHuntScenarioId: json['treasureHuntScenarioId'],
      userId: json['userId'],
      username: json['username'],
      teamId: json['teamId'],
      teamName: json['teamName'],
      score: json['score'],
      treasuresFound: json['treasuresFound'],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'treasureHuntScenarioId': treasureHuntScenarioId,
      'userId': userId,
      'username': username,
      'teamId': teamId,
      'teamName': teamName,
      'score': score,
      'treasuresFound': treasuresFound,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class TreasureHuntScoreboard {
  final List<TreasureHuntScore> individualScores;
  final List<TreasureHuntScore> teamScores;
  final bool scoresLocked;

  TreasureHuntScoreboard({
    required this.individualScores,
    required this.teamScores,
    required this.scoresLocked,
  });

  factory TreasureHuntScoreboard.fromJson(Map<String, dynamic> json) {
    List<TreasureHuntScore> individualScores = [];
    if (json['individualScores'] != null) {
      individualScores = (json['individualScores'] as List)
          .map((s) => TreasureHuntScore.fromJson(s))
          .toList();
    }

    List<TreasureHuntScore> teamScores = [];
    if (json['teamScores'] != null) {
      teamScores = (json['teamScores'] as List)
          .map((s) => TreasureHuntScore.fromJson(s))
          .toList();
    }

    return TreasureHuntScoreboard(
      individualScores: individualScores,
      teamScores: teamScores,
      scoresLocked: json['scoresLocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'individualScores': individualScores.map((s) => s.toJson()).toList(),
      'teamScores': teamScores.map((s) => s.toJson()).toList(),
      'scoresLocked': scoresLocked,
    };
  }
}
