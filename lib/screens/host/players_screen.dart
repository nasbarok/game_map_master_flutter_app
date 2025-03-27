import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../../services/invitation_service.dart';
import '../../services/team_service.dart';
import '../../services/api_service.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({Key? key}) : super(key: key);

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  int? getCurrentMapId(BuildContext context) {
    return Provider.of<GameStateService>(context, listen: false)
        .selectedMap
        ?.id;
  }

  @override
  void initState() {
    super.initState();

    // Chargement initial des équipes si le terrain est déjà ouvert
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // Vérifier si le widget est toujours monté

      final gameStateService = Provider.of<GameStateService>(context, listen: false);
      final teamService = Provider.of<TeamService>(context, listen: false);

      if (gameStateService.isTerrainOpen && gameStateService.selectedMap != null) {
        teamService.loadTeams(gameStateService.selectedMap!.id!);
        teamService.loadConnectedPlayers();
        teamService.startPeriodicRefresh(); // Activer le rafraîchissement périodique
      }
    });
  }

  @override
  void dispose() {
    // Arrêter explicitement le rafraîchissement périodique
    if (mounted) {
      final teamService = Provider.of<TeamService>(context, listen: false);
      teamService.stopPeriodicRefresh();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final gameStateService = Provider.of<GameStateService>(context);
    final teamService = Provider.of<TeamService>(context, listen: false);

    // Si le terrain vient d'être ouvert et qu'une carte est sélectionnée
    if (gameStateService.isTerrainOpen && gameStateService.selectedMap != null) {
      teamService.loadTeams(gameStateService.selectedMap!.id!);
      teamService.loadConnectedPlayers();
      teamService.startPeriodicRefresh();
    } else if (!gameStateService.isTerrainOpen) {
      teamService.stopPeriodicRefresh();
    }
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
      final apiService = Provider.of<ApiService>(context, listen: false);
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
    final invitationService =
        Provider.of<InvitationService>(context, listen: false);

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

  @override
  Widget build(BuildContext context) {
    final gameStateService = Provider.of<GameStateService>(context);
    final invitationService = Provider.of<InvitationService>(context);
    final teamService = Provider.of<TeamService>(context);

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
            _buildTeamsTab(teamService),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    final invitationService = Provider.of<InvitationService>(context);
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
                      return Card(
                        child: ListTile(
                          title: Text(
                              'Invitation de ${invitation['fromUsername']}'),
                          subtitle: Text('Carte: ${invitation['mapName']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => invitationService
                                    .respondToInvitation(invitation, false),
                                child: const Text('Refuser'),
                              ),
                              ElevatedButton(
                                onPressed: () => invitationService
                                    .respondToInvitation(invitation, true),
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
                      final status = invitation['status'] ?? 'pending';

                      return Card(
                        child: ListTile(
                          title:
                              Text('Invitation à ${invitation['toUsername']}'),
                          subtitle: Text(
                              'Statut: ${status == 'pending' ? 'En attente' : status == 'accepted' ? 'Acceptée' : 'Refusée'}'),
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

  Widget _buildTeamsTab(TeamService teamService) {
    final teams = teamService.teams;
    final gameStateService = Provider.of<GameStateService>(context);
    final connectedPlayers = gameStateService.connectedPlayersList;
    final mapId = getCurrentMapId(context);

    // Modification de la logique pour déterminer les joueurs sans équipe
    final unassignedPlayers = connectedPlayers.where((player) {
      // Un joueur est considéré comme non assigné s'il n'a pas de teamId
      return player['teamId'] == null;
    }).toList();

    print('📋 connectedPlayers: $connectedPlayers');
    print('📋 teams: ${teams.map((t) => {'id': t.id, 'players': t.players})}');
    print('📋 unassignedPlayers: $unassignedPlayers');

    // Reste du code d'affichage...
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Équipes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Afficher une boîte de dialogue pour créer une équipe
                  showDialog(
                    context: context,
                    builder: (context) {
                      final nameController = TextEditingController();
                      return AlertDialog(
                        title: const Text('Créer une équipe'),
                        content: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom de l\'équipe',
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
                                teamService.createTeam(nameController.text);
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Créer'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle équipe'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          (teams.isEmpty && unassignedPlayers.isEmpty)
              ? const Center(
            child: Text(
              'Aucune équipe créée',
              style: TextStyle(color: Colors.grey),
            ),
          )
              : Expanded(
            child: ListView(children: [
              if (unassignedPlayers.isNotEmpty) ...[
                Text(
                  'Joueurs sans équipe',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...unassignedPlayers.map((player) => ListTile(
                  leading:
                  const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(player['username'] ?? 'Joueur'),
                  trailing: DropdownButton<int>(
                    hint: const Text("Assigner"),
                    onChanged: (teamId) {
                      if (teamId != null && mapId != null) {
                        teamService.assignPlayerToTeam(
                            player['id'], teamId, mapId);
                      }
                    },
                    items: teams
                        .map((t) => DropdownMenuItem<int>(
                      value: t.id,
                      child: Text(t.name),
                    ))
                        .toList(),
                  ),
                )),
                const Divider(),
              ],
              // ✅ Liste des équipes
              ...teams.map(
                    (team) => Card(
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Text(team.name),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () {
                            final nameController =
                            TextEditingController(text: team.name);
                            // Afficher une boîte de dialogue pour renommer l'équipe
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Renommer l\'équipe'),
                                  content: TextField(
                                    controller: nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nouveau nom',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Annuler'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (nameController
                                            .text.isNotEmpty) {
                                          teamService.renameTeam(team.id,
                                              nameController.text);
                                          Navigator.of(context).pop();
                                        }
                                      },
                                      child: const Text('Renommer'),
                                    ),
                                  ],
                                );
                              },
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
                      ...team.players.map((player) => ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(player['username'] ?? 'Joueur'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'remove') {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title:
                                  const Text("Retirer le joueur"),
                                  content: Text(
                                      "Retirer ${player['username']} de l'équipe ${team.name} ?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text('Annuler'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        final mapId =
                                        getCurrentMapId(context);
                                        if (mapId != null) {
                                          teamService
                                              .assignPlayerToTeam(
                                              player['id'],
                                              0,
                                              mapId);
                                        } // ID 0 → aucune équipe
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Retirer'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              final mapId = getCurrentMapId(context);
                              final targetTeam = teams.firstWhere(
                                      (t) => t.id.toString() == value);
                              if (mapId != null) {
                                teamService.assignPlayerToTeam(
                                    player['id'], targetTeam.id, 0);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem<String>(
                              value: 'remove',
                              child: Text('Retirer de l\'équipe'),
                            ),
                            const PopupMenuDivider(),
                            ...teams
                                .where((t) => t.id != team.id)
                                .map((t) => PopupMenuItem<String>(
                              value: t.id.toString(),
                              child: Text(
                                  'Aller dans ${t.name}'),
                            )),
                          ],
                        ),
                      )),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Afficher une boîte de dialogue pour ajouter des joueurs
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title:
                                  const Text('Ajouter des joueurs'),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    height: 300,
                                    child: ListView.builder(
                                      itemCount: connectedPlayers.length,
                                      itemBuilder: (context, index) {
                                        final player =
                                        connectedPlayers[index];
                                        // Vérifier si le joueur est déjà dans une équipe
                                        bool isInTeam = false;
                                        for (var t in teams) {
                                          if (t.players.any((p) =>
                                          p['id'] == player['id'])) {
                                            isInTeam = true;
                                            break;
                                          }
                                        }

                                        return ListTile(
                                          leading: const CircleAvatar(
                                            child: Icon(Icons.person),
                                          ),
                                          title: Text(
                                              player['username'] ??
                                                  'Joueur'),
                                          trailing: isInTeam
                                              ? const Text(
                                              'Déjà dans une équipe')
                                              : ElevatedButton(
                                            onPressed: () {
                                              final mapId =
                                              getCurrentMapId(
                                                  context);
                                              if (mapId != null) {
                                                teamService
                                                    .assignPlayerToTeam(
                                                    player[
                                                    'id'],
                                                    team.id,
                                                    mapId);
                                                Navigator.of(
                                                    context)
                                                    .pop();
                                              }
                                            },
                                            child: const Text(
                                                'Ajouter'),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Fermer'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Ajouter des joueurs'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Afficher une boîte de dialogue pour sauvegarder la configuration
                  showDialog(
                    context: context,
                    builder: (context) {
                      final nameController = TextEditingController();
                      return AlertDialog(
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
                      );
                    },
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Sauvegarder configuration'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Afficher une boîte de dialogue pour charger une configuration
                  teamService.loadPreviousTeamConfigurations().then((_) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Charger une configuration'),
                          content: SizedBox(
                            width: double.maxFinite,
                            height: 300,
                            child: ListView.builder(
                              itemCount:
                              teamService.previousTeamConfigurations.length,
                              itemBuilder: (context, index) {
                                final config = teamService
                                    .previousTeamConfigurations[index];
                                return ListTile(
                                  title: Text(config.name),
                                  subtitle:
                                  Text('${config.players.length} joueurs'),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      teamService
                                          .applyTeamConfiguration(config.id);
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                          Text('Configuration appliquée'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    child: const Text('Appliquer'),
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
                        );
                      },
                    );
                  });
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('Charger configuration'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
