import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/scenario/target_elimination/target_elimination_scenario.dart';

class EliminationHudWidget extends StatefulWidget {
  final TargetEliminationScenario scenario;
  final PlayerTarget? playerTarget;

  const EliminationHudWidget({
    Key? key,
    required this.scenario,
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
    _scoreService = context.read<TargetEliminationScoreService>();
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
            _playerScore?.getKillDeathRatio().toStringAsFixed(2) ?? '0.00',
            Colors.blue,
            Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
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
    final message = widget.scenario.announcementTemplate
        .replaceAll('{killer}', elimination.killer.username)
        .replaceAll('{victim}', elimination.victim.username)
        .replaceAll('{killerTeam}', elimination.killerTeam?.name ?? '')
        .replaceAll('{victimTeam}', elimination.victimTeam?.name ?? '');

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
        builder: (context) => TargetEliminationScannerScreen(
          scenario: widget.scenario,
        ),
      ),
    );
  }

  void _showScoreboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TargetEliminationScoreboardScreen(
          scenario: widget.scenario,
        ),
      ),
    );
  }
}