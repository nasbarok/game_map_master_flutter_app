import 'dart:async';
import 'package:game_map_master_flutter_app/services/api_service.dart';
import 'package:game_map_master_flutter_app/services/scenario_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/coordinate.dart';
import '../../models/game_session.dart';
import '../../models/game_session_participant.dart';
import '../../models/game_session_scenario.dart';
import '../../models/scenario/bomb_operation/bomb_operation_session.dart';
import '../../models/scenario/treasure_hunt/treasure_hunt_score.dart';
import '../../services/game_session_service.dart';
import '../../services/game_state_service.dart';
import '../../services/player_location_service.dart';
import '../../services/scenario/bomb_operation/bomb_operation_auto_manager.dart';
import '../../services/scenario/bomb_operation/bomb_operation_service.dart';
import '../../services/scenario/bomb_operation/bomb_proximity_detection_service.dart';
import '../../services/scenario/treasure_hunt/treasure_hunt_score_service.dart';
import '../../services/team_service.dart';
import '../../services/websocket/bomb_operation_web_socket_handler.dart';
import '../../services/websocket/web_socket_game_session_handler.dart';
import '../../widgets/adaptive_background.dart';
import '../../widgets/bomb_operation_info_card.dart';
import '../../widgets/game_map_widget.dart';
import '../../widgets/participants_card.dart';
import '../../widgets/qr_code_scanner_widgets.dart';
import '../../widgets/time_remaining_card.dart';
import '../../widgets/treasure_hunt_scoreboard_card.dart';
import '../scenario/treasure_hunt/treasure_hunt_scanner_screen.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

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
  BombOperationAutoManager? _bombAutoManager;
  late StreamSubscription<Map<int, Coordinate>> _locationSub;

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
  bool _isBombManagerReady = false;
  int effectiveFieldId = -1;

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
    effectiveFieldId = (widget.fieldId ?? widget.gameSession.field?.id)!;
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
    locationService.initialize(widget.userId, teamId, effectiveFieldId);
    logger.d(
        '🔄 [WebSocketService] Reconnecté. Chargement des positions initiales...');
    locationService.loadInitialPositions(effectiveFieldId);
    locationService.startLocationTracking(widget.gameSession.id!);
    // 🔁 Abonnement aux positions pour mise à jour de l’auto-manager
    _locationSub = locationService.positionStream.listen((positions) {
      final myPos = positions[widget.userId];
      if (myPos != null && _bombAutoManager != null) {
        _bombAutoManager!.updatePlayerPosition(myPos.latitude, myPos.longitude);
      }
    });
  }

  /// Vérifie si le scénario Opération Bombe est actif pour cette session
  void _checkForBombOperationScenario() async {
    if (_scenarios.isEmpty) {
      logger.d('🔍 [GameSessionScreen] Aucun scénario à analyser.');
      return;
    }

    logger.d('🔍 [GameSessionScreen] Analyse des scénarios actifs...');
    GameSessionScenario? bombScenario;

    for (final scenario in _scenarios) {
      logger.d(
          '➡️ Scénario ID=${scenario.scenarioId}, type=${scenario.scenarioType}, actif=${scenario.active}');
      if (scenario.scenarioType == 'bomb_operation' &&
          scenario.active == true) {
        logger.d(
            '💣 Scénario Opération Bombe détecté (ID=${scenario.scenarioId})');
        bombScenario = scenario;
        break;
      }
    }

    if (bombScenario == null) {
      logger.d('🚫 Aucun scénario de type bombe actif trouvé.');
      return;
    }

    setState(() {
      _hasBombOperationScenario = true;
    });

    final bombOperationService = GetIt.I<BombOperationService>();

    logger.d(
        '🧨 BombOperationService non encore initialisé, appel API en cours...');
    try {
      final bombSession = await _apiService.get(
        'game-sessions/bomb-operation/by-game-session/${widget.gameSession.id}',
      );
      logger.d('📦 Réponse API reçue, parsing JSON...');
      final parsedSession = BombOperationSession.fromJson(bombSession);
      await bombOperationService.initialize(parsedSession);
      logger.d('✅ BombOperationService initialisé avec succès');
    } catch (e, stack) {
      logger.e(
          '❌ Erreur durant l\'initialisation du BombOperationService : $e\n$stack');
      return;
    }

    final session = bombOperationService.activeSessionScenarioBomb;
    if (session == null || session.bombOperationScenario == null) {
      logger.e(
          '❌ Session ou scénario BombOperation absent après initialisation !');
      return;
    }

    final scenarioData = session.bombOperationScenario!;
    logger.d(
        '🧠 Scénario opération bombe chargé : ID=${scenarioData.id}, nom=${scenarioData.activeSites}');
    logger.d('🔌 Configuration du ProximityService...');
    final bombHandler = GetIt.I<BombOperationWebSocketHandler>();
    final proximity = BombProximityDetectionService(
      bombOperationService: bombOperationService,
      bombOperationScenario: scenarioData,
      gameSessionId: widget.gameSession.id!,
      userId: widget.userId,
    );
    bombHandler.setProximityService(proximity);
    logger.d('✅ ProximityService injecté');

    logger.d('⚙️ Instanciation de l’auto-manager...');
    _bombAutoManager = BombOperationAutoManager(
      bombOperationScenario: scenarioData,
      bombOperationService: bombOperationService,
      gameSessionId: widget.gameSession.id!,
      fieldId: widget.fieldId!,
      userId: widget.userId,
      context: context,
    );

    _bombAutoManager?.onStatusUpdate = (message, {bool isSuccess = true}) {
      logger.d('🟢 Mise à jour status auto-manager : $message');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isSuccess ? Colors.green : Colors.orange,
          ),
        );
      }
    };

    _bombAutoManager?.onBombEvent = (site, action, playerName) {
      logger.d('📢 Événement bombe : $action sur ${site.name} par $playerName');
    };

    try {
      logger.d(
          '🚀 Lancement de l’auto-manager avec ${session.toActiveBombSites.length} site(s) a activer...');
      await _bombAutoManager!.start(
        activeBombSites: session.toActiveBombSites,
      );
      setState(() {
        _isBombManagerReady = true;
      });
      logger.d('✅ Auto-manager démarré avec succès.');
    } catch (e, stack) {
      logger.e('❌ Échec du démarrage de l’auto-manager : $e\n$stack');
    }
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
    final l10n = AppLocalizations.of(context)!;
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
        SnackBar(
          content: Text(l10n.gameEndedMessage),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      logger.d('❌ Erreur lors de la fin de la partie: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorEndingGame(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildScoreboardSection() {
    final l10n = AppLocalizations.of(context)!;
    if (_scoreboard != null &&
        (_scoreboard!.individualScores.isNotEmpty ||
            _scoreboard!.teamScores.isNotEmpty)) {
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
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return AdaptiveScaffold(
        gameBackgroundType: GameBackgroundType.game,
        backgroundOpacity: 0.9,
        appBar: AppBar(
          title: Text(l10n.gameSessionScreenTitle),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return AdaptiveScaffold(
        gameBackgroundType: GameBackgroundType.game,
        backgroundOpacity: 0.9,
        appBar: AppBar(
          title: Text(l10n.gameSessionScreenTitle),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialData,
                child: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
      );
    }

    final bool isActive = _gameSession?.active == true;
    return AdaptiveScaffold(
      gameBackgroundType: GameBackgroundType.game,
      backgroundOpacity: 0.9,
      appBar: AppBar(
        title: Text(l10n.gameSessionScreenTitle),
        actions: [
          if (widget.isHost && isActive)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _endGameSession,
              tooltip: l10n.endGameTooltip,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: l10n.refreshTooltip,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Contenu principal
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Carte de temps restant
                TimeRemainingCard(
                  remainingTimeInSeconds: _displayedTimeInSeconds,
                  isActive: isActive,
                  isCountdown: _isCountdownMode,
                ),
                const SizedBox(height: 16),
// Widget d'information Bombe Operation (uniquement si le scénario est actif)
                if (_hasBombOperationScenario)
                  _isBombManagerReady && _bombAutoManager != null
                      ? BombOperationInfoCard(
                          teamId: widget.teamId,
                          userId: widget.userId,
                          gameSessionId: _gameSession!.id!,
                          autoManager: _bombAutoManager!,
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 12),
                                Text(l10n.bombScenarioLoading),
                              ],
                            ),
                          ),
                        ),

                const SizedBox(height: 16),
                // Bouton de scan QR code (uniquement si la partie est active)
                if (isActive && _isTreasureHuntActive)
                  QRCodeScannerButton(
                    onPressed: _navigateToQRCodeScanner,
                    isActive: isActive, // Pass l10n.qrScannerButtonActive if you want the text from l10n
                  ),
                // 👉 Ta carte interactive ici
                const SizedBox(height: 16),

                if (_gameSession?.gameMap != null &&
                    _gameSession!.gameMap!.hasInteractiveMapConfig)
                  GameMapWidget(
                    gameSessionId: _gameSession!.id!,
                    gameMap: _gameSession!.gameMap!,
                    userId: widget.userId,
                    teamId: widget.teamId,
                    hasBombOperationScenario: _hasBombOperationScenario,
                    participants: _participants,
                    fieldId:
                        _gameSession?.gameMap?.field?.id! ?? widget.fieldId,
                  ),
                const SizedBox(height: 16),
                // Tableau des scores (uniquement si un scénario de chasse au trésor est actif)
                _buildScoreboardSection(),
                // Carte des participants
                ParticipantsCard(
                  participants: _participants,
                  teamColors: _teamColors,
                ),

                // Espace pour les notifications de trésors trouvés
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Notifications de trésors trouvés
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                children: _treasureFoundNotifications.map((notification) {
                  final username = notification['username'] ?? l10n.playersTab; // Fallback
                  final teamName = notification['teamName'];
                  final points = notification['points'] ?? 0;
                  final symbol = notification['symbol'] ?? '🏆';

                  return Card(
                    color: Colors.green.shade100,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              symbol,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: username,
                                    style:
                                        const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (teamName != null) ...[
                                    TextSpan(text: l10n.treasureFoundNotification(username, teamName, points.toString(), symbol).split(username)[1].split(points.toString())[0]), // complex way to extract " de l'équipe "
                                    TextSpan(
                                      text: teamName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(text: l10n.treasureFoundNotification(username, teamName, points.toString(), symbol).split(teamName)[1].split(points.toString())[0]), // complex way to extract " a trouvé un trésor de "
                                  ] else ... [
                                     TextSpan(text: l10n.treasureFoundNotificationNoTeam(username, points.toString(), symbol).split(username)[1].split(points.toString())[0]),
                                  ],
                                  TextSpan(
                                    text: '$points $symbol',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const TextSpan(text: ' !'),
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
    _bombAutoManager?.dispose();
    _locationSub.cancel();

    super.dispose();
  }
}
