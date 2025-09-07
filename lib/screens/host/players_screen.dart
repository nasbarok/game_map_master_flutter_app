import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/invitation.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../../services/invitation_service.dart';
import '../../services/team_service.dart';
import '../../services/api_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

import '../../widgets/common/invite_badge.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({Key? key, this.onGoToFieldTab}) : super(key: key);
  final VoidCallback? onGoToFieldTab;

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TeamService teamService;
  late GameStateService gameStateService;

  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  TabController? _tabController;
  bool _bootstrapped = false;

  bool _lastIsOpen = true; // pour détecter les changements d’ouverture

  int? getCurrentMapId(BuildContext context) {
    return context.watch<GameStateService>().selectedMap?.id;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final isOpen = context.read<GameStateService>().isTerrainOpen;
    final initialLen = isOpen ? 4 : 1;
    _recreateTabController(initialLen, initialIndex: 0);
    _lastIsOpen = isOpen;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    teamService = context.watch<TeamService>();
    gameStateService = context.watch<GameStateService>();

    final isOpen = gameStateService.isTerrainOpen;
    final newLength = isOpen ? 4 : 1;

    // 🔹 Bootstrap unique ici
    if (!_bootstrapped) {
      logger.d('🚀 PlayersScreen bootstrap (isOpen=$isOpen)');
      // Charger "envoyées" quoi qu’il arrive (ne fera rien si pas de fieldId côté service)
      context.read<InvitationService>().loadSentInvitations();
      logger.d('📤 loadSentInvitations() demandé au bootstrap');

      if (isOpen && gameStateService.selectedMap != null) {
        final mapId = gameStateService.selectedMap!.id!;
        logger.d('🌀 Chargement équipes + joueurs (bootstrap) mapId=$mapId');
        teamService.loadTeams(mapId);
        gameStateService.loadConnectedPlayers();
      } else {
        // Terrain fermé → on veut voir les reçues
        context.read<InvitationService>().loadReceivedInvitations();
        logger.d('📥 loadReceivedInvitations() demandé (terrain fermé)');
      }
      _bootstrapped = true;
    }

    // Si la longueur change (ouverture/fermeture), on RECRÉE proprement
    if (_tabController == null ||
        _lastIsOpen != isOpen ||
        _tabController!.length != newLength) {
      final currentIndex = _tabController?.index ?? 0;

      int mappedIndex;
      if (isOpen) {
        // fermeture→ouverture : Invitations était 0 devient 1
        mappedIndex = (currentIndex == 0) ? 1 : currentIndex;
        if (mappedIndex >= newLength) mappedIndex = newLength - 1;
      } else {
        // ouverture→fermeture : on retombe sur l’onglet 0 (Invitations reçues)
        mappedIndex = 0;
      }

      _recreateTabController(newLength, initialIndex: mappedIndex);
      _lastIsOpen = isOpen;
    }
  }

  void _recreateTabController(int length, {int initialIndex = 0}) {
    // Nettoyer l'ancien controller AVANT d'en créer un nouveau
    if (_tabController != null) {
      _tabController!.removeListener(_tabListener);
      _tabController!.dispose();
    }

    _tabController = TabController(
      length: length,
      vsync: this,
      initialIndex: initialIndex.clamp(0, length - 1),
    );
    _tabController!.addListener(_tabListener);

    // Optionnel mais confortable pour rebâtir TabBar/TabBarView
    if (mounted) setState(() {});
  }

  void _tabListener() {
    if (_tabController!.indexIsChanging) return;

    final isOpen = context.read<GameStateService>().isTerrainOpen;
    final invitationsTabIndex = isOpen ? 1 : 0;
    final teamsTabIndex = isOpen ? 2 : null;

    logger.d('🧭 PlayersScreen: tab=${_tabController!.index} (isOpen=$isOpen)');

    if (_tabController!.index == invitationsTabIndex) {
      logger
          .d('📩 PlayersScreen → onglet Invitations sélectionné (sentInvites)');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<InvitationService>().loadSentInvitations();
      });
    }

    if (teamsTabIndex != null && _tabController!.index == teamsTabIndex) {
      logger.d(
          '👥 PlayersScreen → onglet Équipes sélectionné → refresh teams & players');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final gs = context.read<GameStateService>();
        final ts = context.read<TeamService>();
        final mapId = gs.selectedMap?.id;
        gs.loadConnectedPlayers();
        if (mapId != null) ts.loadTeams(mapId);
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    final l10n = AppLocalizations.of(context)!;
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
          content: Text(l10n.genericError(e)),
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
    final l10n = AppLocalizations.of(context)!;
    try {
      invitationService.sendInvitation(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invitationSentTo(username)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.genericError(e)),
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
      final l10n = AppLocalizations.of(context)!;

      if (fieldId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noFieldsAvailable),
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
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.watch<GameStateService>();
    final invitationService = context.watch<InvitationService>();

    final isOpen = gameStateService.isTerrainOpen;
    if (!isOpen) {
      return _buildNoOpenFieldBody();
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: null,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.searchTab),
            Tab(text: l10n.invitations),
            Tab(text: l10n.teams),
            Tab(text: l10n.favorites),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildInvitationsTab(invitationService),
          _buildTeamsTab(teamService, gameStateService),
          _buildFavoritesTab(),
        ],
      ),
      // FAB contextuel, visible uniquement sur l’onglet Teams
      floatingActionButton: _tabController == null
          ? null
          : AnimatedBuilder(
              animation: _tabController!,
              builder: (_, __) {
                final fab = _buildPlayersFab(); // <-- on APPELLE la méthode
                return fab ?? const SizedBox.shrink(); // <-- on gère le null
              },
            ),
    );
  }

  Widget _buildNoOpenFieldBody() {
    final l10n = AppLocalizations.of(context)!;
    final invitationService = context.watch<InvitationService>();
    final received = invitationService.receivedInvitations;
    final pending = invitationService.receivedPendingInvitations;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Icon(Icons.people, size: 80, color: Colors.grey.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(
          l10n.playerManagementUnavailableTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.openField,
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: widget.onGoToFieldTab, // ← si tu as passé le callback
          icon: const Icon(Icons.dashboard),
          label: Text(l10n.goToFieldTabButton),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.receivedInvitations,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            if (pending.isNotEmpty) InviteBadge(count: pending.length),
          ],
        ),
        const SizedBox(height: 12),
        if (received.isEmpty) ...[
          const Icon(Icons.mail_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 8),
          Text(l10n.noInvitations, style: const TextStyle(color: Colors.grey)),
        ] else ...[
          for (final inv in received)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        l10n.invitationFrom(
                            inv.senderUsername),
                      ),
                      subtitle: Text(
                        l10n.mapLabelShort(inv.fieldName),
                      ),
                    ),
                    if (inv.isPending)
                      ButtonBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => context
                                .read<InvitationService>()
                                .respondToInvitation(context, inv.id, false),
                            child: Text(l10n.declineInvitation),
                          ),
                          ElevatedButton(
                            onPressed: () => context
                                .read<InvitationService>()
                                .respondToInvitation(context, inv.id, true),
                            child: Text(l10n.acceptInvitation),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            l10n.favoritesTab,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Text(
                l10n.favoritesComingSoon,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
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
                                ? _buildInviteButton(
                                    user['id'], user['username'])
                                : const SizedBox.shrink(),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteButton(int userId, String username) {
    final l10n = AppLocalizations.of(context)!;
    final invitationService = context.watch<InvitationService>();

    // Vérifier si une invitation pending existe déjà
    final hasPendingInvitation =
        invitationService.sentInvitationsOld.any((inv) {
      final json = inv.toJson();
      final payload = json['payload'] ?? {};
      return payload['targetUserId'] == userId && json['status'] == 'pending';
    });

    if (hasPendingInvitation) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          l10n.alreadyInvited,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => _sendInvitation(userId, username),
      child: Text(l10n.inviteButton),
    );
  }

  Widget _buildInvitationsTab(InvitationService invitationService) {
    final l10n = AppLocalizations.of(context)!;
    final sentInvitations = invitationService.sentInvitations;
    final sentPendingCount = context.select<InvitationService, int>(
      (svc) => svc.sentInvitations.where((i) => i.isPending).length,
    );
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.invitationsSentTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => invitationService.loadSentInvitations(),
                tooltip: l10n.refreshTooltip,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => invitationService.loadSentInvitations(),
              child: sentInvitations.isEmpty
                  // Important: un scrollable même vide pour pouvoir "pull-to-refresh"
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  const Icon(Icons.mail_outline,
                                      size: 64, color: Colors.grey),
                                  if (sentPendingCount > 0)
                                    Positioned(
                                      right: -6,
                                      top: -6,
                                      child:
                                          InviteBadge(count: sentPendingCount),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noInvitationsSent,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: sentInvitations.length,
                      itemBuilder: (context, index) {
                        final invitation = sentInvitations[index];
                        return _buildInvitationCard(
                            invitation, invitationService);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(
      Invitation invitation, InvitationService invitationService) {
    final l10n = AppLocalizations.of(context)!;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (invitation.status) {
      case 'PENDING':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = l10n.invitationPending;
        break;
      case 'ACCEPTED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = l10n.invitationAccepted;
        break;
      case 'DECLINED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = l10n.invitationDeclined;
        break;
      case 'CANCELED':
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        statusText = l10n.invitationCanceled;
        break;
      case 'EXPIRED':
        statusColor = Colors.grey.shade400;
        statusIcon = Icons.access_time;
        statusText = l10n.invitationExpired;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = invitation.status;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(statusIcon, color: Colors.white, size: 20),
        ),
        title: Text(l10n.invitationTo(invitation.targetUsername)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(statusText,
                style:
                    TextStyle(color: statusColor, fontWeight: FontWeight.w500)),
            Text(
              _formatTimestamp(invitation.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: invitation.isPending
            ? TextButton(
                onPressed: () =>
                    _cancelInvitation(invitation.id, invitationService),
                child: Text(l10n.cancelInvitation,
                    style: TextStyle(color: Colors.red)),
              )
            : null,
      ),
    );
  }

  Future<void> _cancelInvitation(
      int invitationId, InvitationService invitationService) async {
    try {
      await invitationService.cancelInvitation(invitationId);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cancelInvitation)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    final l10n = AppLocalizations.of(context)!;
    if (difference.inMinutes < 1) {
      return l10n.timeJustNow;
    } else if (difference.inHours < 1) {
      return l10n.minutesAgo(difference.inMinutes);
    } else if (difference.inDays < 1) {
      return l10n.hoursAgo(difference.inHours);
    } else {
      return l10n.shortDate(timestamp.day, timestamp.month);
    }
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
                    onPressed: () =>
                        kickPlayer(player['id'], player['username']),
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
                    onPressed: () =>
                        kickPlayer(player['id'], player['username']),
                  ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildTeamsTab(
    TeamService teamService,
    GameStateService gameStateService,
  ) {
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
          // ✅ Titre + bouton "Nouveau"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.teams, style: Theme.of(context).textTheme.titleLarge),
              if (isMapOwner)
                ElevatedButton.icon(
                  onPressed: _createTeamDialog,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.newTeamButton), // texte uniformisé
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ Liste scrollable
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
                        Text(
                          l10n.unassignedPlayersLabel,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
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
          // ❌ plus de bouton "save configuration" ici
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

  Widget? _buildPlayersFab() {
    final l10n = AppLocalizations.of(context)!;
    final isOpen = context.watch<GameStateService>().isTerrainOpen;

    if (!isOpen || !isMapOwner || _tabController == null) return null;

    // Teams = index 2 quand isOpen == true
    final teamsIndex = 2;
    if (_tabController!.index != teamsIndex) return null;

    return FloatingActionButton.extended(
      heroTag: 'players-teams-fab',
      onPressed: _createTeamDialog,
      // ↩︎ même action que “Nouveau”
      icon: const Icon(Icons.add),
      label: Text(l10n.newTeamButton),
      // ↩︎ texte uniformisé
      tooltip: l10n.newTeamButton,
    );
  }

  Future<void> _createTeamDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createTeam),
        // ou l10n.newTeamButton si tu préfères
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
                context.read<TeamService>().createTeam(nameController.text);
                Navigator.of(context).pop();
              }
            },
            child: Text(l10n.create), // texte uniforme côté validation
          ),
        ],
      ),
    );
  }
}
