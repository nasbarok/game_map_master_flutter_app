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
import '../../services/auth_service.dart';
import '../../services/game_session_service.dart';
import '../../services/player_connection_service.dart';
import '../../services/scenario/bomb_operation/bomb_operation_service.dart';
import '../../services/team_service.dart';
import '../../services/websocket_service.dart';
import '../../services/game_state_service.dart';
import '../../widgets/bomb_operation_team_role_selector.dart';
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
    // Initialisation sûre ici
    _webSocketService = context.read<WebSocketService>();
    _webSocketService.addListener(_updateConnectedPlayers);
  }

  @override
  void dispose() {
    _webSocketService.removeListener(_updateConnectedPlayers);
    super.dispose();
  }

  void _updateConnectedPlayers() {
    // Cette méthode sera appelée quand le WebSocketService notifie ses listeners
    final gameStateService = context.read<GameStateService>();
    final webSocketService = context.read<WebSocketService>();

    // Pour l'instant, simulons un nombre aléatoire de joueurs connectés
    if (gameStateService.isTerrainOpen) {
      // Dans une implémentation réelle, vous récupéreriez le nombre de joueurs connectés
      // gameStateService.updateConnectedPlayers(webSocketService.connectedPlayers.length);

      // Simulation pour le développement
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

  void _setGameDuration() {
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
    // Utiliser le sélecteur de type "roue" pour les heures et minutes
    DatePicker.showTimePicker(
      context,
      showSecondsColumn: false,
      onChanged: (time) {
        // Mise à jour en temps réel pendant que l'utilisateur fait défiler
      },
      onConfirm: (time) {
        // Calculer la durée en minutes
        int minutes = time.hour * 60 + time.minute;
        gameStateService.setGameDuration(minutes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.durationSetSuccess(
                time.hour.toString(), time.minute.toString())),
            backgroundColor: Colors.green,
          ),
        );
      },
      currentTime: DateTime(2022, 1, 1, 0, 0),
      // Commencer à 00:00
      locale: AppUtils.getDatePickerLocale(flutterLocale),
    );
  }

  void _startGame() async {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.read<GameStateService>();

    // Vérif : terrain ouvert ?
    if (!gameStateService.isTerrainOpen) {
      _showError(l10n.selectMapError);
      return;
    }

    // Vérif : scénarios ?
    final selectedScenarios = gameStateService.selectedScenarios ?? [];
    if (selectedScenarios.isEmpty) {
      _showError(l10n
          .noScenarioSelected); // Assuming noScenarioSelected exists or create it
      return;
    }

    // Vérif : scénario bombe ?
    final hasBombScenario =
        selectedScenarios.any((s) => s.scenario.type == 'bomb_operation');

    try {
      if (hasBombScenario) {
        await _initBombOperationScenario();
      }
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

  Future<void> _initBombOperationScenario() async {
    final l10n = AppLocalizations.of(context)!;
    final teamService = context.read<TeamService>();
    final bombOperationService = context.read<BombOperationService>();
    final gameStateService = context.read<GameStateService>();
    final scenarios = gameStateService.selectedScenarios!;
    final teams = teamService.teams;

    final activeTeams = teams.where((t) => t.players.isNotEmpty).toList();
    final bombScenario =
        scenarios.firstWhere((s) => s.scenario.type == 'bomb_operation');

    if (activeTeams.length != 2) {
      throw Exception(l10n.bombScenarioRequiresTwoTeamsError);
    }

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

    if (assignedRoles == null) throw Exception(l10n.bombConfigurationCancelled);

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
        // Assuming gameEndedMessage is appropriate
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _selectMap() async {
    final l10n = AppLocalizations.of(context)!;
    final apiService = context.read<ApiService>();
    final gameStateService = context.read<GameStateService>();

    try {
      final List<dynamic> mapData = await apiService.get('maps/owner/self');
      final List<GameMap> maps =
          mapData.map((json) => GameMap.fromJson(json)).toList();

      if (maps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noMapAvailable),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      GameMap? tempSelectedMap = maps.first;

      showDialog<GameMap>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(l10n.selectMap),
                content: DropdownButton<GameMap>(
                  isExpanded: true,
                  value: tempSelectedMap,
                  onChanged: (GameMap? newMap) {
                    setState(() {
                      tempSelectedMap = newMap;
                    });
                  },
                  items: maps.map((map) {
                    return DropdownMenuItem<GameMap>(
                      value: map,
                      child: Text(map.name),
                    );
                  }).toList(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(tempSelectedMap);
                    },
                    child: Text(l10n.validateButton),
                  ),
                ],
              );
            },
          );
        },
      ).then((selectedMap) {
        if (selectedMap != null) {
          gameStateService.selectMap(selectedMap);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.mapSelectedSuccess(selectedMap.name)),
              backgroundColor: Colors.blue,
            ),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorLoadingMaps(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleTerrainOpen() async {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.read<GameStateService>();
    final apiService = context.read<ApiService>();
    final playerConnectionService = context.read<PlayerConnectionService>();
    GameMap? selectedMap = gameStateService.selectedMap; // Make nullable

    if (selectedMap == null) {
      logger.d(
          '❌ ${l10n.selectMapError}'); // Use a general "select map first" message
      _showError(l10n.selectMapError);
      return;
    }

    try {
      Field? field = selectedMap.field;

      // 🔁 Si on ouvre le terrain
      if (!gameStateService.isTerrainOpen) {
        // 🧠 S’il n’y a pas encore de terrain, on en crée un
        if (field == null || field.closedAt != null) {
          logger.d('🛠 Création d’un terrain via POST /fields...');
          final fieldResponse = await apiService.post('fields', {
            'name': l10n.fieldLabel(selectedMap.name),
            // Example of using a localized string for field name
            'description': selectedMap.description ?? '',
          });
          field = Field.fromJson(fieldResponse);
          logger.d('✅ Terrain créé avec ID: ${field.id}');

          // 🔁 Mise à jour de la GameMap pour lier le terrain
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
          'openedAt': now.toIso8601String(),
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
        // 🔒 Fermeture du terrain
        final fieldId = field?.id;
        if (fieldId == null) {
          logger.d('❌ Impossible de fermer : aucun terrain associé à la carte');
          _showError(l10n.noAssociatedField);
          return;
        }

        logger.d('📡 Requête POST /fields/$fieldId/close');
        final now = DateTime.now().toUtc();
        final response = await apiService.post('fields/$fieldId/close', {
          'closedAt': now.toIso8601String(),
        });
        logger.d('✅ Terrain fermé côté serveur : $response');
        gameStateService.setTerrainOpen(false);
        _showSuccess(l10n.fieldClosedSuccess);

        // 🔄 Dissocier le terrain de la carte
        final updatedMap = selectedMap.copyWith(field: null);
        final mapResponse =
            await apiService.put('maps/${selectedMap.id}', updatedMap.toJson());
        logger.d('🧹 Terrain dissocié de la carte');

        // 🧼 Réinitialisation de la carte sélectionnée
        gameStateService.selectMap(null);
      }
    } catch (e) {
      logger.d('❌ ${l10n.errorOpeningClosingField(e.toString())}');
      _showError(l10n.errorOpeningClosingField(e.toString()));
    }
  }

  // méthode pour gérer l'hôte comme joueur
  void _toggleHostAsPlayer() async {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.read<GameStateService>();
    final authService = context.read<AuthService>();
    final playerConnectionService = context.read<PlayerConnectionService>();

    final user = authService.currentUser!;
    // Ensure selectedMap is not null before accessing its properties
    if (gameStateService.selectedMap == null ||
        gameStateService.selectedMap!.field == null) {
      _showError(l10n.selectMapError); // Or a more specific error
      return;
    }
    final fieldId = gameStateService.selectedMap!.field?.id;

    // Vérifier si l'hôte est déjà dans la liste des joueurs
    final isHostPlayer = gameStateService.isPlayerConnected(user.id!);

    try {
      if (!isHostPlayer) {
        // Ajouter l'hôte comme joueur
        await playerConnectionService.joinMap(fieldId!);

        // Ajouter manuellement l'hôte à la liste des joueurs
        gameStateService.addConnectedPlayer({
          'id': user.id,
          'username': user.username,
          'teamId': null,
          'teamName': null,
        });
      } else {
        // Retirer l'hôte de la liste des joueurs
        await playerConnectionService.leaveFieldForHost(fieldId!);

        // Retirer manuellement l'hôte de la liste des joueurs
        gameStateService.removeConnectedPlayer(user.id!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.error + e.toString())),
      );
    }
  }

  Widget _buildSelectedMapCard(GameStateService gameStateService) {
    final l10n = AppLocalizations.of(context)!;
    final selectedMap = gameStateService.selectedMap;
    if (selectedMap == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mapCardTitle(selectedMap.name),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (selectedMap.description != null &&
              selectedMap.description!.isNotEmpty)
            Text(
              selectedMap.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (selectedMap.sourceAddress != null &&
              selectedMap.sourceAddress!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: Colors.grey[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedMap.sourceAddress!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(GameStateService gameStateService) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceAround,
      children: [
        _buildInfoCard(
          icon: Icons.people,
          title: l10n.playersTab,
          value: '${gameStateService.connectedPlayersList.length}',
        ),
        _buildInfoCard(
          icon: Icons.videogame_asset,
          title: l10n.scenariosLabel,
          value: gameStateService.selectedScenarios?.isEmpty ?? true
              ? l10n.noScenarioInfoCard
              : '${gameStateService.selectedScenarios!.length}',
        ),
        _buildInfoCard(
          icon: Icons.timer,
          title: l10n.duration,
          value: gameStateService.gameDuration == null
              ? l10n.unlimitedDurationInfoCard
              : '${gameStateService.gameDuration} min',
        ),
      ],
    );
  }

  Widget _buildFieldStatus(GameStateService gameStateService) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gameStateService.isTerrainOpen
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.sessionStatusLabel(gameStateService.isTerrainOpen
                ? l10n.fieldStatusOpen
                : l10n.fieldStatusClosed),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: gameStateService.isTerrainOpen ? Colors.green : Colors.red,
            ),
          ),
          if (gameStateService.selectedMap != null)
            ElevatedButton.icon(
              onPressed: _toggleTerrainOpen,
              icon: Icon(gameStateService.isTerrainOpen
                  ? Icons.close
                  : Icons.door_front_door),
              label: Text(gameStateService.isTerrainOpen
                  ? l10n.closeField
                  : l10n.openField),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    gameStateService.isTerrainOpen ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
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
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Ferme le dialog
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

  Widget _buildFieldStatusOnlyView(GameStateService gameStateService) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gameStateService.isTerrainOpen
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              l10n.sessionStatusLabel(
                gameStateService.isTerrainOpen
                    ? l10n.fieldStatusOpen
                    : l10n.fieldStatusClosed,
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    gameStateService.isTerrainOpen ? Colors.green : Colors.red,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showLeaveConfirmationDialog,
            icon: const Icon(Icons.logout),
            label: Text(l10n.leaveFieldButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameConfiguration(GameStateService gameStateService) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          l10n.gameConfigurationTitle,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: gameStateService.isTerrainOpen ? null : _selectMap,
          icon: const Icon(Icons.map),
          label: Text(
            gameStateService.selectedMap != null
                ? l10n.mapLabel(gameStateService.selectedMap!.name)
                : l10n.selectMapButtonLabel,
          ),
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
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    gameStateService.isTerrainOpen ? _setGameDuration : null,
                icon: const Icon(Icons.timer),
                label: Text(l10n.setDurationButtonLabel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (gameStateService.selectedMap != null)
          Row(
            children: [
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
      return const SizedBox(); // Pas de partie en cours, on n'affiche rien
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
                      player['username'] ?? l10n.playersTab, // Fallback
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
                    trailing: isHost ? Text(l10n.youHostLabel) : null,
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
  }) {
    return Card(
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
    );
  }

  Widget _buildSelectedScenarios(GameStateService gameStateService) {
    final l10n = AppLocalizations.of(context)!;
    final scenarios = gameStateService.selectedScenarios ?? [];

    if (scenarios.isEmpty) {
      return const SizedBox(); // Aucun scénario sélectionné
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
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (bigScenarios.isNotEmpty) ...[
          _buildScenarioCard(bigScenarios.first, isBig: true),
        ],
        const SizedBox(height: 8),
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

    return Card(
      color: isBig ? Colors.amber.shade100 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isBig ? 20 : 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: isBig ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog(String message) async {
    final currentContext = context; // Capture context before async gap
    final l10n = AppLocalizations.of(currentContext)!; // Use captured context
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
                Text(message), // Use the passed message directly
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.watch<GameStateService>();
    final authService = context.watch<AuthService>();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSelectedMapCard(gameStateService),
            const SizedBox(height: 16),
            _buildInfoCards(gameStateService),
            const SizedBox(height: 16),
            _buildSelectedScenarios(gameStateService),
            const SizedBox(height: 16),
            isMapOwner
                ? _buildFieldStatus(gameStateService)
                : _buildFieldStatusOnlyView(gameStateService),
            const SizedBox(height: 16),
            isMapOwner
                ? _buildGameConfiguration(gameStateService)
                : _buildGameConfigurationOnlyView(gameStateService),
            const SizedBox(height: 32),
            _buildConnectedPlayersList(gameStateService, authService),
          ],
        ),
      ),
    );
  }
}
