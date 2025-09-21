import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/scenario/target_elimination/elimination.dart';
import '../../models/scenario/target_elimination/player_target.dart';
import '../../models/scenario/target_elimination/target_elimination_scenario.dart';
import '../../models/scenario/target_elimination/target_elimination_score.dart';
import '../../screens/scenario/target_elimination/player_target_display_screen.dart';
import '../../screens/scenario/target_elimination/target_elimination_scanner_screen.dart';
import '../../screens/scenario/target_elimination/target_elimination_scoreboard_screen.dart';
import '../../services/scenario/target_elimination/target_elimination_score_service.dart';
import '../../services/team_service.dart';

class EliminationHudWidget extends StatefulWidget {
  final TargetEliminationScenario scenario;
  final int gameSessionId;
  final int currentPlayerId;
  final PlayerTarget? playerTarget;

  const EliminationHudWidget({
    Key? key,
    required this.scenario,
    required this.gameSessionId,
    required this.currentPlayerId,
    this.playerTarget,
  }) : super(key: key);

  @override
  _EliminationHudWidgetState createState() => _EliminationHudWidgetState();
}

class _EliminationHudWidgetState extends State<EliminationHudWidget> {
  late TargetEliminationScoreService _scoreService;
  TargetEliminationScore? _playerScore;
  List<Elimination> _recentEliminations = [];

  @override
  void initState() {
    super.initState();
    _scoreService =
        Provider.of<TargetEliminationScoreService>(context, listen: false);
    _loadPlayerScore();
    _loadRecentEliminations();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPlayerBanner(),
          SizedBox(height: 16),
          _buildStatsRow(),
          SizedBox(height: 16),
          _buildRecentEliminationsFeed(),
          SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildPlayerBanner() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.gps_fixed, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.playerTarget != null
                  ? l10n.youAreTargetNumber(widget.playerTarget!.targetNumber)
                  : l10n.waitingForTargetAssignment,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          if (widget.playerTarget != null)
            IconButton(
              icon: Icon(Icons.qr_code, color: Colors.red),
              onPressed: _showMyQRCode,
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            l10n.kills,
            _playerScore?.kills.toString() ?? '0',
            Colors.green,
            Icons.whatshot,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            l10n.deaths,
            _playerScore?.deaths.toString() ?? '0',
            Colors.red,
            Icons.close,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'K/D',
            _playerScore?.killDeathRatio.toStringAsFixed(2) ?? '0.00',
            Colors.blue,
            Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEliminationsFeed() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recentEliminations,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8),
          Expanded(
            child: _recentEliminations.isEmpty
                ? Center(
                    child: Text(
                      l10n.noRecentEliminations,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _recentEliminations.length,
                    itemBuilder: (context, index) {
                      final elimination = _recentEliminations[index];
                      return _buildEliminationItem(elimination);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEliminationItem(Elimination elimination) {
    final l10n = AppLocalizations.of(context)!;
    final message = widget.scenario.announcementTemplate
        .replaceAll('{killer}', elimination.killerName!)
        .replaceAll('{victim}', elimination.victimName!)
        .replaceAll('{killerTeam}', elimination.killerTeamName ?? l10n.noTeam)
        .replaceAll('{victimTeam}', elimination.victimTeamName ?? l10n.noTeam);

    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: FloatingActionButton.extended(
            onPressed: _scanQRCode,
            icon: Icon(Icons.qr_code_scanner),
            label: Text(l10n.scanQRCode),
            backgroundColor: Colors.red,
          ),
        ),
        SizedBox(width: 16),
        FloatingActionButton(
          onPressed: _showScoreboard,
          child: Icon(Icons.leaderboard),
          backgroundColor: Colors.blue,
        ),
      ],
    );
  }

  void _loadPlayerScore() async {
    // Charger le score du joueur
  }

  void _loadRecentEliminations() async {
    // Charger les 3 dernières éliminations
  }

  void _showMyQRCode() {
    if (widget.playerTarget != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerTargetDisplayScreen(
            playerTarget: widget.playerTarget!,
          ),
        ),
      );
    }
  }

  void _scanQRCode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TargetEliminationScannerScreen(
          scenarioId: widget.scenario.id!,
          // adapte si le champ est différent (ex: scenario.scenarioId)
          gameSessionId: widget.gameSessionId,
          currentPlayerId: widget.currentPlayerId,
        ),
      ),
    );
  }

  void _showScoreboard() {
    final teamService = context.watch()<TeamService>();
    // Règle métier : mode équipes actif si AU MOINS 2 équipes ont ≥ 2 joueurs
    final validTeamsCount =
        teamService.teams.where((t) => (t.players.length) >= 2).length;
    final bool isTeamMode = validTeamsCount >= 2;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TargetEliminationScoreboardScreen(
          scenarioId: widget.scenario.id!,
          // int
          gameSessionId: widget.gameSessionId,
          // int
          currentPlayerId: widget.currentPlayerId,
          // pour surligner le joueur courant
          isTeamMode: isTeamMode, // active l’onglet Équipes
        ),
      ),
    );
  }
}
