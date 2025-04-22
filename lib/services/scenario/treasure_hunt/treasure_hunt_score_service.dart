import 'package:airsoft_game_map/services/api_service.dart';

import '../../../models/scenario/treasure_hunt/treasure_hunt_score.dart';

class TreasureHuntScoreService {
  final ApiService _apiService;

  TreasureHuntScoreService(this._apiService);

  Future<TreasureHuntScoreboard> getScoreboard(int scenarioId,int gameSessionId) async {
    final json = await _apiService.get('scenarios/treasure-hunt/$scenarioId/scores?gameSessionId=$gameSessionId');
    print('🧾 Scoreboard JSON reçu: $json');
    return TreasureHuntScoreboard.fromJson(json);
  }

  Future<void> lockScores(int treasureHuntId, bool locked) async {
    await _apiService.post(
      'scenarios/treasure-hunt/$treasureHuntId/lock-scores',
      {'locked': locked},
    );
  }

  Future<void> resetScores(int treasureHuntId) async {
    await _apiService.post(
      'scenarios/treasure-hunt/$treasureHuntId/reset-scores',
      {},
    );
  }

  Future<Map<String, dynamic>> scanQRCode(String qrCode, int userId, int? teamId) async {
    final data = {
      'qrCode': qrCode,
      'userId': userId,
      'teamId': teamId,
    };
    final response = await _apiService.post('scenarios/treasure-hunt/scan', data);
    return response as Map<String, dynamic>;
  }

  String formatRemainingTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  bool isTopPlayerInTeam(TreasureHuntScoreboard scoreboard, int userId, int? teamId) {
    if (teamId == null) return true;

    final teamPlayers = scoreboard.individualScores
        .where((score) => score.teamId == teamId)
        .toList();

    if (teamPlayers.isEmpty) return true;

    teamPlayers.sort((a, b) => b.score.compareTo(a.score));
    return teamPlayers.first.userId == userId;
  }

  int getTeamRanking(TreasureHuntScoreboard scoreboard, int teamId) {
    for (int i = 0; i < scoreboard.teamScores.length; i++) {
      if (scoreboard.teamScores[i].teamId == teamId) {
        return i + 1;
      }
    }
    return 0;
  }

  int getPlayerRanking(TreasureHuntScoreboard scoreboard, int userId) {
    for (int i = 0; i < scoreboard.individualScores.length; i++) {
      if (scoreboard.individualScores[i].userId == userId) {
        return i + 1;
      }
    }
    return 0;
  }
}
