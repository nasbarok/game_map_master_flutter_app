import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TargetEliminationScore {
  final int id;
  final int scenarioId;
  final int playerId;
  final int? teamId;
  final int gameSessionId;
  final int kills;
  final int deaths;
  final int points;
  final DateTime lastUpdated;
  final String? playerName;
  final String? teamName;

  TargetEliminationScore({
    required this.id,
    required this.scenarioId,
    required this.playerId,
    this.teamId,
    required this.gameSessionId,
    required this.kills,
    required this.deaths,
    required this.points,
    required this.lastUpdated,
    this.playerName,
    this.teamName,
  });

  factory TargetEliminationScore.fromJson(Map<String, dynamic> json) {
    return TargetEliminationScore(
      id: json['id'] as int,
      scenarioId: json['scenarioId'] as int,
      playerId: json['playerId'] as int,
      teamId: json['teamId'] as int?,
      gameSessionId: json['gameSessionId'] as int,
      kills: json['kills'] as int,
      deaths: json['deaths'] as int,
      points: json['points'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      playerName: json['playerName'] as String?,
      teamName: json['teamName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scenarioId': scenarioId,
      'playerId': playerId,
      'teamId': teamId,
      'gameSessionId': gameSessionId,
      'kills': kills,
      'deaths': deaths,
      'points': points,
      'lastUpdated': lastUpdated.toIso8601String(),
      'playerName': playerName,
      'teamName': teamName,
    };
  }

  TargetEliminationScore copyWith({
    int? id,
    int? scenarioId,
    int? playerId,
    int? teamId,
    int? gameSessionId,
    int? kills,
    int? deaths,
    int? points,
    DateTime? lastUpdated,
    String? playerName,
    String? teamName,
  }) {
    return TargetEliminationScore(
      id: id ?? this.id,
      scenarioId: scenarioId ?? this.scenarioId,
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      gameSessionId: gameSessionId ?? this.gameSessionId,
      kills: kills ?? this.kills,
      deaths: deaths ?? this.deaths,
      points: points ?? this.points,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      playerName: playerName ?? this.playerName,
      teamName: teamName ?? this.teamName,
    );
  }

  /// Calcule le ratio K/D (Kill/Death)
  double get killDeathRatio {
    if (deaths == 0) {
      return kills.toDouble();
    }
    return kills / deaths;
  }

  /// Retourne le ratio K/D formaté pour l'affichage
  String get formattedKillDeathRatio {
    final ratio = killDeathRatio;
    if (ratio == ratio.roundToDouble()) {
      return ratio.round().toString();
    }
    return ratio.toStringAsFixed(2);
  }

  /// Calcule l'efficacité (pourcentage de survie)
  double get efficiency {
    final totalEngagements = kills + deaths;
    if (totalEngagements == 0) return 0.0;
    return (kills / totalEngagements) * 100;
  }

  /// Retourne l'efficacité formatée pour l'affichage
  String get formattedEfficiency {
    return '${efficiency.toStringAsFixed(1)}%';
  }

  /// Vérifie si ce score est meilleur qu'un autre selon différents critères
  bool isBetterThan(TargetEliminationScore other, ScoreComparison comparison) {
    switch (comparison) {
      case ScoreComparison.points:
        return points > other.points;
      case ScoreComparison.kills:
        return kills > other.kills;
      case ScoreComparison.killDeathRatio:
        return killDeathRatio > other.killDeathRatio;
      case ScoreComparison.efficiency:
        return efficiency > other.efficiency;
    }
  }

  /// Retourne le rang basé sur les points (1 = meilleur)
  int getRank(List<TargetEliminationScore> allScores) {
    final sortedScores = List<TargetEliminationScore>.from(allScores)
      ..sort((a, b) => b.points.compareTo(a.points));
    
    return sortedScores.indexWhere((score) => score.id == id) + 1;
  }

  /// Vérifie si ce joueur est dans le top N
  bool isInTopN(List<TargetEliminationScore> allScores, int n) {
    return getRank(allScores) <= n;
  }

  /// Retourne une couleur basée sur la performance
  ScorePerformance getPerformanceLevel(List<TargetEliminationScore> allScores) {
    final rank = getRank(allScores);
    final totalPlayers = allScores.length;
    
    if (totalPlayers <= 1) return ScorePerformance.average;
    
    final percentile = (rank / totalPlayers) * 100;
    
    if (percentile <= 10) return ScorePerformance.excellent;
    if (percentile <= 25) return ScorePerformance.good;
    if (percentile <= 75) return ScorePerformance.average;
    return ScorePerformance.poor;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TargetEliminationScore && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TargetEliminationScore{id: $id, playerId: $playerId, kills: $kills, deaths: $deaths, points: $points}';
  }
}

enum ScoreComparison {
  points,
  kills,
  killDeathRatio,
  efficiency,
}

enum ScorePerformance {
  excellent,
  good,
  average,
  poor,
}

/// Extension pour obtenir les couleurs et icônes de performance
extension ScorePerformanceExtension on ScorePerformance {
  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (this) {
      case ScorePerformance.excellent:
        return Colors.amber;
      case ScorePerformance.good:
        return theme.colorScheme.primary;
      case ScorePerformance.average:
        return theme.colorScheme.secondary;
      case ScorePerformance.poor:
        return theme.colorScheme.outline;
    }
  }

  IconData getIcon() {
    switch (this) {
      case ScorePerformance.excellent:
        return Icons.emoji_events;
      case ScorePerformance.good:
        return Icons.trending_up;
      case ScorePerformance.average:
        return Icons.trending_flat;
      case ScorePerformance.poor:
        return Icons.trending_down;
    }
  }

  String getLabel() {
    switch (this) {
      case ScorePerformance.excellent:
        return 'Excellent';
      case ScorePerformance.good:
        return 'Bon';
      case ScorePerformance.average:
        return 'Moyen';
      case ScorePerformance.poor:
        return 'Faible';
    }
  }
}

/// Classe utilitaire pour les statistiques d'équipe
class TeamScore {
  final int? teamId;
  final String? teamName;
  final int totalKills;
  final int totalDeaths;
  final int totalPoints;
  final int playerCount;
  final List<TargetEliminationScore> playerScores;

  TeamScore({
    this.teamId,
    this.teamName,
    required this.totalKills,
    required this.totalDeaths,
    required this.totalPoints,
    required this.playerCount,
    required this.playerScores,
  });

  factory TeamScore.fromPlayerScores(List<TargetEliminationScore> scores) {
    if (scores.isEmpty) {
      throw ArgumentError('La liste des scores ne peut pas être vide');
    }

    final firstScore = scores.first;
    
    return TeamScore(
      teamId: firstScore.teamId,
      teamName: firstScore.teamName,
      totalKills: scores.fold(0, (sum, score) => sum + score.kills),
      totalDeaths: scores.fold(0, (sum, score) => sum + score.deaths),
      totalPoints: scores.fold(0, (sum, score) => sum + score.points),
      playerCount: scores.length,
      playerScores: scores,
    );
  }

  double get averageKillDeathRatio {
    if (totalDeaths == 0) return totalKills.toDouble();
    return totalKills / totalDeaths;
  }

  double get averagePointsPerPlayer {
    if (playerCount == 0) return 0.0;
    return totalPoints / playerCount;
  }

  TargetEliminationScore? get topPlayer {
    if (playerScores.isEmpty) return null;
    
    return playerScores.reduce((a, b) => 
      a.points > b.points ? a : b
    );
  }
}

