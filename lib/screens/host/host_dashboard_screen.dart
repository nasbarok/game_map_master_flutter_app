import 'package:airsoft_game_map/screens/host/players_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    // Vérifie si l'application est visible à l'écran
    if (ModalRoute.of(context)?.isCurrent == true) {
      // ✅ Affichage classique du Dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Invitation reçue'),
          content: Text(
            'Vous avez été invité par ${invitation['fromUsername']} '
            'pour rejoindre la carte "${invitation['mapName']}".',
          ),
          actions: [
            TextButton(
              onPressed: () {
                _invitationService.respondToInvitation(
                    context, invitation, false);
                Navigator.of(context).pop();
              },
              child: const Text('Refuser'),
            ),
            ElevatedButton(
              onPressed: () {
                _invitationService.respondToInvitation(
                    context, invitation, true);
                Navigator.of(context).pop();
              },
              child: const Text('Accepter'),
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
    final authService = context.watch<AuthService>();
    final gameStateService = context.watch<GameStateService>();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Dashboard'),
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
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Terrain'),
            Tab(icon: Icon(Icons.map), text: 'Cartes'),
            Tab(icon: Icon(Icons.videogame_asset), text: 'Scénarios'),
            Tab(icon: Icon(Icons.people), text: 'Joueurs'),
            Tab(icon: Icon(Icons.history), text: 'Historique'),
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
                const SnackBar(
                  content: Text(
                      'Utilisez l\'onglet Cartes pour créer ou modifier des cartes'),
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
                  const SnackBar(
                    content: Text('Veuillez d\'abord ouvrir un terrain'),
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
    final gameMapService = context.watch<GameMapService>();

    // Si la liste des cartes est vide
    if (gameMapService.gameMaps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucune carte',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez une carte pour commencer',
              style: TextStyle(color: Colors.grey),
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
              label: const Text('Créer une carte'),
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
            title: Text(map.name ?? 'Sans nom'),
            subtitle: Text(map.description ?? 'Pas de description'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
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
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmer la suppression'),
                        content: const Text(
                            'Voulez-vous vraiment supprimer cette carte ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final gameMapService = context.read<GameMapService>();
                      try {
                        await gameMapService.deleteGameMap(map.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Carte supprimée avec succès'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur lors de la suppression : $e'),
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
            const Text(
              'Aucun scénario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez un scénario pour commencer',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScenarioFormScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer un scénario'),
            ),
            const SizedBox(height: 24),
            // 👉 Bouton Tableau des scores si Treasure Hunt actif
            if (activeScenario != null && activeScenario.scenario.type== 'treasure_hunt')
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
                child: const Text('Tableau des scores'),
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
            subtitle: Text(scenario.description ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
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
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Supprimer ce scénario ?'),
                        content: const Text('Voulez-vous vraiment supprimer ce scénario ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await context.read<ScenarioService>().deleteScenario(scenario.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Scénario supprimé'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur : $e'),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucune équipe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez une équipe pour commencer',
            style: TextStyle(color: Colors.grey),
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
            label: const Text('Créer une équipe'),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledTeamsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Joueurs non disponibles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Veuillez d\'abord ouvrir un terrain',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Basculer vers l'onglet Terrain
              _tabController.animateTo(0);
            },
            icon: const Icon(Icons.dashboard),
            label: const Text('Aller à l\'onglet Terrain'),
          ),
        ],
      ),
    );
  }

  // Charger les cartes depuis GameMapService
  Future<void> _loadGameMaps() async {
    try {
      final gameMapService = context.read<GameMapService>();
      await gameMapService
          .loadGameMaps(); // Charger les cartes via GameMapService
    } catch (e) {
      print('Erreur lors du chargement des cartes: $e');
    }
  }

  // Charger les scénarios depuis ScenarioService
  Future<void> _loadScenarios() async {
    try {
      final scenarioService = context.read<ScenarioService>();
      await scenarioService.loadScenarios(); // Charger les scénarios via ScenarioService
    } catch (e) {
      print('Erreur lors du chargement des scénarios: $e');
    }
  }

}
