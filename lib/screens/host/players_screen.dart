import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../../services/invitation_service.dart';
import '../../services/team_service.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

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

      final l10n = AppLocalizations.of(context)!;
      final apiService = context.read<ApiService>();

      // Appel à l'API pour déconnecter le joueur
      await apiService.post('fields/$fieldId/players/$playerId/kick', {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.playerKickedSuccess(playerName)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      logger.d('❌ ${l10n.errorKickingPlayer(e.toString())}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorKickingPlayer(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool get isMapOwner {
    final authService = context.read<AuthService>();
    final gameStateService = context.read<GameStateService>();

    final currentUser = authService.currentUser;
    final selectedMap = gameStateService.selectedMap;

    if (currentUser == null || selectedMap == null) return false;

    return currentUser.id == selectedMap.owner?.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            Text(
              l10n.playerManagementUnavailableTitle,
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
                // Naviguer vers l'onglet Terrain
                DefaultTabController.of(context)?.animateTo(0);
              },
              icon: const Icon(Icons.dashboard),
              label: Text(l10n.goToFieldTabButton),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.playersManagement),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.searchTab),
              Tab(text: l10n.invitations),
              Tab(text: l10n.teams),
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
    final l10n = AppLocalizations.of(context)!;
    final invitationService = context.watch<InvitationService>();
    final canInvite = invitationService.canSendInvitations();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: l10n.searchPlayers,
              hintText: l10n.searchPlayersHint,
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
                    ? Center(
                        child: Text(
                          l10n.noResultsFound,
                          style: const TextStyle(color: Colors.grey),
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
                            subtitle: Text(user['role'] ?? l10n.roleGamer),
                            trailing: canInvite
                                ? ElevatedButton(
                                    onPressed: () => _sendInvitation(
                                      user['id'],
                                      user['username'],
                                    ),
                                    child: Text(l10n.inviteButton),
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
    final l10n = AppLocalizations.of(context)!;
    final pendingInvitations = invitationService.pendingInvitations;
    final sentInvitations = invitationService.sentInvitations;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.invitations,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          pendingInvitations.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      l10n.noInvitations,
                      style: const TextStyle(color: Colors.grey),
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
                      final fromUsername =
                          payload['fromUsername'] ?? l10n.unknownPlayerName;
                      final mapName = payload['mapName'] ?? l10n.unknownMap;
                      return Card(
                        child: ListTile(
                          title: Text(l10n.invitationFrom(fromUsername)),
                          subtitle: Text(l10n.mapLabelShort(mapName)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    invitationService.respondToInvitation(
                                        context, invitationToJson, false),
                                child: Text(l10n.declineInvitation),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    invitationService.respondToInvitation(
                                        context, invitationToJson, true),
                                child: Text(l10n.acceptInvitation),
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
            l10n.invitationsSentTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          sentInvitations.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      l10n.noInvitationsSent,
                      style: const TextStyle(color: Colors.grey),
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
                      final toUsername =
                          payload['toUsername'] ?? l10n.unknownPlayerName;

                      String statusText;
                      if (status == 'pending') {
                        statusText = l10n.statusPending;
                      } else if (status == 'accepted') {
                        statusText = l10n.statusAccepted;
                      } else {
                        statusText = l10n.statusDeclined;
                      }

                      return Card(
                        child: ListTile(
                          title: Text(l10n.invitationTo(toUsername)),
                          subtitle: Text(l10n.sessionStatusLabel(statusText)),
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
    final l10n = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    final isCurrentUser = authService.currentUser?.id == player['id'];
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(player['username'] ?? l10n.unknownPlayerName),
      subtitle: Text(l10n.noTeam),
      trailing: (isMapOwner || isCurrentUser)
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  hint: Text(l10n.assignTeamHint),
                  onChanged: (teamId) {
                    if (teamId != null && mapId != null) {
                      teamService.assignPlayerToTeam(
                          player['id'], teamId, mapId);
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
                if (isMapOwner && !isCurrentUser)
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.red),
                  tooltip: l10n.kickPlayerTooltip,
                  onPressed: () => kickPlayer(player['id'], player['username']),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildTeamPlayerTile(
      Map<String, dynamic> player,
      int teamId,
      String teamName,
      TeamService teamService,
      int? mapId,
      List<dynamic> teams) {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    final isCurrentUser = authService.currentUser?.id == player['id'];
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.blue,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(player['username'] ?? l10n.unknownPlayerName),
      trailing: (isMapOwner || isCurrentUser)
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.group_remove),
                  tooltip: l10n.removeFromTeamTooltip,
                  onPressed: () {
                    if (mapId != null) {
                      teamService.removePlayerFromTeam(player['id'], mapId);
                    }
                  },
                ),
                if (isMapOwner && !isCurrentUser)
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.red),
                  tooltip: l10n.kickPlayerTooltip,
                  onPressed: () => kickPlayer(player['id'], player['username']),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildTeamsTab(
      TeamService teamService, GameStateService gameStateService) {
    final l10n = AppLocalizations.of(context)!;
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
              Text(l10n.teams, style: Theme.of(context).textTheme.titleLarge),
              if (isMapOwner)
                ElevatedButton.icon(
                  onPressed: () {
                    final nameController = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.createTeam),
                        content: TextField(
                          controller: nameController,
                          decoration: InputDecoration(labelText: l10n.teamName),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(l10n.cancel),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (nameController.text.isNotEmpty) {
                                teamService.createTeam(nameController.text);
                                Navigator.of(context).pop();
                              }
                            },
                            child: Text(l10n.create),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.newTeamButton),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ Liste scrollable dans Expanded dans Column (et plus dans Row)
          Expanded(
            child: (teams.isEmpty && unassignedPlayers.isEmpty)
                ? Center(
                    child: Text(
                      l10n.noTeamsCreated,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView(
                    children: [
                      if (unassignedPlayers.isNotEmpty) ...[
                        Text(l10n.unassignedPlayersLabel,
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
                  title: Text(l10n.saveConfigurationDialogTitle),
                  content: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.configurationNameLabel,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          teamService.saveCurrentTeamConfiguration(
                              nameController.text);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.configurationSavedSuccess),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.save),
            label: Text(l10n.saveConfigurationButton),
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ExpansionTile(
        title: Row(
          children: [
            Text(team.name),
            const SizedBox(width: 8),
            if (isMapOwner) ...[
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                tooltip: l10n.edit,
                onPressed: () {
                  final nameController = TextEditingController(text: team.name);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.renameTeamDialogTitle),
                      content: TextField(
                        controller: nameController,
                        decoration:
                            InputDecoration(labelText: l10n.newTeamNameLabel),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.cancel),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (nameController.text.isNotEmpty) {
                              teamService.renameTeam(
                                  team.id, nameController.text);
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(l10n.renameButton),
                        ),
                      ],
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 16),
                tooltip: l10n.delete,
                onPressed: () {
                  teamService.deleteTeam(team.id);
                },
              ),
            ],
          ],
        ),
        subtitle: Text(l10n.playersCountSuffix(team.players.length)),
        children: [
          ...team.players.map(
            (player) => _buildTeamPlayerTile(
                player, team.id, team.name, teamService, mapId, allTeams),
          ),
          const Divider(),
          if (isMapOwner)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.addPlayersToTeamDialogTitle),
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
                              title: Text(
                                  player['username'] ?? l10n.unknownPlayerName),
                              trailing: isInTeam
                                  ? Text(l10n.alreadyInTeamLabel)
                                  : ElevatedButton(
                                      onPressed: () {
                                        if (mapId != null) {
                                          teamService.assignPlayerToTeam(
                                              player['id'], team.id, mapId);
                                          Navigator.of(context).pop();
                                        }
                                      },
                                      child: Text(l10n.addButton),
                                    ),
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.ok), // ou l10n.closeButton si créé
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: Text(l10n.addPlayersToTeamDialogTitle),
              ),
            ),
        ],
      ),
    );
  }
}
