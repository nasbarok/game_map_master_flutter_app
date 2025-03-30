import 'package:airsoft_game_map/screens/gamer/team_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/field.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../../services/player_connection_service.dart';
import '../../services/team_service.dart';
import '../../services/websocket_service.dart';
import '../../services/invitation_service.dart';
import 'package:go_router/go_router.dart';
import '../../models/team.dart';

class GameLobbyScreen extends StatefulWidget {
  const GameLobbyScreen({Key? key}) : super(key: key);

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Charger les données initiales après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final teamService = Provider.of<TeamService>(context, listen: false);
      final gameStateService = Provider.of<GameStateService>(context, listen: false);
      final mapId = gameStateService.selectedMap?.id;

      if (mapId != null) {
        teamService.loadConnectedPlayers(); // facultatif si ça marche sans paramètre
        teamService.loadTeams(mapId);       // utiliser l’ID de la carte active
      } else {
        print('❌ Aucune carte sélectionnée, impossible de charger les équipes.');
      }
      teamService.startPeriodicRefresh();

    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameStateService>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Partie sur ${gameState.selectedMap?.name ?? ""}'),
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
          // Onglet Terrain
          _buildTerrainTab(),
          // Onglet Joueurs
          _buildPlayersTab(),
        ],
      ),
    );
  }

  Widget _buildTerrainTab() {
    final gameState = Provider.of<GameStateService>(context);

    return Padding(
      padding: const EdgeInsets.all(16),
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
                  Text(
                    'Carte : ${gameState.selectedMap?.name ?? "Inconnue"}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Scénarios : ${gameState.selectedScenarios != null && gameState.selectedScenarios!.isNotEmpty ? gameState.selectedScenarios!.map((s) => s['name']).join(", ") : "Aucun"}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
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
                            'Temps restant : ${gameState.timeLeftDisplay}',
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
            const Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partie en cours',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Suivez les instructions de l\'hôte et collaborez avec votre équipe pour atteindre les objectifs du scénario.',
                    ),
                  ],
                ),
              ),
            )
          else
            const Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'En attente de démarrage',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'L\'hôte n\'a pas encore lancé la partie. Préparez votre équipement et rejoignez une équipe en attendant.',
                    ),
                  ],
                ),
              ),
            ),
          const Spacer(),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                _showLeaveConfirmationDialog(gameState.selectedMap!.field!);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Quitter la partie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersTab() {
    final gameStateService = Provider.of<GameStateService>(context);
    final authService = Provider.of<AuthService>(context);
    final connectedPlayers = gameStateService.connectedPlayersList;
    final currentUserId = authService.currentUser?.id;

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
                  'Joueurs connectés (${connectedPlayers.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (connectedPlayers.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Aucun joueur connecté',
                        style: TextStyle(color: Colors.grey),
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

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrentUser ? Colors.amber : Colors.blue,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          player['username'] ?? 'Joueur',
                          style: TextStyle(
                            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: player['teamName'] != null
                            ? Text('Équipe : ${player['teamName']}')
                            : const Text('Sans équipe', style: TextStyle(fontStyle: FontStyle.italic)),
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
    final teamService = Provider.of<TeamService>(context);
    final myTeamId = teamService.myTeamId;

    // Trouver l'équipe du joueur
    String teamName = "Aucune équipe";
    Color teamColor = Colors.grey;

    if (myTeamId != null) {
      final teamIndex = teamService.teams.indexWhere((team) => team.id == myTeamId);
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
              'Votre équipe',
              style: TextStyle(
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
                  MaterialPageRoute(builder: (context) => const TeamManagementScreen()),
                );
              },
              icon: const Icon(Icons.group),
              label: const Text('Gérer les équipes'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer d\'équipe'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              final teamService = Provider.of<TeamService>(context, listen: false);
              final isCurrentTeam = team.id == teamService.myTeamId;
              
              return ListTile(
                title: Text(team.name),
                subtitle: Text('${team.players.length} joueur${team.players.length != 1 ? 's' : ''}'),
                trailing: isCurrentTeam 
                    ? const Icon(Icons.check_circle, color: Colors.green) 
                    : null,
                onTap: isCurrentTeam 
                    ? null 
                    : () {
                        final authService = Provider.of<AuthService>(context, listen: false);
                        final playerId = authService.currentUser!.id;
                        teamService.assignPlayerToTeam(playerId!, team.id, Provider.of<GameStateService>(context, listen: false).selectedMap!.id!);
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
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmationDialog(Field field) {
    final playerConnectionService =
    Provider.of<PlayerConnectionService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la partie'),
        content: const Text('Êtes-vous sûr de vouloir quitter cette partie ? Vous ne pourrez pas la rejoindre à nouveau si elle est fermée.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Annuler'),
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
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}
