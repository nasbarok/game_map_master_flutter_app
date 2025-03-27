import 'package:airsoft_game_map/screens/host/players_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../../models/field.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/invitation_service.dart';
import '../../services/notifications.dart';
import '../../services/websocket_service.dart';
import '../../services/game_state_service.dart';
import 'field_form_screen.dart';
import 'team_form_screen.dart';
import 'scenario_form_screen.dart';
import 'game_map_form_screen.dart';
import 'qr_code_generator_screen.dart';
import 'scenario_selection_dialog.dart';
import 'terrain_dashboard_screen.dart';
import 'package:go_router/go_router.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 onglets comme demandé
    
    // Connecter au WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final webSocketService = Provider.of<WebSocketService>(context, listen: false);
      final invitationService = Provider.of<InvitationService>(context, listen: false);

      webSocketService.connect();

      invitationService.onInvitationReceivedDialog = _showInvitationDialog;
    });
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
                final invitationService = Provider.of<InvitationService>(context, listen: false);
                invitationService.respondToInvitation(invitation, false);
                Navigator.of(context).pop();
              },
              child: const Text('Refuser'),
            ),
            ElevatedButton(
              onPressed: () {
                final invitationService = Provider.of<InvitationService>(context, listen: false);
                invitationService.respondToInvitation(invitation, true);
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
  void dispose() {
    final invitationService = Provider.of<InvitationService>(context, listen: false);
    invitationService.onInvitationReceivedDialog = null;
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final gameStateService = Provider.of<GameStateService>(context);
    final user = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
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
                  content: Text('Utilisez l\'onglet Cartes pour créer ou modifier des cartes'),
                  backgroundColor: Colors.blue,
                ),
              );
              break;
            case 1:
              // Pour l'onglet Cartes
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GameMapFormScreen()),
              );
              break;
            case 2:
              // Pour l'onglet Scénarios
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScenarioFormScreen()),
              );
              break;
            case 3:
              // Pour l'onglet Joueurs
              if (gameStateService.isTerrainOpen) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TeamFormScreen()),
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
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    return FutureBuilder<List<dynamic>>(
      future: apiService.get('maps').then((data) => data as List<dynamic>),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final maps = snapshot.data ?? [];

        if (maps.isEmpty) {
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
                      MaterialPageRoute(builder: (context) => const GameMapFormScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une carte'),
                ),
              ],
            ),
          );
        }

        // Affichage de la liste des cartes
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: maps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final map = maps[index];
            return Card(
              child: ListTile(
                title: Text(map['name'] ?? 'Sans nom'),
                subtitle: Text(map['description'] ?? 'Pas de description'),
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildScenariosTab() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
            ],
          ),
        ],
      ),
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
}
