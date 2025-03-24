import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../../services/team_service.dart';
import '../../services/websocket_service.dart';
import 'join_team_screen.dart';
import 'qr_code_scanner_screen.dart';
import 'package:go_router/go_router.dart';

class GamerDashboardScreen extends StatefulWidget {
  const GamerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<GamerDashboardScreen> createState() => _GamerDashboardScreenState();
}

class _GamerDashboardScreenState extends State<GamerDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Connecter au WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final webSocketService = Provider.of<WebSocketService>(context, listen: false);
      webSocketService.connect();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamer Dashboard'),
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
            Tab(icon: Icon(Icons.map), text: 'Terrain'),
            Tab(icon: Icon(Icons.people), text: 'Joueurs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Parties
          _buildTerrainTab(),
          _buildPlayersTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action en fonction de l'onglet actif
          if (_tabController.index == 0) {
            _showScanQRCodeDialog();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const JoinTeamScreen()),
            );
          }
        },
        child: Icon(_tabController.index == 0 ? Icons.qr_code_scanner : Icons.group_add),
      ),
    );
  }

  Widget _buildTerrainTab() {
    final gameState = Provider.of<GameStateService>(context);

    if (!gameState.isTerrainOpen || gameState.selectedMap == null) {
      return const Center(
        child: Text(
          'Aucun terrain connecté',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Carte : ${gameState.selectedMap?.name ?? "Inconnue"}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Scénario : ${gameState.selectedScenarios != null && gameState.selectedScenarios!.isNotEmpty ? gameState.selectedScenarios!.first['name'] ?? 'Inconnu' : 'Aucun'}',
          ),
          const SizedBox(height: 8),
          if (gameState.timeLeftDisplay != null)
            Text('Temps restant : ${gameState.timeLeftDisplay}'),
          const Spacer(),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // À implémenter : quitter la partie ?
              },
              icon: const Icon(Icons.logout),
              label: const Text('Quitter la partie'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersTab() {
    final teamService = Provider.of<TeamService>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.id;

    final players = teamService.connectedPlayers;
    final myTeamId = teamService.myTeamId;

    if (players.isEmpty) {
      return const Center(
        child: Text('Aucun joueur connecté.'),
      );
    }

    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final isMe = player['id'] == currentUserId;
        final isSameTeam = player['teamId'] == myTeamId;

        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(player['username'] ?? 'Joueur'),
          subtitle: Text(isSameTeam ? 'Dans votre équipe' : 'Autre équipe'),
          trailing: isMe
              ? ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinTeamScreen()),
              );
            },
            child: const Text('Changer d\'équipe'),
          )
              : null,
        );
      },
    );
  }
  
  void _showScanQRCodeDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRCodeScannerScreen()),
    );
  }
}
