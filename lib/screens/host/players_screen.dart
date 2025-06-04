import 'package:airsoft_game_map/models/websocket/websocket_message.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../../services/invitation_service.dart';
import '../../services/team_service.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import 'package:airsoft_game_map/utils/logger.dart';
class PlayersScreen extends StatefulWidget {
  const PlayersScreen({Key? key}) : super(key: key);

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final TextEditingController _searchController = TextEditingController();
  late TeamService teamService;
  late GameStateService gameStateService;


  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  int? getCurrentMapId(BuildContext context) {
    return context.watch<GameStateService>().selectedMap?.id;
  }

  @override
  void initState() {
    super.initState();

    // Chargement initial des équipes si le terrain est déjà ouvert
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // Vérifier si le widget est toujours monté

      if (gameStateService.isTerrainOpen &&
          gameStateService.selectedMap != null) {
        teamService.loadTeams(gameStateService.selectedMap!.id!);
        logger.d(
            '🌀 [players_screen] [initState] Chargement des équipes et des joueurs connectés');
        gameStateService.loadConnectedPlayers();
      }
    });
  }


  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    teamService = context.watch<TeamService>();
    gameStateService = context.watch<GameStateService>();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final apiService = context.read<ApiService>();
      final results = await apiService.get('users/search?query=$query');

      setState(() {
        _searchResults = results as List;
        _isSearching = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la recherche: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _sendInvitation(int userId, String username) {
    final invitationService = context.read<InvitationService>();

    try {
      invitationService.sendInvitation(userId, username);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitation envoyée à $username'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void removePlayerFromTeam(int playerId) {
    final mapId = getCurrentMapId(context);
    final teamService = context.watch<TeamService>();
    if (mapId != null) {
      // Utiliser null au lieu de 0 pour indiquer "pas d'équipe"
      teamService.removePlayerFromTeam(playerId, mapId);
    }
  }

  // Dans _PlayersScreenState
  Future<void> kickPlayer(int playerId, String playerName) async {
    if (!mounted) return;
    try {
      final gameStateService = context.read<GameStateService>();
      final fieldId = gameStateService.selectedMap?.field?.id;

      if (fieldId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Aucun terrain sélectionnée'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final apiService = context.read<ApiService>();

      // Appel à l'API pour déconnecter le joueur
      await apiService.post('fields/$fieldId/players/$playerId/kick', {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$playerName a été déconnecté de la partie'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      logger.d('❌ Erreur lors de la déconnexion du joueur: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la déconnexion du joueur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameStateService = context.watch<GameStateService>();
    final invitationService = context.watch<InvitationService>();

    // Si le terrain n'est pas ouvert, afficher un message
    if (!gameStateService.isTerrainOpen) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 80, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Gestion des joueurs non disponible',
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
                // Naviguer vers l'onglet Terrain
                DefaultTabController.of(context)?.animateTo(0);
              },
              icon: const Icon(Icons.dashboard),
              label: const Text('Aller à l\'onglet Terrain'),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion des joueurs'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Rechercher'),
              Tab(text: 'Invitations'),
              Tab(text: 'Équipes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Onglet Recherche
            _buildSearchTab(),

            // Onglet Invitations
            _buildInvitationsTab(invitationService),

            // Onglet Équipes
            _buildTeamsTab(teamService, gameStateService),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    final invitationService = context.watch<InvitationService>();
    final canInvite = invitationService.canSendInvitations();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Rechercher des joueurs',
              hintText: 'Entrez un nom d\'utilisateur',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _searchUsers('');
                },
              ),
              border: const OutlineInputBorder(),
            ),
            onChanged: _searchUsers,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun résultat. Essayez une autre recherche.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(user['username'][0].toUpperCase()),
                            ),
                            title: Text(user['username']),
                            subtitle: Text(user['role'] ?? 'Joueur'),
                            trailing: canInvite
                                ? ElevatedButton(
                                    onPressed: () => _sendInvitation(
                                      user['id'],
                                      user['username'],
                                    ),
                                    child: const Text('Inviter'),
                                  )
                                : const SizedBox.shrink(),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsTab(InvitationService invitationService) {
    final pendingInvitations = invitationService.pendingInvitations;
    final sentInvitations = invitationService.sentInvitations;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invitations reçues',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          pendingInvitations.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'Aucune invitation en attente',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: pendingInvitations.length,
                    itemBuilder: (context, index) {
                      final invitation = pendingInvitations[index];
                      final invitationToJson = invitation.toJson();
                      final payload = invitationToJson['payload'] ?? {};
                      // Accéder au payload de manière sécurisée
                      final fromUsername = payload['fromUsername'] ?? 'Inconnu';
                      final mapName = payload['mapName'] ?? 'Carte inconnue';
                      return Card(
                        child: ListTile(
                          title: Text('Invitation de $fromUsername'),
                          subtitle: Text('Carte: $mapName'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    invitationService.respondToInvitation(
                                        context, invitationToJson, false),
                                child: const Text('Refuser'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    invitationService.respondToInvitation(
                                        context, invitationToJson, true),
                                child: const Text('Accepter'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          const SizedBox(height: 16),
          Text(
            'Invitations envoyées',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          sentInvitations.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'Aucune invitation envoyée',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: sentInvitations.length,
                    itemBuilder: (context, index) {
                      final invitation = sentInvitations[index];
                      final invitationToJson = invitation.toJson();
                      final payload = invitationToJson['payload'] ?? {};
                      final status = invitationToJson['status'] ?? 'pending';
                      final toUsername = payload['toUsername'] ?? 'Inconnu';

                      String statusText;
                      if (status == 'pending') {
                        statusText = 'En attente';
                      } else if (status == 'accepted') {
                        statusText = 'Acceptée';
                      } else {
                        statusText = 'Refusée';
                      }

                      return Card(
                        child: ListTile(
                          title: Text('Invitation à $toUsername'),
                          subtitle: Text('Statut: $statusText'),
                          trailing: status == 'pending'
                              ? const Icon(Icons.hourglass_empty)
                              : status == 'accepted'
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : const Icon(Icons.close, color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildUnassignedPlayerTile(Map<String, dynamic> player,
      List<dynamic> teams, TeamService teamService, int? mapId) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(player['username'] ?? 'Joueur inconnu'),
      subtitle: const Text('Non assigné'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            hint: const Text('Assigner'),
            onChanged: (teamId) {
              if (teamId != null && mapId != null) {
                teamService.assignPlayerToTeam(player['id'], teamId, mapId);
              }
            },
            items: [
              for (var team in teams)
                DropdownMenuItem(
                  value: team.id,
                  child: Text(team.name),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            tooltip: 'Déconnecter le joueur',
            onPressed: () => kickPlayer(player['id'], player['username']),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamPlayerTile(
      Map<String, dynamic> player,
      int teamId,
      String teamName,
      TeamService teamService,
      int? mapId,
      List<dynamic> teams) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.blue,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(player['username'] ?? 'Joueur inconnu'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.group_remove),
            tooltip: 'Retirer de l\'équipe',
            onPressed: () {
              if (mapId != null) {
                teamService.removePlayerFromTeam(player['id'], mapId);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            tooltip: 'Déconnecter le joueur',
            onPressed: () => kickPlayer(player['id'], player['username']),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsTab(
      TeamService teamService, GameStateService gameStateService) {
    final connectedPlayers = gameStateService.connectedPlayersList;
    final mapId = getCurrentMapId(context);
    final teams = teamService.teams;
    logger.d('🌀 Rebuild TeamsTab : ${teams.length} équipe(s)');

    final unassignedPlayers = connectedPlayers.where((player) {
      if (player['teamId'] == null) return true;
      final teamIndex = teams.indexWhere((team) => team.id == player['teamId']);
      if (teamIndex < 0) return true;
      final isInTeam =
          teams[teamIndex].players.any((p) => p['id'] == player['id']);
      return !isInTeam;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Titre + bouton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Équipes', style: Theme.of(context).textTheme.titleLarge),
              ElevatedButton.icon(
                onPressed: () {
                  final nameController = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Créer une équipe'),
                      content: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                            labelText: 'Nom de l\'équipe'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (nameController.text.isNotEmpty) {
                              teamService.createTeam(nameController.text);
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('Créer'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle équipe'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ Liste scrollable dans Expanded dans Column (et plus dans Row)
          Expanded(
            child: (teams.isEmpty && unassignedPlayers.isEmpty)
                ? const Center(
                    child: Text(
                      'Aucune équipe créée',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView(
                    children: [
                      if (unassignedPlayers.isNotEmpty) ...[
                        Text('Joueurs sans équipe',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        ...unassignedPlayers.map((player) =>
                            _buildUnassignedPlayerTile(
                                player, teams, teamService, mapId)),
                        const Divider(),
                      ],
                      ...teams.map((team) => _buildTeamCard(
                            team,
                            teams,
                            teamService,
                            mapId,
                            connectedPlayers,
                          )),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          // ✅ Bouton en bas
          ElevatedButton.icon(
            onPressed: () {
              final nameController = TextEditingController();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sauvegarder la configuration'),
                  content: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la configuration',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          teamService.saveCurrentTeamConfiguration(
                              nameController.text);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Configuration sauvegardée'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: const Text('Sauvegarder'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('Sauvegarder configuration'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(
    dynamic team,
    List<dynamic> allTeams,
    TeamService teamService,
    int? mapId,
    List<dynamic> connectedPlayers,
  ) {
    return Card(
      child: ExpansionTile(
        title: Row(
          children: [
            Text(team.name),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 16),
              onPressed: () {
                final nameController = TextEditingController(text: team.name);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Renommer l\'équipe'),
                    content: TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Nouveau nom'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty) {
                            teamService.renameTeam(
                                team.id, nameController.text);
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Renommer'),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 16),
              onPressed: () {
                teamService.deleteTeam(team.id);
              },
            ),
          ],
        ),
        subtitle: Text('${team.players.length} joueurs'),
        children: [
          ...team.players.map(
            (player) => _buildTeamPlayerTile(
                player, team.id, team.name, teamService, mapId, allTeams),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Ajouter des joueurs'),
                    content: SizedBox(
                      width: double.maxFinite,
                      height: 300,
                      child: ListView.builder(
                        itemCount: connectedPlayers.length,
                        itemBuilder: (context, index) {
                          final player = connectedPlayers[index];
                          bool isInTeam = allTeams.any((t) =>
                              t.players.any((p) => p['id'] == player['id']));

                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(player['username'] ?? 'Joueur inconnu'),
                            trailing: isInTeam
                                ? const Text('Déjà dans une équipe')
                                : ElevatedButton(
                                    onPressed: () {
                                      if (mapId != null) {
                                        teamService.assignPlayerToTeam(
                                            player['id'], team.id, mapId);
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    child: const Text('Ajouter'),
                                  ),
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Ajouter des joueurs'),
            ),
          ),
        ],
      ),
    );
  }
}
