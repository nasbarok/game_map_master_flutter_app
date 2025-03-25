import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
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
    
    // Charger les données initiales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final teamService = Provider.of<TeamService>(context, listen: false);
      teamService.loadConnectedPlayers();
      teamService.loadTeams();
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

    // Si le terrain n'est pas ouvert, rediriger vers l'écran principal
    if (!gameState.isTerrainOpen) {
      // Utiliser un Future.microtask pour éviter de modifier l'UI pendant le build
      Future.microtask(() {
        context.go('/gamer');
      });
      return const Center(child: CircularProgressIndicator());
    }

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
                _showLeaveConfirmationDialog();
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
    final teamService = Provider.of<TeamService>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.id;

    final players = teamService.connectedPlayers;
    final teams = teamService.teams;
    final myTeamId = teamService.myTeamId;

    if (players.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun joueur connecté',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Organiser les joueurs par équipe
    Map<int?, List<dynamic>> playersByTeam = {};
    
    // Initialiser avec toutes les équipes, même vides
    for (var team in teams) {
      playersByTeam[team.id] = [];
    }
    
    // Ajouter une catégorie pour les joueurs sans équipe
    playersByTeam[null] = [];
    
    // Répartir les joueurs dans leurs équipes
    for (var player in players) {
      int? teamId = player['teamId'];
      if (!playersByTeam.containsKey(teamId)) {
        playersByTeam[teamId] = [];
      }
      playersByTeam[teamId]!.add(player);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Afficher le nombre total de joueurs
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Joueurs connectés (${players.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        
        // Afficher les joueurs par équipe
        ...playersByTeam.entries.map((entry) {
          final teamId = entry.key;
          final teamPlayers = entry.value;
          
          if (teamPlayers.isEmpty) {
            return const SizedBox.shrink(); // Ne pas afficher les équipes vides
          }
          
          final teamName = teamId == null 
              ? 'Sans équipe' 
              : teams.firstWhere((t) => t.id == teamId, orElse: () => Team(id: -1, name: 'Équipe inconnue', players: [])).name;
          
          final isMyTeam = teamId == myTeamId;
          
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: isMyTeam 
                  ? BorderSide(color: Theme.of(context).primaryColor, width: 2) 
                  : BorderSide.none,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMyTeam ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.group,
                        color: isMyTeam ? Theme.of(context).primaryColor : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        teamName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isMyTeam ? Theme.of(context).primaryColor : Colors.grey.shade800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${teamPlayers.length} joueur${teamPlayers.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: isMyTeam ? Theme.of(context).primaryColor : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: teamPlayers.length,
                  itemBuilder: (context, index) {
                    final player = teamPlayers[index];
                    final isMe = player['id'] == currentUserId;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isMe ? Theme.of(context).primaryColor : Colors.grey.shade400,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        player['username'] ?? 'Joueur',
                        style: TextStyle(
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: isMe ? const Text('Vous') : null,
                      trailing: isMe && teams.length > 1
                          ? ElevatedButton(
                              onPressed: () {
                                _showChangeTeamDialog(teams);
                              },
                              child: const Text('Changer d\'équipe'),
                            )
                          : null,
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ],
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
                        teamService.assignPlayerToTeam(playerId!, team.id);
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

  void _showLeaveConfirmationDialog() {
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
              context.go('/gamer');
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
