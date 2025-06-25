// lib/screens/gamer/team_management_screen.dart

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../services/team_service.dart';
import '../../services/game_state_service.dart';
import '../../services/auth_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({Key? key}) : super(key: key);

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _loadTeams(); // ✅ contexte désormais disponible
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gameStateService = GetIt.I<GameStateService>();
      final teamService = GetIt.I<TeamService>();

      final selectedMap = gameStateService.selectedMap;
      if (selectedMap != null && selectedMap.id != null) {
        await teamService.loadTeams(selectedMap.id!);
      }
    } catch (e) {
      logger.d('❌ Erreur lors du chargement des équipes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinTeam(int teamId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gameStateService = GetIt.I<GameStateService>();
      final teamService = GetIt.I<TeamService>();
      final authService = GetIt.I<AuthService>();

      if (gameStateService.selectedMap != null &&
          authService.currentUser != null) {
        await teamService.assignPlayerToTeam(authService.currentUser!.id!,
            teamId, gameStateService.selectedMap!.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vous avez rejoint l\'équipe avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger.d('❌ Erreur lors du changement d\'équipe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du changement d\'équipe: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamService = context.watch<TeamService>();
    final gameStateService = context.watch<GameStateService>();
    final teams = teamService.teams;
    final myTeamId = teamService.myTeamId;
    final connectedPlayers = gameStateService.connectedPlayersList;
    final authService = GetIt.I<AuthService>();
    final currentUserId = authService.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des équipes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Équipes'),
            Tab(text: 'Joueurs'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTeams,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Onglet Équipes
                  teams.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.groups,
                                  size: 80,
                                  color: Colors.grey.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              const Text(
                                'Aucune équipe disponible',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Attendez que l\'hôte crée des équipes',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: teams.length,
                          itemBuilder: (context, index) {
                            final team = teams[index];
                            final isMyTeam = team.id == myTeamId;
                            final teamPlayers = team.players;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      isMyTeam ? Colors.green : Colors.blue,
                                  child: Icon(
                                    isMyTeam ? Icons.check : Icons.group,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  team.name,
                                  style: TextStyle(
                                    fontWeight: isMyTeam
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text('${teamPlayers.length} joueurs'),
                                trailing: isMyTeam
                                    ? const Chip(
                                        label: Text('Votre équipe'),
                                        backgroundColor: Colors.green,
                                        labelStyle:
                                            TextStyle(color: Colors.white),
                                      )
                                    : ElevatedButton(
                                        onPressed: () => _joinTeam(team.id),
                                        child: const Text('Rejoindre'),
                                      ),
                                children: [
                                  ...teamPlayers.map((player) => ListTile(
                                        leading: const CircleAvatar(
                                          child: Icon(Icons.person),
                                        ),
                                        title: Text(
                                            player['username'] ?? 'Joueur'),
                                        trailing: player['id'] == currentUserId
                                            ? const Icon(Icons.star,
                                                color: Colors.amber)
                                            : null,
                                      )),
                                ],
                              ),
                            );
                          },
                        ),

                  // Onglet Joueurs
                  connectedPlayers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people,
                                  size: 80,
                                  color: Colors.grey.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              const Text(
                                'Aucun joueur connecté',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Les joueurs connectés apparaîtront ici',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: connectedPlayers.length,
                          itemBuilder: (context, index) {
                            final player = connectedPlayers[index];
                            final isCurrentUser = player['id'] == currentUserId;

                            // Trouver l'équipe du joueur
                            String teamName = "Sans équipe";
                            Color teamColor = Colors.grey;

                            if (player['teamId'] != null) {
                              final teamIndex = teams.indexWhere(
                                  (team) => team.id == player['teamId']);
                              if (teamIndex >= 0) {
                                teamName = teams[teamIndex].name;
                                teamColor = Colors.blue;
                              }
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isCurrentUser
                                      ? Colors.amber
                                      : Colors.blue,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  player['username'] ?? 'Joueur',
                                  style: TextStyle(
                                    fontWeight: isCurrentUser
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  teamName,
                                  style: TextStyle(
                                    color: teamColor,
                                  ),
                                ),
                                trailing: isCurrentUser
                                    ? const Chip(
                                        label: Text('Vous'),
                                        backgroundColor: Colors.amber,
                                        labelStyle:
                                            TextStyle(color: Colors.white),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
