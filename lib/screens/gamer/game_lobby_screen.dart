import 'package:game_map_master_flutter_app/screens/gamer/team_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/field.dart';
import '../../models/websocket/player_left_message.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../../services/player_connection_service.dart';
import '../../services/team_service.dart';
import '../../services/websocket_service.dart';
import '../../services/invitation_service.dart';
import 'package:go_router/go_router.dart';
import '../../models/team.dart';
import '../../widgets/gamer_history_button.dart';
import '../../widgets/options/user_options_menu.dart';
import '../../widgets/options/cropped_logo_button.dart';
import '../gamesession/game_session_screen.dart';
import '../history/field_sessions_screen.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

class GameLobbyScreen extends StatefulWidget {
  const GameLobbyScreen({Key? key}) : super(key: key);

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GameStateService _gameStateService;
  late WebSocketService _webSocketService;

  @override
  void initState() {
    super.initState();

    // Initialiser avec un seul onglet par défaut
    _tabController = TabController(length: 2, vsync: this);

    _gameStateService = Provider.of<GameStateService>(context, listen: false);
    _webSocketService = Provider.of<WebSocketService>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final teamService = Provider.of<TeamService>(context, listen: false);

      _webSocketService.connect();

      final mapId = _gameStateService.selectedMap?.id;
      final fieldId = _gameStateService.selectedMap?.field?.id;

      if (fieldId != null) {
        logger.d('📡 Abonnement au topic du terrain depuis GameLobbyScreen');
        _webSocketService.subscribeToField(fieldId);
        if (mapId != null) {
          _gameStateService.loadConnectedPlayers();
          teamService.loadTeams(mapId);
        }
      } else {
        logger.d('❌ Pas de terrain ouvert en cours');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameState = context.read<GameStateService>();

    final selectedMap = gameState.selectedMap;
    final terrainOuvert = gameState.isTerrainOpen;

    logger.d('🧭 [GameLobbyScreen] build() déclenché');
    logger.d('🔍 Carte sélectionnée : ${selectedMap?.name ?? "Aucune"}');
    logger.d('🔓 Terrain ouvert : $terrainOuvert');

    final bool isConnectedToField = gameState.isTerrainOpen;

    // ✅ Rendu normal
    logger.d('✅ Affichage de l’interface GameLobbyScreen');

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CroppedLogoButtonAnimated(
            size: 35.0,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserOptionsMenu()),
              );
            },
          ),
        ),
        title: Text(l10n.mapLabel(selectedMap?.name ?? l10n.unknownMap)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = context.read<AuthService>();
              await authService.leaveAndLogout(context);
              if (mounted) {
                context.go('/login');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.map), text: l10n.terrainTab),
            Tab(icon: const Icon(Icons.people), text: l10n.playersTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Terrain
          _buildTerrainTab(),
          // Onglet Joueurs
          _buildPlayersTab(),
        ],
      ),
    );
  }

  Widget _buildTerrainTab() {
    final l10n = AppLocalizations.of(context)!;
    final gameState = context.watch<GameStateService>();

    if (!gameState.isTerrainOpen || gameState.selectedMap == null) {
      // Afficher la liste des anciens terrains
      return _buildPreviousFieldsList();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.mapLabel(
                              gameState.selectedMap?.name ?? l10n.unknownMap),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          tooltip: l10n.sessionsHistoryTooltip,
                          icon: const Icon(Icons.history),
                          onPressed: () {
                            final fieldId = gameState.selectedMap?.field?.id;
                            if (fieldId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FieldSessionsScreen(fieldId: fieldId),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.noAssociatedField)),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSelectedScenarios(),
                    const SizedBox(height: 24),
                    if (gameState.isGameRunning)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              l10n.remainingTimeLabel(
                                  gameState.timeLeftDisplay),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (gameState.isGameRunning)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.gameInProgressTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.gameInProgressInstructions,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToGameSession(context),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(l10n.joinGameButton),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.waitingForGameStartTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.waitingForGameStartInstructions,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24), // ou ajustable
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _showLeaveConfirmationDialog(gameState.selectedMap!.field!);
                },
                icon: const Icon(Icons.logout),
                label: Text(l10n.leaveFieldButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedScenarios() {
    final l10n = AppLocalizations.of(context)!;
    final gameState = context.read<GameStateService>();

    final scenarios = gameState.selectedScenarios ?? [];

    if (scenarios.isEmpty) {
      return Text(
        l10n.noScenarioSelected,
        style: const TextStyle(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectedScenariosLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...scenarios.map((scenario) {
          final String name = scenario.scenario.name;
          final treasure = scenario.treasureHuntScenario;
          final String description = treasure != null
              ? l10n.treasureHuntScenarioDetails(
                  treasure.totalTreasures.toString(), treasure.defaultSymbol)
              : (scenario.scenario.description ?? l10n.noDescription);

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.flag),
              title: Text(name),
              subtitle: Text(description),
            ),
          );
        }).toList(),
      ],
    );
  }

  // Méthode pour afficher la liste des anciens terrains
  Widget _buildPreviousFieldsList() {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Field>>(
      future: _loadPreviousFields(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(l10n.loadingError(snapshot.error.toString())),
          );
        }

        final fields = snapshot.data ?? [];

        if (fields.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 80, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  l10n.noFieldsVisited,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.waitForInvitation,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: fields.length,
          itemBuilder: (context, index) {
            final field = fields[index];
            final isOpen = field.active;

            String openedAtStr = field.openedAt != null
                ? l10n.fieldOpenedOn(_formatDate(field.openedAt!))
                : l10n.unknownOpeningDate;

            String closedAtStr = field.closedAt != null
                ? l10n.fieldClosedOn(_formatDate(field.closedAt!))
                : l10n.stillActive;

            String ownerName = field.owner?.username != null
                ? l10n.ownerLabel(field.owner!.username!)
                : l10n.unknownOwner;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isOpen ? Colors.green : Colors.grey,
                      child: const Icon(Icons.map, color: Colors.white),
                    ),
                    title: Text(field.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isOpen
                            ? l10n.fieldStatusOpen
                            : l10n.fieldStatusClosed),
                        Text(openedAtStr),
                        Text(closedAtStr),
                        Text(ownerName),
                      ],
                    ),
                    trailing: Wrap(
                      direction: Axis.vertical,
                      spacing: 4,
                      children: [
                        if (isOpen)
                          ElevatedButton(
                            onPressed: () => _joinField(field.id!),
                            child: Text(l10n.joinButton),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: l10n.deleteFromHistoryTooltip,
                          onPressed: () => _deleteHistoryEntry(field),
                        ),
                      ],
                    ),
                  ),
                  // 👇 Bouton Historique spécifique
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GamerHistoryButton(fieldId: field.id!),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Méthode pour charger les anciens terrains
  Future<List<Field>> _loadPreviousFields() async {
    try {
      final apiService = GetIt.I<ApiService>();
      final response = await apiService.get('fields-history/history');

      if (response == null || !(response is List)) {
        return [];
      }

      final fields =
          (response as List).map((data) => Field.fromJson(data)).toList();
      // 🔥 NOUVEAU : pour chaque terrain actif, tenter de s'abonner
      for (final field in fields) {
        if (field.active == true && field.id != null) {
          logger.d(
              '📡 Tentative d\'abonnement WebSocket au terrain ${field.name} (ID: ${field.id})');
          _webSocketService.subscribeToField(field.id!);
        }
      }

      return fields;
    } catch (e) {
      logger.d('❌ Erreur lors du chargement des terrains: $e');
      return [];
    }
  }

  // Méthode pour rejoindre un terrain
  Future<void> _joinField(int fieldId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final apiService = GetIt.I<ApiService>();
      final authService = GetIt.I<AuthService>();
      final gameStateService = GetIt.I<GameStateService>();

      if (authService.currentUser == null) {
        return;
      }

      final userId = authService.currentUser!.id;

      // Appeler l'API pour rejoindre le terrain
      final response = await apiService.post('fields/$fieldId/join', {
        'userId': userId,
      });

      if (response != null) {
        // Mettre à jour l'état du jeu
        await gameStateService.restoreSessionIfNeeded(apiService, fieldId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.youJoinedFieldSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger.d('❌ Erreur lors de la connexion au terrain: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.loadingError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _leaveField() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final gameStateService = GetIt.I<GameStateService>();
      final authService = GetIt.I<AuthService>();
      final webSocketService = GetIt.I<WebSocketService>();

      if (gameStateService.selectedMap == null ||
          authService.currentUser == null) {
        return;
      }

      final fieldId = gameStateService.selectedMap!.field!.id;
      final userId = authService.currentUser!.id;

      // Envoyer un message WebSocket pour quitter le terrain
      final message = PlayerLeftMessage(
        senderId: userId!,
        fieldId: fieldId!,
      );
      await webSocketService.sendMessage('/app/leave-field', message);
      // Réinitialiser l'état du jeu
      gameStateService.reset();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.youLeftField),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      logger.d('❌ Erreur lors de la déconnexion du terrain: $e');
    }
  }

  Widget _buildPlayersTab() {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.read<GameStateService>();
    final teamService = context.watch<TeamService>();
    final authService = context.read<AuthService>();
    final connectedPlayers = gameStateService.connectedPlayersList;
    final teams = teamService.teams;
    final currentUserId = authService.currentUser?.id;

    if (!gameStateService.isTerrainOpen) {
      return Center(
        child: Text(l10n.notConnectedToField),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTeamInfo(),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.connectedPlayersCount(
                      connectedPlayers.length.toString()),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (connectedPlayers.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        l10n.noPlayerConnected,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: connectedPlayers.length,
                    itemBuilder: (context, index) {
                      final player = connectedPlayers[index];
                      final isCurrentUser = player['id'] == currentUserId;

                      // ✅ Calcul dynamique du nom d'équipe
                      String teamName = l10n.noTeam;
                      Color teamColor = Colors.grey;

                      final teamId = player['teamId'];
                      final team = teams.where((t) => t.id == teamId).toList();
                      if (team.isNotEmpty) {
                        teamName = team.first.name;
                        teamColor = Colors.blue;
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isCurrentUser ? Colors.amber : teamColor,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          player['username'] ?? l10n.playersTab,
                          // Fallback, should not happen
                          style: TextStyle(
                            fontWeight: isCurrentUser
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          teamName,
                          style: TextStyle(color: teamColor),
                        ),
                        trailing: isCurrentUser
                            ? Chip(
                                label: Text(l10n.youLabel),
                                backgroundColor: Colors.amber,
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                              )
                            : null,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Dans GameLobbyScreen

  Widget _buildTeamInfo() {
    final l10n = AppLocalizations.of(context)!;
    final teamService = GetIt.I<TeamService>();
    final myTeamId = teamService.myTeamId;

    // Trouver l'équipe du joueur
    String teamName = l10n.noTeam;
    Color teamColor = Colors.grey;

    if (myTeamId != null) {
      final teamIndex =
          teamService.teams.indexWhere((team) => team.id == myTeamId);
      if (teamIndex >= 0) {
        teamName = teamService.teams[teamIndex].name;
        teamColor = Colors.green;
      }
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.yourTeamLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: teamColor,
                  child: Icon(
                    myTeamId != null ? Icons.group : Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  teamName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: teamColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TeamManagementScreen()),
                );
              },
              icon: const Icon(Icons.group),
              label: Text(l10n.manageTeamsButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeTeamDialog(List<Team> teams) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changeTeamTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              final teamService = context.watch<TeamService>();
              final isCurrentTeam = team.id == teamService.myTeamId;

              return ListTile(
                title: Text(team.name),
                subtitle: Text(l10n.playersCountSuffix(team.players.length)),
                trailing: isCurrentTeam
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: isCurrentTeam
                    ? null
                    : () {
                        final authService = context.read<AuthService>();
                        final playerId = authService.currentUser!.id;
                        teamService.assignPlayerToTeam(playerId!, team.id,
                            context.read<GameStateService>().selectedMap!.id!);
                        Navigator.of(context).pop();
                      },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmationDialog(Field field) {
    final l10n = AppLocalizations.of(context)!;
    final playerConnectionService = context.read<PlayerConnectionService>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveFieldConfirmationTitle),
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

  Future<void> _deleteHistoryEntry(Field field) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteFieldHistoryTitle),
        content: Text(l10n.deleteFieldHistoryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final apiService = GetIt.I<ApiService>();
      await apiService.delete('fields-history/history/${field.id}');

      setState(
          () {}); // ❗ Recharge le FutureBuilder (déclenche à nouveau _loadPreviousFields)

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fieldDeletedFromHistory)),
      );
    } catch (e) {
      logger.d('❌ Erreur suppression terrain : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorDeletingField)),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _navigateToGameSession(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = GetIt.I<AuthService>();
    final gameStateService = GetIt.I<GameStateService>();

    final user = authService.currentUser;
    final teamId = GetIt.I<TeamService>().myTeamId;
    final isHost = false;
    final gameSession = gameStateService.activeGameSession;

    if (user != null && gameSession != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameSessionScreen(
            userId: user.id!,
            teamId: teamId,
            isHost: isHost,
            gameSession: gameSession,
            fieldId: gameSession.field!.id,
          ),
        ),
      );
    } else {
      logger.d(
          '❌ Impossible de rejoindre la partie : utilisateur ou session manquants');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cannotJoinGame)),
      );
    }
  }

  @override
  void dispose() {
    final fieldId = _gameStateService.selectedMap?.field?.id;
    if (fieldId != null) {
      logger.d('📡 Désabonnement du topic du terrain depuis GameLobbyScreen');
      _webSocketService.unsubscribeFromField(fieldId);
    }

    _tabController.dispose();
    super.dispose();
  }
}
