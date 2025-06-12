import 'dart:async';
import 'dart:convert';
import 'package:airsoft_game_map/models/websocket/scenario_activated_message.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../models/coordinate.dart';
import '../../models/game_session.dart';
import '../../models/game_session_participant.dart';
import '../../models/game_session_scenario.dart';
import '../../models/scenario/treasure_hunt/treasure_hunt_score.dart';
import '../../models/websocket/game_session_ended_message.dart';
import '../../models/websocket/game_session_started_message.dart';
import '../../models/websocket/participant_joined_message.dart';
import '../../models/websocket/participant_left_message.dart';
import '../../models/websocket/scenario_added_message.dart';
import '../../models/websocket/scenario_deactivated_message.dart';
import '../../models/websocket/treasure_found_message.dart';
import '../../screens/gamesession/game_session_screen.dart';
import '../auth_service.dart';
import '../game_session_service.dart';
import '../game_state_service.dart';
import '../player_location_service.dart';
import '../scenario/treasure_hunt/treasure_hunt_score_service.dart';
import '../team_service.dart';
import 'package:airsoft_game_map/utils/logger.dart';
class WebSocketGameSessionHandler {
  final GameSessionService _gameSessionService;
  final TreasureHuntScoreService _treasureHuntScoreService;

  WebSocketGameSessionHandler({
    required GameSessionService gameSessionService,
    required TreasureHuntScoreService treasureHuntScoreService,
  })  : _gameSessionService = gameSessionService,
        _treasureHuntScoreService = treasureHuntScoreService;

  final StreamController<GameSession> _gameSessionController = StreamController<GameSession>.broadcast();
  final StreamController<List<GameSessionParticipant>> _participantsController = StreamController<List<GameSessionParticipant>>.broadcast();
  final StreamController<List<GameSessionScenario>> _scenariosController = StreamController<List<GameSessionScenario>>.broadcast();
  final StreamController<TreasureHuntScoreboard> _scoreboardController = StreamController<TreasureHuntScoreboard>.broadcast();
  final StreamController<Map<String, dynamic>> _treasureFoundController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<int> _remainingTimeController = StreamController<int>.broadcast();

  Stream<GameSession> get gameSessionStream => _gameSessionController.stream;
  Stream<List<GameSessionParticipant>> get participantsStream => _participantsController.stream;
  Stream<List<GameSessionScenario>> get scenariosStream => _scenariosController.stream;
  Stream<TreasureHuntScoreboard> get scoreboardStream => _scoreboardController.stream;
  Stream<Map<String, dynamic>> get treasureFoundStream => _treasureFoundController.stream;
  Stream<int> get remainingTimeStream => _remainingTimeController.stream;

  Timer? _remainingTimeTimer;

  void Function(TreasureHuntScoreboard)? _onScoreboardUpdate;



  void handleGameSessionStarted(Map<String, dynamic> message, BuildContext context) {
    GameSessionStartedMessage? msg;
    try {
      msg = GameSessionStartedMessage.fromJson(message);
      logger.d("🧾 Contenu parsé avec succès : ${msg.gameSessionId}");
    } catch (e, stack) {
      logger.d("❌ Erreur parsing GameSessionStartedMessage : $e");
      logger.d("📌 Stacktrace : $stack");
    }

    final gameStateService = context.read<GameStateService>();
    final authService = GetIt.I<AuthService>();
    final teamService = GetIt.I<TeamService>();

    final user = authService.currentUser;
    final teamId = teamService.myTeamId;
    final isHost = false;

    final gameSession = GameSession.fromWebSocketMessage(msg!);

    // Mettre à jour l'état global
    gameStateService.setActiveGameSession(gameSession);
    gameStateService.setGameRunning(true);

    if (user != null && gameSession != null) {
      // Optionnel : petit feedback avant de naviguer
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La partie a commencé !"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Redirection vers l'écran de session
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameSessionScreen(
            userId: user.id!,
            teamId: teamId,
            isHost: isHost,
            gameSession: gameSession,
            fieldId: gameSession.field?.id,
          ),
        ),
      );
    } else {
      logger.d('❌ Impossible de rejoindre la partie : utilisateur ou session manquants');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de rejoindre la partie'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void handleGameSessionEnded(Map<String, dynamic> message, BuildContext context) {
    final gameStateService = GetIt.I<GameStateService>();

    // Stopper le timer de temps restant si utilisé
    gameStateService.stopGameLocally();

    final msg = GameSessionEndedMessage.fromJson(message);
    final endedSessionId = msg.gameSessionId;

    final currentSession = gameStateService.activeGameSession;

    if (currentSession != null && currentSession.id == endedSessionId) {
      logger.d("✅ Session en cours marquée comme terminée (ID: $endedSessionId)");

      // Marquer la session comme terminée
      final updatedSession = currentSession.copyWith(
        active: false,
        endTime: msg.endTime,
      );
      gameStateService.setActiveGameSession(updatedSession);

      // Message à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⏹️ La partie est terminée."),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );

      // Optionnel : retourner automatiquement à l'écran précédent
      Future.delayed(const Duration(seconds: 3), () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Quitter l'écran de session
        }
      });
    } else {
      logger.d("ℹ️ Session terminée mais différente de la session active (ID: $endedSessionId)");
    }
  }


  void handleParticipantJoined(Map<String, dynamic> message, BuildContext context) {
    final msg = ParticipantJoinedMessage.fromJson(message);
    final gameSessionId = msg.gameSessionId;
    _gameSessionService.getActiveParticipants(gameSessionId).then((participants) {
      _participantsController.add(participants);
    });
  }

  void handleParticipantLeft(Map<String, dynamic> message, BuildContext context) {
    final msg = ParticipantLeftMessage.fromJson(message);
    final gameSessionId = msg.gameSessionId;
    _gameSessionService.getActiveParticipants(gameSessionId).then((participants) {
      _participantsController.add(participants);
    });
  }

  void handleScenarioAdded(Map<String, dynamic> message, BuildContext context) {
    final msg = ScenarioAddedMessage.fromJson(message);
    final gameSessionId = msg.gameSessionId;
    _gameSessionService.getScenarios(gameSessionId).then((scenarios) {
      _scenariosController.add(scenarios);
    });
  }

  void handleScenarioActivated(Map<String, dynamic> message, BuildContext context) {
    final msg = ScenarioActivatedMessage.fromJson(message);
    final gameSessionId = msg.gameSessionId;
    final scenarioId = msg.scenarioId;
    _gameSessionService.getScenarios(gameSessionId).then((scenarios) {
      _scenariosController.add(scenarios);

      // Si c'est un scénario de chasse au trésor, charger le tableau des scores
      final scenario = scenarios.firstWhere(
            (s) => s.id == scenarioId,
        orElse: () => GameSessionScenario.placeholder(scenarioId),
      );
      if (scenario != null && scenario.scenarioType == 'TREASURE_HUNT') {
        _treasureHuntScoreService.getScoreboard(scenario.scenarioId,gameSessionId).then((scoreboard) {
          _scoreboardController.add(scoreboard);
        });
      }
    });
  }

  void handleScenarioDeactivated(Map<String, dynamic> message, BuildContext context) {
    final msg = ScenarioDeactivatedMessage.fromJson(message);
    final gameSessionId = msg.gameSessionId;
    final scenarioId = msg.scenarioId;
    _gameSessionService.getScenarios(gameSessionId).then((scenarios) {
      _scenariosController.add(scenarios);
    });
  }

  void handleTreasureFound(
      Map<String, dynamic> message,
      BuildContext context, {
        void Function(TreasureHuntScoreboard)? onScoreboardUpdate,
      }) {
    final msg = TreasureFoundMessage.fromJson(message);
    final gameSessionId = msg.data.gameSessionId;
    final scenarioId = msg.data.scenarioId;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.message),
        backgroundColor: Colors.deepPurple,
        duration: const Duration(seconds: 5),
      ),
    );

    _treasureHuntScoreService.getScoreboard(scenarioId!, gameSessionId!).then((scoreboard) {
      logger.d('🎯 Scoreboard mis à jour : ${scoreboard.individualScores.length} scores');

      if (onScoreboardUpdate != null) {
        onScoreboardUpdate(scoreboard);
      } else if (_onScoreboardUpdate != null) {
        _onScoreboardUpdate!(scoreboard);
      }
    });
  }
  void registerOnScoreboardUpdate(void Function(TreasureHuntScoreboard) callback) {
    _onScoreboardUpdate = callback;
  }
  void dispose() {
    _remainingTimeTimer?.cancel();
    _gameSessionController.close();
    _participantsController.close();
    _scenariosController.close();
    _scoreboardController.close();
    _treasureFoundController.close();
    _remainingTimeController.close();
  }

  void handlePlayerPosition(Map<String, dynamic> message, BuildContext context) {
    try {
      logger.d("📥 [handlePlayerPosition] Message brut reçu : $message");

      final type = message['type'];
      logger.d("🔍 Type détecté : $type");
      if (type != 'PLAYER_POSITION') {
        logger.d("⏩ Ignoré : type différent de PLAYER_POSITION");
        return;
      }

      final payload = message['payload'];
      logger.d("📦 Payload extrait : $payload");

      if (payload == null) {
        logger.d("❌ Payload nul, arrêt du traitement");
        return;
      }

      final userId = message['senderId'];
      final lat = payload['latitude'];
      final lon = payload['longitude'];
      final gameSessionId = payload['gameSessionId'];
      final teamId = payload['teamId'];

      logger.d("👤 userId=$userId | lat=$lat | lon=$lon | teamId=$teamId | session=$gameSessionId");

      if (userId == null || lat == null || lon == null) {
        logger.d("❌ Champs manquants dans le payload (userId, lat ou lon)");
        return;
      }

      final currentUserId = GetIt.I<AuthService>().currentUser?.id;
      if (userId == currentUserId) {
        logger.d("⏩ Ignoré : c'est moi-même (userId=$userId)");
        return;
      }

      logger.d("📡 Mise à jour position du joueur $userId");

      GetIt.I<PlayerLocationService>().updatePlayerPosition(
        userId,
        Coordinate(latitude: lat, longitude: lon),
      );

      logger.d("✅ Position du joueur $userId mise à jour : $lat, $lon");

    } catch (e, stack) {
      logger.d('❌ Erreur lors du traitement de la position: $e');
      logger.d('📄 Stacktrace : $stack');
    }
  }


}
