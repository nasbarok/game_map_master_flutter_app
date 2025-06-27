import 'dart:convert';

import 'package:game_map_master_flutter_app/models/game_session.dart';
import 'package:game_map_master_flutter_app/services/api_service.dart';
import 'package:game_map_master_flutter_app/services/auth_service.dart';
import 'package:game_map_master_flutter_app/services/team_service.dart';
import 'package:get_it/get_it.dart';

import '../models/field.dart';
import '../models/game_session_participant.dart';
import '../models/game_session_scenario.dart';
import '../models/team.dart';
import 'game_state_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';
import 'dart:convert' as jsonConvert;

class GameSessionService {
  final ApiService _apiService;

  GameSessionService(this._apiService);

  Future<GameSession> createGameSession(
      int gameMapId, Field field, int durationMinutes) async {
    final data = {
      'gameMapId': gameMapId,
      'field': field,
      'durationMinutes': durationMinutes,
      'active': false
    };
    final json = await _apiService.post('game-sessions', data);
    return GameSession.fromJson(json);
  }

  Future<GameSession> startGameSession(int gameSessionId) async {
    final now = DateTime.now().toUtc();
    final json = await _apiService.post('game-sessions/$gameSessionId/start', {
      'startTime': now.toIso8601String(),
    });
    return GameSession.fromJson(json);
  }

  Future<GameSession> endGameSession(int gameSessionId) async {
    logger.d('[GameSessionService] 📡 POST /game-sessions/$gameSessionId/end');

    final now = DateTime.now().toUtc();
    final endTimeString = now.toIso8601String();
    logger.d('[GameSessionService] endTime que je vais envoyer: $endTimeString');
    // Ici tu utilises le module importé : json.encode(...)
    logger.d('[GameSessionService] Données envoyées pour end: ${jsonConvert.jsonEncode({
      'endTime': endTimeString,
    })}');

    // Ici tu crées une variable "json" qui n'a rien à voir avec l'import
    final json = await _apiService.post('game-sessions/$gameSessionId/end', {
      'endTime': endTimeString,
    });

    return GameSession.fromJson(json);
  }

  Future<GameSession> getGameSession(int gameSessionId) async {
    logger.d('[GameSessionService] 📡 GET /game-sessions/$gameSessionId');

    final json = await _apiService.get('game-sessions/$gameSessionId');
    final session = GameSession.fromJson(json);

    if (session.gameMap != null) {
      final map = session.gameMap!;
      logger
          .d('[GameSessionService] 🗺️ GameMap ID=${map.id}, name=${map.name}');
      logger.d(
          '[GameSessionService] 📐 backgroundBoundsJson présent : ${map.backgroundBoundsJson != null && map.backgroundBoundsJson!.isNotEmpty}');
      logger.d(
          '[GameSessionService] 📡 satelliteBoundsJson présent : ${map.satelliteBoundsJson != null && map.satelliteBoundsJson!.isNotEmpty}');
      logger.d(
          '[GameSessionService] 🖼️ backgroundImageBase64 longueur : ${map.backgroundImageBase64?.length ?? 0}');
      logger.d(
          '[GameSessionService] 🛰️ satelliteImageBase64 longueur : ${map.satelliteImageBase64?.length ?? 0}');
    } else {
      logger.d('[GameSessionService] ⚠️ Aucune GameMap reçue dans la session');
    }

    return session;
  }

  Future<List<GameSession>> getAllActiveGameSessions() async {
    final jsonList = await _apiService.get('game-sessions/active');
    return (jsonList as List).map((e) => GameSession.fromJson(e)).toList();
  }

  Future<List<GameSession>> getGameSessionsByGameMap(int gameMapId) async {
    final jsonList = await _apiService.get('game-sessions/map/$gameMapId');
    return (jsonList as List).map((e) => GameSession.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getRemainingTime(int gameSessionId) async {
    return await _apiService.get('game-sessions/$gameSessionId/remaining-time');
  }

  Future<GameSessionParticipant> addParticipant(
    int gameSessionId,
    int userId,
    int? teamId,
    bool isHost,
  ) async {
    final json =
        await _apiService.post('game-sessions/$gameSessionId/participants', {
      'userId': userId,
      'teamId': teamId,
      'isHost': isHost,
    });
    return GameSessionParticipant.fromJson(json);
  }

  Future<void> removeParticipant(int gameSessionId, int userId) async {
    await _apiService
        .delete('game-sessions/$gameSessionId/participants/$userId');
  }

  Future<List<GameSessionParticipant>> getParticipants(
      int gameSessionId) async {
    final jsonList =
        await _apiService.get('game-sessions/$gameSessionId/participants');
    return (jsonList as List)
        .map((e) => GameSessionParticipant.fromJson(e))
        .toList();
  }

  Future<List<GameSessionParticipant>> getActiveParticipants(
      int gameSessionId) async {
    final jsonList = await _apiService
        .get('game-sessions/$gameSessionId/active-participants');
    return (jsonList as List)
        .map((e) => GameSessionParticipant.fromJson(e))
        .toList();
  }

  Future<GameSessionScenario> addScenario(
      int gameSessionId, int scenarioId, bool isMainScenario) async {
    final json =
        await _apiService.post('game-sessions/$gameSessionId/scenarios', {
      'scenarioId': scenarioId,
      'isMainScenario': isMainScenario,
    });
    return GameSessionScenario.fromJson(json);
  }

  Future<GameSessionScenario> activateScenario(
      int gameSessionId, int scenarioId) async {
    final json = await _apiService.post(
        'game-sessions/$gameSessionId/scenarios/$scenarioId/activate', {});
    return GameSessionScenario.fromJson(json);
  }

  Future<GameSessionScenario> deactivateScenario(
      int gameSessionId, int scenarioId) async {
    final json = await _apiService.post(
        'game-sessions/$gameSessionId/scenarios/$scenarioId/deactivate', {});
    return GameSessionScenario.fromJson(json);
  }

  Future<List<GameSessionScenario>> getScenarios(int gameSessionId) async {
    final jsonList =
        await _apiService.get('game-sessions/$gameSessionId/scenarios');
    return (jsonList as List)
        .map((e) => GameSessionScenario.fromJson(e))
        .toList();
  }

  Future<List<GameSessionScenario>> getActiveScenarios(
      int gameSessionId) async {
    final jsonList =
        await _apiService.get('game-sessions/$gameSessionId/active-scenarios');
    return (jsonList as List)
        .map((e) => GameSessionScenario.fromJson(e))
        .toList();
  }

  Future<GameSession?> getCurrentSessionByFieldId(int fieldId) async {
    try {
      final json =
          await _apiService.get('game-sessions/current-session/$fieldId');
      logger.d('🗺️ Session active trouvée pour le terrain $fieldId : $json');
      return GameSession.fromJson(json);
    } catch (e) {
      // Log optionnel ou gestion d’erreur douce si 404
      logger
          .d('⚠️ Aucune session active trouvée pour le terrain $fieldId : $e');
      return null;
    }
  }

  /// Vérifie si les conditions pour lancer un scénario Bombe sont remplies
  bool canStartBombOperationScenario(int gameSessionId) {
    // Récupérer les équipes actives pour cette session
    final teamService = GetIt.I<TeamService>();
    final List<Team> teams = teamService.teams;

    // Récupérer les joueurs connectés
    final gameStateService = GetIt.I<GameStateService>();
    final connectedPlayers = gameStateService.connectedPlayersList;

    // Compter les équipes qui ont au moins un joueur
    final Set<int> teamsWithPlayers = {};

    for (final player in connectedPlayers) {
      if (player['teamId'] != null) {
        teamsWithPlayers.add(player['teamId']);
      }
    }

    // Vérifier qu'il y a exactement 2 équipes avec des joueurs
    if (teamsWithPlayers.length != 2) {
      return false;
    }

    return true;
  }
}
