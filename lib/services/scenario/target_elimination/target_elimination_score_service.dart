import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/scenario/target_elimination/target_elimination_score.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

class TargetEliminationScoreService {
  final ApiService _apiService;
  final AuthService _authService;

  TargetEliminationScoreService({
    ApiService? apiService,
    AuthService? authService,
  }) : _apiService = apiService ?? ApiService(),
        _authService = authService ?? AuthService();

  /// Récupère les scores d'un scénario pour une session de jeu
  Future<List<TargetEliminationScore>> getScenarioScores({
    required int scenarioId,
    required int gameSessionId,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/target-elimination/scenarios/$scenarioId/scores',
        queryParameters: {
          'gameSessionId': gameSessionId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TargetEliminationScore.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors du chargement des scores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors du chargement des scores: $e');
    }
  }

  /// Récupère les scores d'équipe pour un scénario
  Future<List<TeamScore>> getTeamScores({
    required int scenarioId,
    required int gameSessionId,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/target-elimination/scenarios/$scenarioId/team-scores',
        queryParameters: {
          'gameSessionId': gameSessionId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) {
          final List<dynamic> playerScoresJson = json['playerScores'];
          final playerScores = playerScoresJson
              .map((scoreJson) => TargetEliminationScore.fromJson(scoreJson))
              .toList();
          
          return TeamScore.fromPlayerScores(playerScores);
        }).toList();
      } else {
        throw Exception('Erreur lors du chargement des scores d\'équipe: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors du chargement des scores d\'équipe: $e');
    }
  }

  /// Récupère le score d'un joueur spécifique
  Future<TargetEliminationScore?> getPlayerScore({
    required int scenarioId,
    required int playerId,
    required int gameSessionId,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/target-elimination/scenarios/$scenarioId/players/$playerId/score',
        queryParameters: {
          'gameSessionId': gameSessionId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TargetEliminationScore.fromJson(data);
      } else if (response.statusCode == 404) {
        return null; // Aucun score trouvé pour ce joueur
      } else {
        throw Exception('Erreur lors du chargement du score du joueur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors du chargement du score du joueur: $e');
    }
  }

  /// Récupère le score du joueur actuel
  Future<TargetEliminationScore?> getCurrentPlayerScore({
    required int scenarioId,
    required int gameSessionId,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    return getPlayerScore(
      scenarioId: scenarioId,
      playerId: currentUser.id,
      gameSessionId: gameSessionId,
    );
  }

  /// Récupère le top N des joueurs
  Future<List<TargetEliminationScore>> getTopPlayers({
    required int scenarioId,
    required int gameSessionId,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/target-elimination/scenarios/$scenarioId/top-players',
        queryParameters: {
          'gameSessionId': gameSessionId.toString(),
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TargetEliminationScore.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors du chargement du top des joueurs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors du chargement du top des joueurs: $e');
    }
  }

  /// Récupère les statistiques globales du scénario
  Future<ScenarioStatistics> getScenarioStatistics({
    required int scenarioId,
    required int gameSessionId,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/target-elimination/scenarios/$scenarioId/statistics',
        queryParameters: {
          'gameSessionId': gameSessionId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ScenarioStatistics.fromJson(data);
      } else {
        throw Exception('Erreur lors du chargement des statistiques: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors du chargement des statistiques: $e');
    }
  }

  /// Met à jour le score d'un joueur (utilisé par le système après une élimination)
  Future<TargetEliminationScore> updatePlayerScore({
    required int scenarioId,
    required int playerId,
    required int gameSessionId,
    required int kills,
    required int deaths,
    required int points,
  }) async {
    try {
      final response = await _apiService.put(
        '/api/target-elimination/scenarios/$scenarioId/players/$playerId/score',
        body: json.encode({
          'gameSessionId': gameSessionId,
          'kills': kills,
          'deaths': deaths,
          'points': points,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TargetEliminationScore.fromJson(data);
      } else {
        throw Exception('Erreur lors de la mise à jour du score: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de la mise à jour du score: $e');
    }
  }

  /// Réinitialise tous les scores d'un scénario
  Future<void> resetScenarioScores({
    required int scenarioId,
    required int gameSessionId,
  }) async {
    try {
      final response = await _apiService.delete(
        '/api/target-elimination/scenarios/$scenarioId/scores',
        queryParameters: {
          'gameSessionId': gameSessionId.toString(),
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la réinitialisation des scores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de la réinitialisation des scores: $e');
    }
  }

  /// Exporte les scores au format CSV
  Future<String> exportScoresToCSV({
    required int scenarioId,
    required int gameSessionId,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/target-elimination/scenarios/$scenarioId/scores/export',
        queryParameters: {
          'gameSessionId': gameSessionId.toString(),
          'format': 'csv',
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Erreur lors de l\'export des scores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de l\'export des scores: $e');
    }
  }

  /// Calcule les statistiques locales à partir d'une liste de scores
  ScenarioStatistics calculateLocalStatistics(List<TargetEliminationScore> scores) {
    if (scores.isEmpty) {
      return ScenarioStatistics.empty();
    }

    final totalKills = scores.fold(0, (sum, score) => sum + score.kills);
    final totalDeaths = scores.fold(0, (sum, score) => sum + score.deaths);
    final totalPoints = scores.fold(0, (sum, score) => sum + score.points);
    final activePlayers = scores.length;

    final topKiller = scores.reduce((a, b) => a.kills > b.kills ? a : b);
    final topScorer = scores.reduce((a, b) => a.points > b.points ? a : b);

    final averageKills = activePlayers > 0 ? totalKills / activePlayers : 0.0;
    final averageDeaths = activePlayers > 0 ? totalDeaths / activePlayers : 0.0;
    final averagePoints = activePlayers > 0 ? totalPoints / activePlayers : 0.0;

    return ScenarioStatistics(
      totalKills: totalKills,
      totalDeaths: totalDeaths,
      totalPoints: totalPoints,
      activePlayers: activePlayers,
      topKillerId: topKiller.playerId,
      topKillerName: topKiller.playerName,
      topKillerKills: topKiller.kills,
      topScorerId: topScorer.playerId,
      topScorerName: topScorer.playerName,
      topScorerPoints: topScorer.points,
      averageKills: averageKills,
      averageDeaths: averageDeaths,
      averagePoints: averagePoints,
    );
  }
}

/// Classe pour les statistiques globales du scénario
class ScenarioStatistics {
  final int totalKills;
  final int totalDeaths;
  final int totalPoints;
  final int activePlayers;
  final int? topKillerId;
  final String? topKillerName;
  final int topKillerKills;
  final int? topScorerId;
  final String? topScorerName;
  final int topScorerPoints;
  final double averageKills;
  final double averageDeaths;
  final double averagePoints;

  ScenarioStatistics({
    required this.totalKills,
    required this.totalDeaths,
    required this.totalPoints,
    required this.activePlayers,
    this.topKillerId,
    this.topKillerName,
    required this.topKillerKills,
    this.topScorerId,
    this.topScorerName,
    required this.topScorerPoints,
    required this.averageKills,
    required this.averageDeaths,
    required this.averagePoints,
  });

  factory ScenarioStatistics.fromJson(Map<String, dynamic> json) {
    return ScenarioStatistics(
      totalKills: json['totalKills'] as int,
      totalDeaths: json['totalDeaths'] as int,
      totalPoints: json['totalPoints'] as int,
      activePlayers: json['activePlayers'] as int,
      topKillerId: json['topKillerId'] as int?,
      topKillerName: json['topKillerName'] as String?,
      topKillerKills: json['topKillerKills'] as int,
      topScorerId: json['topScorerId'] as int?,
      topScorerName: json['topScorerName'] as String?,
      topScorerPoints: json['topScorerPoints'] as int,
      averageKills: (json['averageKills'] as num).toDouble(),
      averageDeaths: (json['averageDeaths'] as num).toDouble(),
      averagePoints: (json['averagePoints'] as num).toDouble(),
    );
  }

  factory ScenarioStatistics.empty() {
    return ScenarioStatistics(
      totalKills: 0,
      totalDeaths: 0,
      totalPoints: 0,
      activePlayers: 0,
      topKillerKills: 0,
      topScorerPoints: 0,
      averageKills: 0.0,
      averageDeaths: 0.0,
      averagePoints: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalKills': totalKills,
      'totalDeaths': totalDeaths,
      'totalPoints': totalPoints,
      'activePlayers': activePlayers,
      'topKillerId': topKillerId,
      'topKillerName': topKillerName,
      'topKillerKills': topKillerKills,
      'topScorerId': topScorerId,
      'topScorerName': topScorerName,
      'topScorerPoints': topScorerPoints,
      'averageKills': averageKills,
      'averageDeaths': averageDeaths,
      'averagePoints': averagePoints,
    };
  }
}

