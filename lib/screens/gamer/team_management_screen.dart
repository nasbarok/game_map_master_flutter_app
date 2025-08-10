// lib/screens/gamer/team_management_screen.dart

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/team.dart';
import '../../services/team_service.dart';
import '../../services/game_state_service.dart';
import '../../services/auth_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

import '../../widgets/adaptive_background.dart';
import '../../widgets/options/cropped_logo_button.dart';

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
      final l10n = AppLocalizations.of(context)!;
      logger.d('❌ ${l10n.errorLoadingTeamsAlt}: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinTeam(int teamId) async {
    final l10n = AppLocalizations.of(context)!;
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
        if (!mounted) return;
        await _loadTeams();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.joinedTeamSuccessAlt),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger.d('❌ [TeamManagementScreen] ERREUR joinTeam: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorJoiningTeam(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTeamsTab(
    List<Team> teams,
    int? myTeamId,
    AppLocalizations l10n,
  ) {
    if (teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups, size: 80, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              l10n.noTeamsAvailableTitle,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noTeamsAvailableHostMessage,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        final isMyTeam = team.id == myTeamId;
        final List<Map<String, dynamic>> teamPlayers =
            (team.players as List?)?.cast<Map<String, dynamic>>() ?? const [];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.black.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              textTheme: Theme.of(context)
                  .textTheme
                  .apply(bodyColor: Colors.white, displayColor: Colors.white),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            child: ExpansionTile(
              key: PageStorageKey('team-${team.id}'),
              leading: CircleAvatar(
                backgroundColor: isMyTeam ? Colors.green : Colors.blue,
                child: Icon(isMyTeam ? Icons.check : Icons.group,
                    color: Colors.white),
              ),
              title: Text(
                team.name ?? l10n.noTeam,
                style: TextStyle(
                  fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                l10n.playersCountSuffix(teamPlayers.length),
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: isMyTeam
                  ? Chip(
                      label: Text(l10n.yourTeamChip),
                      backgroundColor: Colors.green,
                      labelStyle: const TextStyle(color: Colors.white),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : () => _joinTeam(team.id),
                      child: Text(l10n.joinButton,
                          style: const TextStyle(color: Colors.white)),
                    ),
              children: [
                for (final p in teamPlayers)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade300,
                      child: Text(
                        (p['username'] ?? '?').toString().isNotEmpty
                            ? (p['username'] as String)
                                .substring(0, 1)
                                .toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      (p['username'] ?? l10n.playersTab).toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    // si tu n'as pas de notion online/offline dans team.players, on n'affiche rien
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayersTab(
    List<Map<String, dynamic>> connectedPlayers,
    List<Team> teams,
    int? currentUserId,
    AppLocalizations l10n,
  ) {
    Team? _findTeamById(int? id) {
      if (id == null) return null;
      for (final t in teams) {
        if (t.id == id) return t;
      }
      return null;
    }

    if (connectedPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 80, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              l10n.noPlayerConnected,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(l10n.noPlayersConnectedMessage,
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: connectedPlayers.length,
      itemBuilder: (context, index) {
        final player = connectedPlayers[index];
        final bool isCurrentUser = player['id'] == currentUserId;
        final team = _findTeamById(player['teamId']);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.black.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: team != null ? Colors.blue : Colors.grey,
              child: Text(
                (player['username'] ?? '?').toString().isNotEmpty
                    ? (player['username'] as String)
                        .substring(0, 1)
                        .toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              (player['username'] ?? l10n.playersTab).toString(),
              style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      isCurrentUser ? FontWeight.bold : FontWeight.normal),
            ),
            subtitle: Text(
              team?.name ?? l10n.noTeam,
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: isCurrentUser
                ? Chip(
                    label: Text(l10n.youLabel),
                    backgroundColor: Colors.amber,
                    labelStyle: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamService = context.watch<TeamService>();
    final gameStateService = context.watch<GameStateService>();
    final teams = teamService.teams;
    final myTeamId = teamService.myTeamId;
    final connectedPlayers = gameStateService.connectedPlayersList;
    final authService = GetIt.I<AuthService>();
    final currentUserId = authService.currentUser?.id;

    return AdaptiveScaffold(
      gameBackgroundType: GameBackgroundType.menu,
      enableParallax: true,
      backgroundOpacity: 0.85,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 65,
        title: Text(
          l10n.teamManagementTitle,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.7),
              ),
            ],
          ),
        ),
        leadingWidth: 100,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 4),
            // ⬇️ Contraint la taille du logo pour éviter les débordements
            const SizedBox(
              width: 36,
              height: 36,
              child: CroppedLogoButton(),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: l10n.teams),
                Tab(text: l10n.playersTab),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTeams,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // onglet équipes
                  _buildTeamsTab(teams, myTeamId, l10n),
                  // onglet joueurs
                  _buildPlayersTab(
                    connectedPlayers.cast<Map<String, dynamic>>(),
                    teams,
                    currentUserId,
                    l10n,
                  ),
                ],
              ),
            ),
    );
  }
}
