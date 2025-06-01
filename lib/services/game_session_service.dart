import 'dart:convert';

import 'package:airsoft_game_map/models/game_session.dart';
import 'package:airsoft_game_map/services/api_service.dart';
import 'package:airsoft_game_map/services/auth_service.dart';
import 'package:airsoft_game_map/services/team_service.dart';
import 'package:get_it/get_it.dart';

import '../models/field.dart';
import '../models/game_session_participant.dart';
import '../models/game_session_scenario.dart';
import '../models/team.dart';
import 'game_state_service.dart';

class GameSessionService {
  final ApiService _apiService;

  GameSessionService(this._apiService);

  Future<GameSession> createGameSession(int gameMapId,Field field, int durationMinutes) async {
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
    final json = await _apiService.post('game-sessions/$gameSessionId/start', {});
    return GameSession.fromJson(json);
  }

  Future<GameSession> endGameSession(int gameSessionId) async {
    final json = await _apiService.post('game-sessions/$gameSessionId/end', {});
    return GameSession.fromJson(json);
  }

  Future<GameSession> getGameSession(int gameSessionId) async {
    print('[GameSessionService] 📡 GET /game-sessions/$gameSessionId');

    final json = await _apiService.get('game-sessions/$gameSessionId');
    final session = GameSession.fromJson(json);

    if (session.gameMap != null) {
      final map = session.gameMap!;
      print('[GameSessionService] 🗺️ GameMap ID=${map.id}, name=${map.name}');
      print('[GameSessionService] 📐 backgroundBoundsJson présent : ${map.backgroundBoundsJson != null && map.backgroundBoundsJson!.isNotEmpty}');
      print('[GameSessionService] 📡 satelliteBoundsJson présent : ${map.satelliteBoundsJson != null && map.satelliteBoundsJson!.isNotEmpty}');
      print('[GameSessionService] 🖼️ backgroundImageBase64 longueur : ${map.backgroundImageBase64?.length ?? 0}');
      print('[GameSessionService] 🛰️ satelliteImageBase64 longueur : ${map.satelliteImageBase64?.length ?? 0}');
    } else {
      print('[GameSessionService] ⚠️ Aucune GameMap reçue dans la session');
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
    final json = await _apiService.post('game-sessions/$gameSessionId/participants', {
      'userId': userId,
      'teamId': teamId,
      'isHost': isHost,
    });
    return GameSessionParticipant.fromJson(json);
  }

  Future<void> removeParticipant(int gameSessionId, int userId) async {
    await _apiService.delete('game-sessions/$gameSessionId/participants/$userId');
  }

  Future<List<GameSessionParticipant>> getParticipants(int gameSessionId) async {
    final jsonList = await _apiService.get('game-sessions/$gameSessionId/participants');
    return (jsonList as List).map((e) => GameSessionParticipant.fromJson(e)).toList();
  }

  Future<List<GameSessionParticipant>> getActiveParticipants(int gameSessionId) async {
    final jsonList = await _apiService.get('game-sessions/$gameSessionId/active-participants');
    return (jsonList as List).map((e) => GameSessionParticipant.fromJson(e)).toList();
  }

  Future<GameSessionScenario> addScenario(int gameSessionId, int scenarioId, bool isMainScenario) async {
    final json = await _apiService.post('game-sessions/$gameSessionId/scenarios', {
      'scenarioId': scenarioId,
      'isMainScenario': isMainScenario,
    });
    return GameSessionScenario.fromJson(json);
  }

  Future<GameSessionScenario> activateScenario(int gameSessionId, int scenarioId) async {
    final json = await _apiService.post('game-sessions/$gameSessionId/scenarios/$scenarioId/activate', {});
    return GameSessionScenario.fromJson(json);
  }

  Future<GameSessionScenario> deactivateScenario(int gameSessionId, int scenarioId) async {
    final json = await _apiService.post('game-sessions/$gameSessionId/scenarios/$scenarioId/deactivate', {});
    return GameSessionScenario.fromJson(json);
  }

  Future<List<GameSessionScenario>> getScenarios(int gameSessionId) async {
    final jsonList = await _apiService.get('game-sessions/$gameSessionId/scenarios');
    return (jsonList as List).map((e) => GameSessionScenario.fromJson(e)).toList();
  }

  Future<List<GameSessionScenario>> getActiveScenarios(int gameSessionId) async {
    final jsonList = await _apiService.get('game-sessions/$gameSessionId/active-scenarios');
    return (jsonList as List).map((e) => GameSessionScenario.fromJson(e)).toList();
  }

  Future<GameSession?> getCurrentSessionByFieldId(int fieldId) async {
    try {
      final json = await _apiService.get('game-sessions/current-session/$fieldId');
      print('🗺️ Session active trouvée pour le terrain $fieldId : $json');
      return GameSession.fromJson(json);
    } catch (e) {
      // Log optionnel ou gestion d’erreur douce si 404
      print('⚠️ Aucune session active trouvée pour le terrain $fieldId : $e');
      return null;
    }
  }

  /// Vérifie si les conditions pour lancer un scénario Bombe sont remplies
  bool canStartBombOperationScenario(int gameSessionId) {
    // Récupérer les équipes actives pour cette session
    final teamService = GetIt.I<TeamService>();
    final List<Team> activeTeams = teamService.getTeamsForGameSession(gameSessionId);

    // Vérifier qu'il y a exactement 2 équipes
    if (activeTeams.length != 2) {
      return false;
    }

    // Vérifier que chaque équipe a au moins un joueur
    final gameStateService = GetIt.I<GameStateService>();
    final connectedPlayers = gameStateService.connectedPlayersList;

    final team1Players = connectedPlayers.where((player) => player['teamId'] == activeTeams[0].id).toList();
    final team2Players = connectedPlayers.where((player) => player['teamId'] == activeTeams[1].id).toList();

    if (team1Players.isEmpty || team2Players.isEmpty) {
      return false;
    }

    return true;
  }
}
