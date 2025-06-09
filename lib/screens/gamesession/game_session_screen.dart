import 'dart:async';
import 'package:airsoft_game_map/services/api_service.dart';
import 'package:airsoft_game_map/services/scenario_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../models/game_session.dart';
import '../../models/game_session_participant.dart';
import '../../models/game_session_scenario.dart';
import '../../models/scenario/bomb_operation/bomb_operation_session.dart';
import '../../models/scenario/treasure_hunt/treasure_hunt_score.dart';
import '../../services/game_session_service.dart';
import '../../services/game_state_service.dart';
import '../../services/player_location_service.dart';
import '../../services/scenario/bomb_operation/bomb_operation_service.dart';
import '../../services/scenario/treasure_hunt/treasure_hunt_score_service.dart';
import '../../services/team_service.dart';
import '../../services/websocket/web_socket_game_session_handler.dart';
import '../../widgets/bomb_operation_info_card.dart';
import '../../widgets/game_map_widget.dart';
import '../../widgets/participants_card.dart';
import '../../widgets/qr_code_scanner_widgets.dart';
import '../../widgets/time_remaining_card.dart';
import '../../widgets/treasure_hunt_scoreboard_card.dart';
import '../scenario/treasure_hunt/treasure_hunt_scanner_screen.dart';
import 'package:airsoft_game_map/utils/logger.dart';

class GameSessionScreen extends StatefulWidget {
  GameSession gameSession;
  final int userId;
  late final int? teamId;
  final bool isHost;
  final int? fieldId;

  GameSessionScreen({
    Key? key,
    required this.gameSession,
    required this.userId,
    this.teamId,
    required this.isHost,
    this.fieldId,
  }) : super(key: key);

  @override
  _GameSessionScreenState createState() => _GameSessionScreenState();
}

class _GameSessionScreenState extends State<GameSessionScreen> {
  final GameSessionService _gameSessionService = GetIt.I<GameSessionService>();
  final ApiService _apiService = GetIt.I<ApiService>();
  final TreasureHuntScoreService _treasureHuntScoreService =
      GetIt.I<TreasureHuntScoreService>();

  bool _isTreasureHuntActive = false;
  GameSession? _gameSession;
  Timer? _timeTimer;
  int _displayedTimeInSeconds = 0;
  bool _isCountdownMode = false;

  List<GameSessionParticipant> _participants = [];
  List<GameSessionScenario> _scenarios = [];
  TreasureHuntScoreboard? _scoreboard;
  int _remainingTimeInSeconds = 0;
  bool _isLoading = true;
  String? _errorMessage;
  late var treasureHuntScenarioDTO = null;

  // Couleurs pour les équipes
  final Map<int, Color> _teamColors = {
    1: Colors.blue,
    2: Colors.red,
    3: Colors.green,
    4: Colors.orange,
    5: Colors.purple,
    6: Colors.teal,
    7: Colors.pink,
    8: Colors.indigo,
  };

  // Contrôleur pour les notifications de trésors trouvés
  final ScrollController _scrollController = ScrollController();

  // Notifications de trésors trouvés
  List<Map<String, dynamic>> _treasureFoundNotifications = [];
  bool _hasBombOperationScenario = false;

  @override
  void initState() {
    super.initState();
    logger
        .d('🟢 [GameSessionScreen] initState: Chargement initial des données');
    _loadInitialData();

    // ✅ Abonnement registerOnScoreboardUpdate
    GetIt.I<WebSocketGameSessionHandler>()
        .registerOnScoreboardUpdate((scoreboard) {
      if (mounted) {
        setState(() {
          _scoreboard = scoreboard;
        });
      }
    });

    final locationService = GetIt.I<PlayerLocationService>();
    final teamService = GetIt.I<TeamService>();
    int? teamId = widget.teamId;
    if (teamId == null) {
      logger.d(
          '🔍 [GameSessionScreen] teamId non fourni, recherche de l\'équipe active');
      teamId = teamService.getTeamIdForPlayer(widget.userId);
    } else {
      logger.d('🔍 [GameSessionScreen] teamId fourni, utilisé directement');
    }
    final fieldId = widget.fieldId ?? widget.gameSession.field?.id;
    locationService.initialize(widget.userId, teamId, fieldId!);
    logger.d(
        '🔄 [WebSocketService] Reconnecté. Chargement des positions initiales...');
    locationService.loadInitialPositions(fieldId);
    locationService.startLocationSharing(widget.gameSession.id!);
  }

  /// Vérifie si le scénario Opération Bombe est actif pour cette session
  void _checkForBombOperationScenario() async {
    if (_scenarios.isEmpty) {
      logger.d(
          '🔍 [GameSessionScreen] [checkForBombOperationScenario] Aucun scénario actif à vérifier.');
      return;
    }

    for (final scenario in _scenarios) {
      logger.d(
          '🔍 [GameSessionScreen] [checkForBombOperationScenario] Scénario analysé: ID=${scenario.scenarioId}, type=${scenario.scenarioType}, actif=${scenario.active}');
      if (scenario.scenarioType == 'bomb_operation' &&
          scenario.active == true) {
        logger.d(
            '💣 [GameSessionScreen] [checkForBombOperationScenario] Scénario Opération Bombe détecté !');

        setState(() {
          _hasBombOperationScenario = true;
        });

        final bombOperationService = GetIt.I<BombOperationService>();

        if (bombOperationService.activeSessionScenarioBomb == null) {
          logger.d(
              '🧨 [GameSessionScreen] Initialisation du BombOperationService en cours...');
          try {
            final bombSession = await _apiService.get(
              'game-sessions/bomb-operation/by-game-session/${widget.gameSession.id}',
            );
            final parsedSession = BombOperationSession.fromJson(bombSession);
            await bombOperationService.initialize(parsedSession);
            logger.d(
                '✅ [GameSessionScreen] BombOperationService initialisé avec succès');
          } catch (e) {
            logger.d(
                '❌ [GameSessionScreen] Erreur lors de l\'initialisation de BombOperationService : $e');
          }
        } else {
          logger
              .d('ℹ️ [GameSessionScreen] BombOperationService déjà initialisé');
        }

        return;
      }
    }

    logger.d(
        '🚫 [GameSessionScreen] Aucun scénario Opération Bombe actif trouvé.');
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    logger.d('🔄 [GameSessionScreen] _loadInitialData: Start');

    try {
      // ✅ 1. Utiliser directement les données si déjà présentes
      final gameSession = widget.gameSession;
      logger.d('✅ GameSession reçue via constructeur: ID=${gameSession.id}');

      // 🔍 Inspecter les détails de la GameMap
      final map = gameSession.gameMap;
      if (map != null) {
        logger.d(
            '[GameSessionScreen] 🗺️ GameMap ID=${map.id}, name=${map.name}');
        logger.d(
            '[GameSessionScreen] 🖼️ backgroundImageBase64 length: ${map.backgroundImageBase64?.length ?? 0}');
        logger.d(
            '[GameSessionScreen] 🛰️ satelliteImageBase64 length: ${map.satelliteImageBase64?.length ?? 0}');
        logger.d(
            '[GameSessionScreen] 📐 backgroundBoundsJson present: ${map.backgroundBoundsJson != null && map.backgroundBoundsJson!.isNotEmpty}');
        logger.d(
            '[GameSessionScreen] 📡 satelliteBoundsJson present: ${map.satelliteBoundsJson != null && map.satelliteBoundsJson!.isNotEmpty}');
      } else {
        logger.d('[GameSessionScreen] ⚠️ Aucune GameMap liée à la session');
      }

      List<GameSessionParticipant> participants = _participants;
      if (_participants.isEmpty) {
        participants =
            await _gameSessionService.getActiveParticipants(gameSession.id!);
        logger.d('👥 Participants chargés: ${participants.length}');
      }

      List<GameSessionScenario> scenarios = _scenarios;
      if (_scenarios.isEmpty) {
        scenarios = await _gameSessionService.getScenarios(gameSession.id!);
        logger.d('🎯 Scénarios chargés: ${scenarios.length}');
      }

      final remainingTimeResponse =
          await _gameSessionService.getRemainingTime(gameSession.id!);
      logger.d(
          '⏱️ Temps restant récupéré: ${remainingTimeResponse['remainingTimeInSeconds']} secondes');

      TreasureHuntScoreboard? scoreboard;
      final scenarioService = context.read<ScenarioService>();
      for (final scenario in scenarios) {
        logger.d(
            '🔍 Traitement du scénario ID=${scenario.scenarioId}, type=${scenario.scenarioType}, actif=${scenario.active}');

        if (scenario.active != true) {
          logger.d('⏭️ Scénario inactif, ignoré');
          continue;
        }

        switch (scenario.scenarioType) {
          case 'treasure_hunt':
            logger.d(
                '🗺️ Scénario treasure_hunt actif trouvé, chargement du scoreboard...');
            _isTreasureHuntActive = true;
            try {
              scoreboard = await _treasureHuntScoreService.getScoreboard(
                  scenario.scenarioId, gameSession.id!);
              logger.d('📊 Scoreboard chargé pour TREASURE_HUNT');
            } catch (e) {
              logger.d('❌ Erreur lors du chargement du scoreboard: $e');
            }
            scenarioService.getScenarioDTOById(scenario.scenarioId).then((dto) {
              setState(() {
                treasureHuntScenarioDTO = dto;
              });
            });
            break;
          default:
            logger.d(
                '⚠️ Type de scénario inconnu ou non géré: ${scenario.scenarioType}');
        }
      }

      setState(() {
        _gameSession = gameSession;
        _participants = participants;
        _scenarios = scenarios;
        _scoreboard = scoreboard;
        _remainingTimeInSeconds =
            remainingTimeResponse['remainingTimeInSeconds'];
        _isLoading = false;
      });
      logger.d('✅ [GameSessionScreen] Données initiales chargées avec succès');

      // Gestion du timer
      _timeTimer?.cancel();

      if (gameSession.active) {
        _isCountdownMode = _remainingTimeInSeconds > 0;

        if (_isCountdownMode) {
          _displayedTimeInSeconds = _remainingTimeInSeconds;
        } else {
          if (_gameSession?.startTime != null) {
            _displayedTimeInSeconds =
                DateTime.now().difference(_gameSession!.startTime).inSeconds;
          }
        }

        if (!mounted || _gameSession?.active != true) return;

        _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_isCountdownMode) {
              if (_displayedTimeInSeconds > 0) {
                _displayedTimeInSeconds--;
              } else {
                timer.cancel();
              }
            } else {
              _displayedTimeInSeconds++;
            }
          });
        });
      }
    } catch (e) {
      logger.d(
          '❌ [GameSessionScreen] _loadInitialData Erreur lors du chargement initial: $e');
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données: $e';
        _isLoading = false;
      });
    }

    // Vérifier si le scénario Bombe est actif
    _checkForBombOperationScenario();
    /*  if (_hasBombOperationScenario) {
      logger.d('🧨 [GameSessionScreen] [_loadInitialData] Initialisation du BombOperationService...');
      await GetIt.I<BombOperationService>().initialize(widget.gameSession.id!);
    }*/
  }

  void _navigateToQRCodeScanner() {
    logger.d('📷 [GameSessionScreen] Ouverture scanner QR code');

    if (treasureHuntScenarioDTO?.treasureHuntScenario == null) {
      logger
          .d('⚠️ Aucun scénario de chasse au trésor actif trouvé dans le DTO');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun scénario de chasse au trésor actif'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final scenarioId = treasureHuntScenarioDTO!.scenario.id!;
    logger.d(
        '✅ Scénario de chasse au trésor trouvé, ouverture scanner avec ID: $scenarioId');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TreasureHuntScannerScreen(
          userId: widget.userId,
          teamId: widget.teamId,
          treasureHuntId: scenarioId,
          gameSessionId: _gameSession!.id!,
        ),
      ),
    );
  }

  void _endGameSession() async {
    logger.d('⏹️ [GameSessionScreen] Fin de la partie demandée');
    try {
      final updatedSession =
          await _gameSessionService.endGameSession(_gameSession!.id!);
      logger.d('✅ Partie terminée avec succès');
      final gameStateService = context.read<GameStateService>();

      // 🔴 AJOUT ICI : arrêt du timer
      _timeTimer?.cancel();

      gameStateService.setGameRunning(false);
      setState(() {
        _gameSession = updatedSession;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La partie a été arrêtée.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      logger.d('❌ Erreur lors de la fin de la partie: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la fin de la partie: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildScoreboardSection() {
    if (_scoreboard != null &&
        (_scoreboard!.individualScores.isNotEmpty ||
            _scoreboard!.teamScores.isNotEmpty)) {
      /*logger.d('🧩 Affichage du Scoreboard : '
          '${_scoreboard!.individualScores.length} scores individuels, '
          '${_scoreboard!.teamScores.length} scores équipes');*/
      return TreasureHuntScoreboardCard(
        scoreboard: _scoreboard!,
        currentUserId: widget.userId,
        currentTeamId: widget.teamId,
        teamColors: _teamColors,
        scenarioDTO: treasureHuntScenarioDTO,
      );
    } else {
      logger.d('🕳️ Aucun score à afficher pour le moment');
      return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Session de jeu'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Session de jeu'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialData,
                child: Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final bool isActive = _gameSession?.active == true;
    final bool bombActive =
        _scenarios.any((s) => s.scenarioType == 'bomb_operation');
    return Scaffold(
      appBar: AppBar(
        title: Text('Session de jeu'),
        actions: [
          if (widget.isHost && isActive)
            IconButton(
              icon: Icon(Icons.cancel),
              onPressed: _endGameSession,
              tooltip: 'Fin de la partie',
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Contenu principal
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Carte de temps restant
                TimeRemainingCard(
                  remainingTimeInSeconds: _displayedTimeInSeconds,
                  isActive: isActive,
                  isCountdown: _isCountdownMode,
                ),
                SizedBox(height: 16),
// Widget d'information Bombe Operation (uniquement si le scénario est actif)
                if (_hasBombOperationScenario)
                  BombOperationInfoCard(
                    teamId: widget.teamId,
                    userId: widget.userId,
                    gameSessionId: _gameSession!.id!,
                  ),
                SizedBox(height: 16),
                // Bouton de scan QR code (uniquement si la partie est active)
                if (isActive && _isTreasureHuntActive)
                  QRCodeScannerButton(
                    onPressed: _navigateToQRCodeScanner,
                    isActive: isActive,
                  ),
                // 👉 Ta carte interactive ici
                SizedBox(height: 16),

                if (_gameSession?.gameMap != null &&
                    _gameSession!.gameMap!.hasInteractiveMapConfig)
                  GameMapWidget(
                    gameSessionId: _gameSession!.id!,
                    gameMap: _gameSession!.gameMap!,
                    userId: widget.userId,
                    teamId: widget.teamId,
                    hasBombOperationScenario: _hasBombOperationScenario,
                    participants: _participants,
                    fieldId: _gameSession?.gameMap?.field?.id! ?? widget.fieldId,
                  ),
                SizedBox(height: 16),
                // Tableau des scores (uniquement si un scénario de chasse au trésor est actif)
                _buildScoreboardSection(),
                // Carte des participants
                ParticipantsCard(
                  participants: _participants,
                  teamColors: _teamColors,
                ),

                // Espace pour les notifications de trésors trouvés
                SizedBox(height: 100),
              ],
            ),
          ),

          // Notifications de trésors trouvés
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                children: _treasureFoundNotifications.map((notification) {
                  final username = notification['username'] ?? 'Joueur';
                  final teamName = notification['teamName'];
                  final points = notification['points'] ?? 0;
                  final symbol = notification['symbol'] ?? '🏆';

                  return Card(
                    color: Colors.green.shade100,
                    margin: EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              symbol,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                    color: Colors.black, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: username,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (teamName != null) ...[
                                    TextSpan(text: ' de l\'équipe '),
                                    TextSpan(
                                      text: teamName,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                  TextSpan(text: ' a trouvé un trésor de '),
                                  TextSpan(
                                    text: '$points points',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  TextSpan(text: ' !'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    logger.d('🧹 [GameSessionScreen] Dispose: nettoyage des contrôleurs');
    _scrollController.dispose();
    _timeTimer?.cancel();
    super.dispose();
  }
}
