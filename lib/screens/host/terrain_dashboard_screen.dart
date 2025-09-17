import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:game_map_master_flutter_app/utils/app_utils.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/field.dart';
import '../../models/game_map.dart';
import '../../models/game_session.dart';
import '../../models/scenario/bomb_operation/bomb_operation_team.dart';
import '../../models/scenario/scenario_dto.dart';
import '../../services/api_service.dart';
import '../../services/audio/simple_voice_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_session_service.dart';
import '../../services/player_connection_service.dart';
import '../../services/scenario/bomb_operation/bomb_operation_service.dart';
import '../../services/team_service.dart';
import '../../services/websocket_service.dart';
import '../../services/game_state_service.dart';
import '../../widgets/bomb_operation_team_role_selector.dart';
import '../../widgets/button/favorite_star_button.dart';
import '../../widgets/dialog/duration_picker_dialog.dart';
import '../../widgets/zoomable_background_container.dart';
import '../gamesession/game_session_screen.dart';
import '../scenario/bomb_operation/bomb_operation_config.dart';
import 'scenario_selection_dialog.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

class TerrainDashboardScreen extends StatefulWidget {
  const TerrainDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TerrainDashboardScreen> createState() => _TerrainDashboardScreenState();
}

class _TerrainDashboardScreenState extends State<TerrainDashboardScreen> {
  late WebSocketService _webSocketService;
  late Locale flutterLocale;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    flutterLocale = Localizations.localeOf(context);
    _webSocketService = context.read<WebSocketService>();
    _webSocketService.addListener(_updateConnectedPlayers);
  }

  @override
  void dispose() {
    _webSocketService.removeListener(_updateConnectedPlayers);
    super.dispose();
  }

  void _updateConnectedPlayers() {
    final gameStateService = context.read<GameStateService>();
    final webSocketService = context.read<WebSocketService>();

    if (gameStateService.isTerrainOpen) {
      gameStateService
          .updateConnectedPlayers(gameStateService.connectedPlayers);
    }
  }

  void _selectScenarios() async {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.read<GameStateService>();

    if (!gameStateService.isTerrainOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectMapError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedScenarios = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) => ScenarioSelectionDialog(
        mapId: gameStateService.selectedMap!.id!,
      ),
    );

    if (selectedScenarios != null && selectedScenarios.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        gameStateService.setSelectedScenarios(selectedScenarios);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.scenariosSelectedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      });
    }
  }

  void _showDurationPicker() {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.read<GameStateService>();

    if (!gameStateService.isTerrainOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectMapError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => DurationPickerDialog(
        initialDuration: gameStateService.gameDuration,
        onDurationSelected: (duration) {
          gameStateService.setGameDuration(duration);

          final message = duration == null
              ? l10n.unlimitedDurationSet
              : l10n.durationSetToMinutes(duration.toString());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _startGame() async {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.read<GameStateService>();

    if (!gameStateService.isTerrainOpen) {
      _showError(l10n.selectMapError);
      return;
    }

    final selectedScenarios = gameStateService.selectedScenarios ?? [];
    if (selectedScenarios.isEmpty) {
      _showError(l10n.noScenarioInfoCard);
      return;
    }

    final hasBombScenario =
        selectedScenarios.any((s) => s.scenario.type == 'bomb_operation');

    try {
      if (hasBombScenario) {
        await _initBombOperationScenario();
      }
      // Audio de début de partie côté HOST
      await _playGameStartedAudioHost();

      _showLoadingDialog(l10n.loadingDialogMessage);
      try {
        logger.d(
            '🚀 [TerrainDashboardScreen] [_startGame] Début de création de la session de jeu');
        final gameSession = await _initGameSession();

        logger.d(
            '✅ [TerrainDashboardScreen] [_startGame] Session créée, lancement de l\'écran de jeu');
        await _launchGameScreen(gameSession);
        _showSuccess(l10n.gameStartedSuccess);
      } catch (e) {
        Navigator.of(context).pop();
        throw e;
      }
    } catch (e) {
      logger.e('❌ Erreur globale _startGame: $e');
      _showError(l10n.errorStartingGame(e.toString()));
    }
  }

  //Audio côté host
  Future<void> _playGameStartedAudioHost() async {
    try {
      final voiceService = GetIt.I<SimpleVoiceService>();
      await voiceService.initialize();
      await voiceService.playMessage('audioGameStarted');
      logger.d('🔊 Audio début de partie joué côté HOST');
    } catch (e) {
      logger.e('❌ Erreur audio début de partie HOST: $e');
    }
  }

  Future<void> _initBombOperationScenario() async {
    final l10n = AppLocalizations.of(context)!;
    final teamService = context.read<TeamService>();
    final bombOperationService = context.read<BombOperationService>();
    final gameStateService = context.read<GameStateService>();
    final scenarios = gameStateService.selectedScenarios!;

    final teams = teamService.teams;
    final activeTeams = teams.where((t) => t.players.isNotEmpty).toList();

    if (activeTeams.length != 2) {
      throw Exception(l10n.bombScenarioRequiresTwoTeamsError);
    }

    final bombScenario =
        scenarios.firstWhere((s) => s.scenario.type == 'bomb_operation');

    final Map<int, BombOperationTeam>? assignedRoles =
        await showDialog<Map<int, BombOperationTeam>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.bombConfigurationTitle),
        content: BombOperationTeamRoleSelector(
          teams: activeTeams,
          onRolesAssigned: (roles) => Navigator.of(context).pop(roles),
          gameSessionId: 0,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (assignedRoles == null) {
      throw Exception(l10n.bombConfigurationCancelled);
    }

    gameStateService.setBombOperationConfig(BombOperationScenarioConfig(
      roles: assignedRoles,
      scenarioId: bombScenario.scenario.id!,
    ));
  }

  Future<GameSession> _initGameSession() async {
    final gameStateService = context.read<GameStateService>();
    final gameSessionService = context.read<GameSessionService>();
    final bombOperationService = context.read<BombOperationService>();

    final gameMap = gameStateService.selectedMap!;
    final field = gameMap.field!;
    final duration = gameStateService.gameDuration ?? 0;

    final gameSession = await gameSessionService.createGameSession(
        gameMap.id!, field, duration);
    logger.d('✅ GameSession créée : ID = ${gameSession.id}');

    final bombConfig = gameStateService.bombOperationConfig;
    if (bombConfig != null) {
      await bombOperationService.saveTeamRoles(
          gameSession.id!, bombConfig.roles);
      final bombOperationSession =
          await bombOperationService.createBombOperationSession(
        gameSessionId: gameSession.id!,
        scenarioId: bombConfig.scenarioId,
      );
      await bombOperationService.initialize(bombOperationSession);
      logger.d('🎯 Scénario Bombe initialisé pour session ${gameSession.id}');
    }

    return gameSession;
  }

  Future<void> _launchGameScreen(GameSession session) async {
    final gameSessionService = context.read<GameSessionService>();
    final gameStateService = context.read<GameStateService>();
    final authService = context.read<AuthService>();
    final teamService = context.read<TeamService>();

    final startedSession =
        await gameSessionService.startGameSession(session.id!);
    logger.d(
        '✅ Partie démarrée : ID = ${startedSession.id}, active=${startedSession.active}');

    final user = authService.currentUser!;
    final teamId = teamService.myTeamId;
    final fieldId = session.field?.id!;

    gameStateService.setGameRunning(true);
    gameStateService.setActiveGameSession(startedSession);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameSessionScreen(
            userId: user.id!,
            teamId: teamId,
            isHost: user.hasRole('HOST'),
            gameSession: startedSession,
            fieldId: fieldId,
          ),
        ),
      );
    });
  }

  void _stopGame() {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = GetIt.I<GameStateService>();
    gameStateService.stopGameLocally();
    gameStateService.stopGameRemotely();

    final webSocketService = GetIt.I<WebSocketService>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.gameEndedMessage),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _selectMap() async {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.read<GameStateService>();
    final apiService = context.read<ApiService>();

    try {
      final response = await apiService.get('maps/owner/self');
      final List<dynamic> mapsJson = response;
      final maps = mapsJson.map((json) => GameMap.fromJson(json)).toList();

      if (maps.isEmpty) {
        _showError(l10n.noMapAvailable);
        return;
      }

      final selectedMap = await showDialog<GameMap>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.selectMap),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: maps.length,
              itemBuilder: (context, index) {
                final map = maps[index];
                return ListTile(
                  title: Text(map.name),
                  subtitle: Text(map.description ?? l10n.noDescription),
                  onTap: () => Navigator.of(context).pop(map),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );

      if (selectedMap != null) {
        gameStateService.selectMap(selectedMap);
        _showSuccess(l10n.mapSelectedSuccess(selectedMap.name));
      }
    } catch (e) {
      _showError(l10n.errorLoadingMaps(e.toString()));
    }
  }

  void _toggleTerrainOpen() async {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.read<GameStateService>();
    final apiService = context.read<ApiService>();
    final playerConnectionService = context.read<PlayerConnectionService>();
    GameMap? selectedMap = gameStateService.selectedMap;

    if (selectedMap == null) {
      logger.d('❌ ${l10n.selectMapError}');
      _showError(l10n.selectMapError);
      return;
    }

    try {
      Field? field = selectedMap.field;

      if (!gameStateService.isTerrainOpen) {
        if (field == null || field.closedAt != null) {
          logger.d('🛠 Création d\'un terrain via POST /fields...');
          final fieldResponse = await apiService.post('fields', {
            'name': l10n.fieldLabel(selectedMap.name),
            'description': selectedMap.description ?? '',
          });
          field = Field.fromJson(fieldResponse);
          logger.d('✅ Terrain créé avec ID: ${field.id}');

          final updatedMap = selectedMap.copyWith(field: field);
          final mapResponse = await apiService.put(
              'maps/${selectedMap.id}', updatedMap.toJson());
          selectedMap = GameMap.fromJson(mapResponse);
          gameStateService.selectMap(selectedMap);
        }

        final fieldId = field.id!;
        logger.d('📡 Requête POST /fields/$fieldId/open');
        final now = DateTime.now().toUtc();
        final response = await apiService.post('fields/$fieldId/open', {
          'openedAt': now.toUtc().toIso8601String(),
        });
        logger.d('✅ Terrain ouvert côté serveur : $response');
        gameStateService.setTerrainOpen(true);
        _showSuccess(l10n.fieldOpenedSuccess(field.name));

        try {
          await gameStateService.connectHostToField();
          final players =
              await playerConnectionService.getConnectedPlayers(fieldId);
          final playersList = players
              .map((player) => {
                    'id': player.user.id,
                    'username': player.user.username,
                    'teamId': player.team?.id,
                    'teamName': player.team?.name,
                  })
              .toList();

          for (var player in playersList) {
            gameStateService.addConnectedPlayer(player);
          }

          logger.d('✅ Joueurs connectés récupérés : ${playersList.length}');
        } catch (e) {
          logger.d(
              'ℹ️ Aucun joueur connecté pour le moment (ou erreur mineure) : $e');
        }

        _webSocketService.subscribeToField(fieldId);
      } else {
        final fieldId = field?.id;
        if (fieldId == null) {
          logger.d('❌ Impossible de fermer : aucun terrain associé à la carte');
          _showError(l10n.noAssociatedField);
          return;
        }

        logger.d('📡 Requête POST /fields/$fieldId/close');
        final now = DateTime.now().toUtc();
        final response = await apiService.post('fields/$fieldId/close', {
          'closedAt': now.toUtc().toIso8601String(),
        });
        logger.d('✅ Terrain fermé côté serveur : $response');
        gameStateService.setTerrainOpen(false);
        _showSuccess(l10n.fieldClosedSuccess);

        final updatedMap = selectedMap.copyWith(field: null);
        final mapResponse =
            await apiService.put('maps/${selectedMap.id}', updatedMap.toJson());
        logger.d('🧹 Terrain dissocié de la carte');

        gameStateService.selectMap(null);
      }
    } catch (e) {
      logger.d('❌ ${l10n.errorOpeningClosingField(e.toString())}');
      _showError(l10n.errorOpeningClosingField(e.toString()));
    }
  }

  void _toggleHostAsPlayer() async {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.read<GameStateService>();
    final authService = context.read<AuthService>();
    final playerConnectionService = context.read<PlayerConnectionService>();

    final user = authService.currentUser!;
    if (gameStateService.selectedMap == null ||
        gameStateService.selectedMap!.field == null) {
      _showError(l10n.selectMapError);
      return;
    }
    final fieldId = gameStateService.selectedMap!.field?.id;

    final isHostPlayer = gameStateService.isPlayerConnected(user.id!);

    try {
      if (!isHostPlayer) {
        await playerConnectionService.joinMap(fieldId!);
        gameStateService.addConnectedPlayer({
          'id': user.id,
          'username': user.username,
          'teamId': null,
          'teamName': null,
        });
      } else {
        await playerConnectionService.leaveFieldForHost(fieldId!);
        gameStateService.removeConnectedPlayer(user.id!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.error + e.toString())),
      );
    }
  }

  void _showLeaveConfirmationDialog() {
    final playerConnectionService = context.read<PlayerConnectionService>();
    final gameStateService = context.read<GameStateService>();
    final field = gameStateService.selectedMap?.field;
    final l10n = AppLocalizations.of(context)!;
    if (field == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveFieldButton),
        content: Text(l10n.leaveFieldConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              playerConnectionService.leaveField(field.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.leaveButton),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMapCard(GameStateService gameStateService) {
    final l10n = AppLocalizations.of(context)!;
    final selectedMap = gameStateService.selectedMap;

    if (selectedMap == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.map, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                l10n.mapCardTitle(
                  (selectedMap != null && selectedMap.name.isNotEmpty)
                      ? selectedMap.name
                      : '',
                ),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _selectMap,
                icon: const Icon(Icons.add),
                label: Text(l10n.selectMapButtonLabel),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedMap.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isMapOwner)
                  IconButton(
                    onPressed: _selectMap,
                    icon: const Icon(Icons.edit),
                    tooltip: l10n.selectMapButtonLabel,
                  ),
              ],
            ),
            if (selectedMap.description != null &&
                selectedMap.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                selectedMap.description!,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards(GameStateService gameStateService) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.people,
            title: l10n.playersTab,
            value: gameStateService.connectedPlayersList.length.toString(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.videogame_asset,
            title: l10n.scenariosLabel,
            value: gameStateService.selectedScenarios?.length.toString() ?? "0",
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.timer,
            title: l10n.duration,
            value: gameStateService.gameDuration == null
                ? l10n.unlimitedDurationInfoCard
                : "${gameStateService.gameDuration} ${l10n.min}",
            onTap: gameStateService.isTerrainOpen
                ? _showDurationPicker
                : null, // ✅ NOUVEAU
          ),
        ),
      ],
    );
  }

  Widget _buildFieldStatus(GameStateService gameStateService) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: gameStateService.isTerrainOpen
          ? Colors.green.shade100
          : Colors.red.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  gameStateService.isTerrainOpen
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: gameStateService.isTerrainOpen
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.sessionStatusLabel(gameStateService.isTerrainOpen
                        ? l10n.fieldStatusOpen
                        : l10n.fieldStatusClosed),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: _toggleTerrainOpen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gameStateService.isTerrainOpen
                        ? Colors.red
                        : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(gameStateService.isTerrainOpen
                      ? l10n.closeField
                      : l10n.openField),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldStatusOnlyView(GameStateService gameStateService) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: gameStateService.isTerrainOpen
          ? Colors.green.shade100
          : Colors.red.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  gameStateService.isTerrainOpen
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: gameStateService.isTerrainOpen
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.sessionStatusLabel(gameStateService.isTerrainOpen
                        ? l10n.fieldStatusOpen
                        : l10n.fieldStatusClosed),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: _showLeaveConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.leaveFieldButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameConfiguration(GameStateService gameStateService) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.gameConfigurationTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    gameStateService.isTerrainOpen ? _selectScenarios : null,
                icon: const Icon(Icons.videogame_asset),
                label: Text(l10n.selectScenariosButtonLabel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    gameStateService.isTerrainOpen ? _showDurationPicker : null,
                icon: const Icon(Icons.timer),
                label: Text(l10n.setDurationButtonLabel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.person_add),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.participateAsPlayerLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Switch(
              value: gameStateService.isPlayerConnected(
                  context.read<AuthService>().currentUser!.id!),
              onChanged: gameStateService.isTerrainOpen
                  ? (value) => _toggleHostAsPlayer()
                  : null,
              activeColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 24),
        gameStateService.isGameRunning
            ? Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final user = context.read<AuthService>().currentUser!;
                        final teamId = context.read<TeamService>().myTeamId;
                        final field = gameStateService.selectedMap!.field;
                        final isHost = user.hasRole('HOST') &&
                            field!.owner!.id! == user.id;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameSessionScreen(
                              gameSession: gameStateService.activeGameSession!,
                              userId: user.id!,
                              teamId: teamId,
                              isHost: isHost,
                              fieldId: field?.id!,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: Text(l10n.joinButton),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stopGame,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(l10n.stopGame),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              )
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: gameStateService.isTerrainOpen &&
                          (gameStateService.selectedScenarios?.isNotEmpty ??
                              false)
                      ? _startGame
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.startGame),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildGameConfigurationOnlyView(GameStateService gameStateService) {
    final l10n = AppLocalizations.of(context)!;

    if (!gameStateService.isGameRunning) {
      return const SizedBox();
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final user = context.read<AuthService>().currentUser!;
                  final teamId = context.read<TeamService>().myTeamId;
                  final field = gameStateService.selectedMap!.field;
                  final isHost =
                      user.hasRole('HOST') && field!.owner!.id! == user.id;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameSessionScreen(
                        gameSession: gameStateService.activeGameSession!,
                        userId: user.id!,
                        teamId: teamId,
                        isHost: isHost,
                        fieldId: field?.id!,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.login),
                label: Text(l10n.joinButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectedPlayersList(
      GameStateService gameStateService, AuthService authService) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🆕 "Participer en tant que joueur" AU-DESSUS de la liste
        if (gameStateService.selectedMap != null &&
            gameStateService.isTerrainOpen &&
            isMapOwner) ...[
          Row(
            children: [
              const Icon(Icons.person_add),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.participateAsPlayerLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Switch(
                value: gameStateService
                    .isPlayerConnected(authService.currentUser!.id!),
                onChanged: (value) => _toggleHostAsPlayer(),
                activeColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        Text(
          l10n.connectedPlayers,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        gameStateService.connectedPlayersList.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gameStateService.connectedPlayersList.length,
                itemBuilder: (context, index) {
                  final player = gameStateService.connectedPlayersList[index];
                  final isHost = player['id'] == authService.currentUser!.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isHost
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade400,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      player['username'] ?? l10n.playersTab,
                      style: TextStyle(
                        fontWeight:
                            isHost ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      player['teamName'] != null
                          ? l10n.teamLabelPlayerList(player['teamName'])
                          : l10n.noTeam,
                    ),
                    trailing: isHost
                        ? Text(l10n.youHostLabel)
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FavoriteStarButton(
                                playerId: player['id'],
                                playerName: player['username'] ?? 'Joueur',
                                size: 20.0,
                              ),
                            ],
                          ),
                  );
                },
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l10n.noPlayerConnected,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Icon(icon),
              Text(title, style: const TextStyle(fontSize: 12)),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedScenarios(GameStateService gameStateService) {
    final l10n = AppLocalizations.of(context)!;
    final scenarios = gameStateService.selectedScenarios ?? [];

    if (scenarios.isEmpty) {
      return const SizedBox();
    }

    final bigScenarios =
        scenarios.where((s) => s.treasureHuntScenario?.size == 'BIG').toList();
    final smallScenarios =
        scenarios.where((s) => s.treasureHuntScenario?.size != 'BIG').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectedScenariosLabel,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (bigScenarios.isNotEmpty) ...[
          _buildScenarioCard(bigScenarios.first, isBig: true),
        ],
        const SizedBox(height: 4),
        ...smallScenarios
            .map((scenario) => _buildScenarioCard(scenario))
            .toList(),
      ],
    );
  }

  Widget _buildScenarioCard(ScenarioDTO scenarioDTO, {bool isBig = false}) {
    final l10n = AppLocalizations.of(context)!;
    final name = scenarioDTO.scenario.name;
    final description = scenarioDTO.scenario.description;
    final treasureHuntData = scenarioDTO.treasureHuntScenario;

    String subtitle = '';
    if (treasureHuntData != null) {
      final totalTreasures = treasureHuntData.totalTreasures;
      final symbol = treasureHuntData.defaultSymbol;
      subtitle =
          l10n.treasureHuntScenarioDetails(totalTreasures.toString(), symbol);
    } else if (description != null && description.isNotEmpty) {
      subtitle = description;
    } else {
      subtitle = l10n.noDescription;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isBig
            ? Colors.amber.withOpacity(0.2)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isBig ? 14 : 12,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: isBig ? 12 : 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showLoadingDialog(String message) async {
    final currentContext = context;
    return showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  bool get isMapOwner {
    final authService = context.read<AuthService>();
    final gameStateService = context.read<GameStateService>();

    final currentUser = authService.currentUser;
    final selectedMap = gameStateService.selectedMap;

    logger.d('🔎 Vérification isMapOwner...');
    logger.d(
        '👤 Utilisateur courant : ${currentUser?.id} (${currentUser?.username})');
    logger.d(
        '🗺️ Carte sélectionnée : ${selectedMap?.id} (${selectedMap?.name})');
    logger.d('👤 Owner de la carte : ${selectedMap?.owner?.id}');

    if (currentUser == null) {
      logger.d('❗ currentUser est nul → isMapOwner=false');
      return false;
    }

    if (selectedMap == null) {
      logger.d('❗ selectedMap est nul → isMapOwner=false');
      return true;
    }

    if (selectedMap.owner == null) {
      logger.d('❗ selectedMap.owner est nul → isMapOwner=false');
      return false;
    }

    final isOwner = currentUser.id == selectedMap.owner!.id;
    logger.d(
        '✅ Résultat comparaison : currentUser.id (${currentUser.id}) == selectedMap.owner.id (${selectedMap.owner!.id}) → $isOwner');

    return isOwner;
  }

  Widget _buildUnifiedTerrainCard(GameStateService gameStateService) {
    final l10n = AppLocalizations.of(context)!;
    final selectedMap = gameStateService.selectedMap;

    if (selectedMap == null) {
      return _buildSelectedMapCard(gameStateService);
    }

    // ✅ CHOIX DE L'IMAGE SELON L'ÉTAT DU TERRAIN
    String backgroundImagePath = gameStateService.isTerrainOpen
        ? 'assets/images/theme/terrain_open_background.png' // Image terrain ouvert
        : 'assets/images/theme/terrain_closed_background.png'; // Image terrain fermé
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ZoomableBackgroundContainer(
        imageAssetPath: backgroundImagePath,
        zoom: 2.5,
        // ajuste comme tu veux
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gameStateService.isTerrainOpen
              ? const Color(0xFF6B8E23).withOpacity(0.6) // Kaki métallisé
              : const Color(0xFF8B0000).withOpacity(0.6),
          // Rouge foncé/gris métallisé
          width: 2,
        ),
        gradientColors: [
          Colors.black.withOpacity(0.3),
          Colors.black.withOpacity(0.5),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status et bouton
            Row(
              children: [
                Icon(
                  gameStateService.isTerrainOpen
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: gameStateService.isTerrainOpen
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.sessionStatusLabel(gameStateService.isTerrainOpen
                        ? l10n.fieldStatusOpen
                        : l10n.fieldStatusClosed),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                isMapOwner
                    ? ElevatedButton(
                        onPressed: _toggleTerrainOpen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gameStateService.isTerrainOpen
                              ? Colors.red
                              : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(gameStateService.isTerrainOpen
                            ? l10n.closeField
                            : l10n.openField),
                      )
                    : ElevatedButton(
                        onPressed: _showLeaveConfirmationDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(l10n.leaveFieldButton),
                      ),
              ],
            ),

            const SizedBox(height: 16),

            // Informations de la carte
            Row(
              children: [
                const Icon(Icons.map, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedMap.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isMapOwner && !gameStateService.isTerrainOpen)
                  IconButton(
                    onPressed: _selectMap,
                    icon: const Icon(Icons.edit, color: Colors.white),
                    tooltip: l10n.selectMapButtonLabel,
                  ),
              ],
            ),

            if (selectedMap.description != null &&
                selectedMap.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                selectedMap.description!,
                style: const TextStyle(color: Colors.grey),
              ),
            ],

            const SizedBox(height: 16),

            // Info cards intégrées
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.people,
                    title: l10n.playersTab,
                    value:
                        gameStateService.connectedPlayersList.length.toString(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.videogame_asset,
                    title: l10n.scenariosLabel,
                    value:
                        gameStateService.selectedScenarios?.length.toString() ??
                            "0",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.timer,
                    title: l10n.duration,
                    value: gameStateService.gameDuration == null
                        ? "∞"
                        : "${gameStateService.gameDuration} ${l10n.min}",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // BOUTONS DE JEU (AVANT LES BOUTONS DE CONFIGURATION)
            if (gameStateService.isTerrainOpen) ...[
              if (gameStateService.isGameRunning)
                // BOUTONS PENDANT LA PARTIE
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final user = context.read<AuthService>().currentUser!;
                          final teamId = context.read<TeamService>().myTeamId;
                          final field = gameStateService.selectedMap!.field;
                          final isHost = user.hasRole('HOST') &&
                              field!.owner!.id! == user.id;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GameSessionScreen(
                                gameSession:
                                    gameStateService.activeGameSession!,
                                userId: user.id!,
                                teamId: teamId,
                                isHost: isHost,
                                fieldId: field?.id!,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.login),
                        label: Text(l10n.joinButton),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.withOpacity(0.9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    if (isMapOwner) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _stopGame,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: Text(l10n.stopGame),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              else
                // BOUTON START GAME
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: gameStateService.isTerrainOpen &&
                            (gameStateService.selectedScenarios?.isNotEmpty ??
                                false)
                        ? _startGame
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.startGame),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],

            // BOUTONS DE CONFIGURATION (GRISÉS SI PARTIE EN COURS)
            if (gameStateService.isTerrainOpen && isMapOwner) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: gameStateService.isGameRunning
                          ? null
                          : _selectScenarios,
                      icon: const Icon(Icons.videogame_asset),
                      label: Text(l10n.selectScenariosButtonLabel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gameStateService.isGameRunning
                            ? Colors.grey.shade600.withOpacity(0.7)
                            : Colors.blue.shade700.withOpacity(0.9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size.fromHeight(56),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: gameStateService.isGameRunning
                          ? null
                          : _showDurationPicker,
                      icon: const Icon(Icons.timer),
                      label: Text(l10n.setDurationButtonLabel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gameStateService.isGameRunning
                            ? Colors.grey.shade600.withOpacity(0.7)
                            : Colors.orange.shade700.withOpacity(0.9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size.fromHeight(56),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (gameStateService.selectedScenarios != null &&
                gameStateService.selectedScenarios!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSelectedScenarios(gameStateService),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.watch<GameStateService>();
    final authService = context.watch<AuthService>();

    return Scaffold(
      // Rendre le fond transparent pour voir l’arrière‑plan du HostDashboard
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ENCADRÉ PRINCIPAL UNIFIÉ (sans boutons de jeu)
            _buildUnifiedTerrainCard(gameStateService),

            // GESTION DES JOUEURS (avec "Participer" au-dessus)
            if (gameStateService.selectedMap != null)
              _buildConnectedPlayersList(gameStateService, authService),
          ],
        ),
      ),
    );
  }
}
