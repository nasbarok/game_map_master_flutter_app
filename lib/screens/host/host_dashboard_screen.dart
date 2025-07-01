import 'package:game_map_master_flutter_app/screens/host/players_screen.dart';
import 'package:flutter/material.dart';
import 'package:game_map_master_flutter_app/utils/app_utils.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/game_map_service.dart';
import '../../services/invitation_service.dart';
import '../../services/notifications.dart';
import '../../services/scenario_service.dart';
import '../../services/websocket_service.dart';
import '../../services/game_state_service.dart';
import '../../widgets/host_history_tab.dart';
import '../scenario/treasure_hunt/scoreboard_screen.dart';
import 'team_form_screen.dart';
import 'scenario_form_screen.dart';
import 'game_map_form_screen.dart';
import 'terrain_dashboard_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late InvitationService _invitationService;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 5, vsync: this); // 4 onglets comme demandé

    // Connecter au WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _invitationService = context.read<InvitationService>();
      final webSocketService = context.read<WebSocketService>();

      webSocketService.connect();

      _invitationService.onInvitationReceivedDialog = _showInvitationDialog;

      _loadGameMaps();
      _loadScenarios();
    });
  }

  @override
  void dispose() {
    _invitationService.onInvitationReceivedDialog = null;
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showInvitationDialog(Map<String, dynamic> invitation) async {
    final l10n = AppLocalizations.of(context)!;
    // Vérifie si l'application est visible à l'écran
    if (ModalRoute.of(context)?.isCurrent == true) {
      // ✅ Affichage classique du Dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.invitationReceivedTitle),
          content: Text(
            l10n.invitationReceivedMessage(
              invitation['fromUsername'] ?? l10n.unknownPlayerName,
              // Assurez-vous d'avoir une clé pour utilisateur inconnu
              invitation['mapName'] ?? l10n.unknownMap,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _invitationService.respondToInvitation(
                    context, invitation, false);
                Navigator.of(context).pop();
              },
              child: Text(l10n.declineInvitation),
            ),
            ElevatedButton(
              onPressed: () {
                _invitationService.respondToInvitation(
                    context, invitation, true);
                Navigator.of(context).pop();
              },
              child: Text(l10n.acceptInvitation),
            ),
          ],
        ),
      );
    } else {
      await showInvitationNotification(invitation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.watch<AuthService>();
    final gameStateService = context.watch<GameStateService>();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hostDashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout,
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
            Tab(icon: const Icon(Icons.dashboard), text: l10n.terrainTab),
            Tab(icon: const Icon(Icons.map), text: l10n.mapTab),
            Tab(
                icon: const Icon(Icons.videogame_asset),
                text: l10n.scenariosTab),
            Tab(icon: const Icon(Icons.people), text: l10n.playersTab),
            Tab(icon: const Icon(Icons.history), text: l10n.historyTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Terrain (tableau de bord host)
          const TerrainDashboardScreen(),

          // Onglet Cartes (gestion des terrains/cartes)
          _buildMapsTab(),

          // Onglet Scénarios
          _buildScenariosTab(),

          // Onglet Joueurs (équipes)
          gameStateService.isTerrainOpen
              ? const PlayersScreen()
              : _buildDisabledTeamsTab(),
          const HostHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action en fonction de l'onglet actif
          switch (_tabController.index) {
            case 0:
              // Pour l'onglet Terrain, pas d'action spécifique
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.noActionForFieldTabSnackbar),
                  backgroundColor: Colors.blue,
                ),
              );
              break;
            case 1:
              // Pour l'onglet Cartes
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const GameMapFormScreen()),
              );
              break;
            case 2:
              // Pour l'onglet Scénarios
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ScenarioFormScreen()),
              );
              break;
            case 3:
              // Pour l'onglet Joueurs
              if (gameStateService.isTerrainOpen) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TeamFormScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.openFieldFirstSnackbar),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              break;
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMapsTab() {
    final l10n = AppLocalizations.of(context)!;
    final gameMapService = context.watch<GameMapService>();

    // Si la liste des cartes est vide
    if (gameMapService.gameMaps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.noMapAvailable,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.createMapPrompt,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GameMapFormScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.createMap),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: gameMapService.gameMaps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final map = gameMapService.gameMaps[index];
        return Card(
          child: ListTile(
            title: Text(map.name ?? l10n.noMapAvailable),
            subtitle: Text(map.description ?? l10n.noDescription),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.editMap,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameMapFormScreen(
                          gameMap: map,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: l10n.deleteMap,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.confirmDeleteTitle),
                        content: Text(l10n.confirmDeleteMapMessage),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final gameMapService = context.read<GameMapService>();
                      try {
                        await gameMapService.deleteGameMap(map.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.mapDeletedSuccess),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.errorDeletingMap(e.toString())),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScenariosTab() {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.watch<GameStateService>();
    final scenarioService = context.watch<ScenarioService>();

    final activeScenario =
        gameStateService.selectedScenarios?.isNotEmpty == true
            ? gameStateService.selectedScenarios!.first
            : null;

    if (scenarioService.scenarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videogame_asset, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.noScenarioAvailable,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.createScenarioPrompt,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ScenarioFormScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.createScenario),
            ),
            const SizedBox(height: 24),
            // 👉 Bouton Tableau des scores si Treasure Hunt actif
            if (activeScenario != null &&
                activeScenario.scenario.type == 'treasure_hunt')
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScoreboardScreen(
                        treasureHuntId: activeScenario.scenario.id,
                        scenarioName: activeScenario.scenario.name,
                        isHost: true,
                      ),
                    ),
                  );
                },
                child: Text(l10n.scoreboardButton),
              ),
          ],
        ),
      );
    }

    // 👉 Sinon afficher la liste des scénarios
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: scenarioService.scenarios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final scenario = scenarioService.scenarios[index];
        return Card(
          child: ListTile(
            title: Text(scenario.name),
            subtitle: Text(
              scenario.description ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.editScenario,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScenarioFormScreen(
                          scenario: scenario,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: l10n.deleteScenario,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.confirmDeleteTitle),
                        content: Text(l10n.confirmDeleteScenarioMessage),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await context
                            .read<ScenarioService>()
                            .deleteScenario(scenario.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.scenarioDeletedSuccess),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.error + e.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamsTab() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            l10n.noTeamsCreated,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createTeamPrompt,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TeamFormScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.createTeam),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledTeamsTab() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            l10n.playersUnavailableTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.openField,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Basculer vers l'onglet Terrain
              _tabController.animateTo(0);
            },
            icon: const Icon(Icons.dashboard),
            label: Text(l10n.goToFieldTabButton),
          ),
        ],
      ),
    );
  }

  // Charger les cartes depuis GameMapService
  Future<void> _loadGameMaps() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final gameMapService = context.read<GameMapService>();
      await gameMapService
          .loadGameMaps(); // Charger les cartes via GameMapService
    } catch (e) {
      logger.d(l10n.errorLoadingMaps(e.toString()));
    }
  }

  // Charger les scénarios depuis ScenarioService
  Future<void> _loadScenarios() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final scenarioService = context.read<ScenarioService>();
      await scenarioService
          .loadScenarios(); // Charger les scénarios via ScenarioService
    } catch (e) {
      logger.d(l10n.errorLoadingScenarios(e.toString()));
    }
  }
}
