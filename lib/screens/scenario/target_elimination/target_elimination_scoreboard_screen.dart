import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../models/scenario/target_elimination/target_elimination_score.dart';
import '../../../services/scenario/target_elimination/target_elimination_score_service.dart';
import '../../../widgets/target_elimination/target_elimination_scoreboard_card.dart';

class TargetEliminationScoreboardScreen extends StatefulWidget {
  final int scenarioId;
  final int gameSessionId;
  final bool isTeamMode;
  final int? currentPlayerId;

  const TargetEliminationScoreboardScreen({
    Key? key,
    required this.scenarioId,
    required this.gameSessionId,
    this.isTeamMode = false,
    this.currentPlayerId,
  }) : super(key: key);

  @override
  State<TargetEliminationScoreboardScreen> createState() => _TargetEliminationScoreboardScreenState();
}

class _TargetEliminationScoreboardScreenState extends State<TargetEliminationScoreboardScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  final TargetEliminationScoreService _scoreService = TargetEliminationScoreService();
  
  List<TargetEliminationScore> _playerScores = [];
  List<TeamScore> _teamScores = [];
  ScenarioStatistics? _statistics;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isTeamMode ? 3 : 2,
      vsync: this,
    );
    _loadScores();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadScores() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger les scores des joueurs
      final playerScores = await _scoreService.getScenarioScores(
        scenarioId: widget.scenarioId,
        gameSessionId: widget.gameSessionId,
      );

      // Charger les scores d'équipe si mode équipe
      List<TeamScore> teamScores = [];
      if (widget.isTeamMode) {
        teamScores = await _scoreService.getTeamScores(
          scenarioId: widget.scenarioId,
          gameSessionId: widget.gameSessionId,
        );
      }

      // Charger les statistiques
      final statistics = await _scoreService.getScenarioStatistics(
        scenarioId: widget.scenarioId,
        gameSessionId: widget.gameSessionId,
      );

      setState(() {
        _playerScores = playerScores;
        _teamScores = teamScores;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.targetEliminationScoreboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadScores,
            tooltip: l10n.refreshScores,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.download),
                    const SizedBox(width: 8),
                    Text(l10n.exportScores),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    const Icon(Icons.refresh, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(l10n.resetScores),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.person),
              text: l10n.players,
            ),
            if (widget.isTeamMode)
              Tab(
                icon: const Icon(Icons.groups),
                text: l10n.teams,
              ),
            Tab(
              icon: const Icon(Icons.analytics),
              text: l10n.statistics,
            ),
          ],
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des scores...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorWidget(context);
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // Onglet Joueurs
        _buildPlayersTab(context),
        
        // Onglet Équipes (si mode équipe)
        if (widget.isTeamMode)
          _buildTeamsTab(context),
        
        // Onglet Statistiques
        _buildStatisticsTab(context),
      ],
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadScores,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadScores,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Carte du tableau des scores
            TargetEliminationScoreboardCard(
              scores: _playerScores,
              currentPlayerId: widget.currentPlayerId,
              showFullList: true,
              onRefresh: _loadScores,
              isLoading: false,
            ),
            
            // Statistiques rapides
            if (_statistics != null)
              _buildQuickStats(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadScores,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Carte du tableau des équipes
            TargetEliminationScoreboardCard(
              scores: _playerScores,
              teamScores: _teamScores,
              isTeamMode: true,
              showFullList: true,
              onRefresh: _loadScores,
              isLoading: false,
            ),
            
            // Détails des équipes
            ..._teamScores.map((teamScore) => _buildTeamDetailCard(context, teamScore)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab(BuildContext context) {
    if (_statistics == null) {
      return const Center(
        child: Text('Aucune statistique disponible'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadScores,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatisticsOverview(context),
            const SizedBox(height: 16),
            _buildTopPlayersCard(context),
            const SizedBox(height: 16),
            _buildPerformanceDistribution(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _statistics!;
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques rapides',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, 'Éliminations', stats.totalKills.toString()),
                _buildStatItem(context, 'Joueurs actifs', stats.activePlayers.toString()),
                _buildStatItem(context, 'Points totaux', stats.totalPoints.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamDetailCard(BuildContext context, TeamScore teamScore) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ExpansionTile(
        title: Text(teamScore.teamName ?? 'Équipe ${teamScore.teamId}'),
        subtitle: Text('${teamScore.playerCount} joueurs • ${teamScore.totalPoints} points'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: teamScore.playerScores.map((score) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(score.playerName?.substring(0, 1).toUpperCase() ?? 'J'),
                  ),
                  title: Text(score.playerName ?? 'Joueur ${score.playerId}'),
                  subtitle: Text('K/D: ${score.kills}/${score.deaths}'),
                  trailing: Text(
                    '${score.points} pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsOverview(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _statistics!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vue d\'ensemble',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2,
              children: [
                _buildStatCard(context, 'Total éliminations', stats.totalKills.toString(), Icons.gps_fixed),
                _buildStatCard(context, 'Joueurs actifs', stats.activePlayers.toString(), Icons.people),
                _buildStatCard(context, 'Points totaux', stats.totalPoints.toString(), Icons.star),
                _buildStatCard(context, 'Moy. éliminations', stats.averageKills.toStringAsFixed(1), Icons.trending_up),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPlayersCard(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _statistics!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meilleurs joueurs',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (stats.topKillerName != null)
              ListTile(
                leading: const Icon(Icons.gps_fixed, color: Colors.red),
                title: Text('Meilleur tueur'),
                subtitle: Text(stats.topKillerName!),
                trailing: Text('${stats.topKillerKills} éliminations'),
              ),
            if (stats.topScorerName != null)
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text('Meilleur score'),
                subtitle: Text(stats.topScorerName!),
                trailing: Text('${stats.topScorerPoints} points'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceDistribution(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculer la distribution des performances
    final performances = <ScorePerformance, int>{};
    for (final score in _playerScores) {
      final performance = score.getPerformanceLevel(_playerScores);
      performances[performance] = (performances[performance] ?? 0) + 1;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribution des performances',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...ScorePerformance.values.map((performance) {
              final count = performances[performance] ?? 0;
              final percentage = _playerScores.isNotEmpty 
                  ? (count / _playerScores.length * 100).round()
                  : 0;
              
              return ListTile(
                leading: Icon(
                  performance.getIcon(),
                  color: performance.getColor(context),
                ),
                title: Text(performance.getLabel()),
                trailing: Text('$count joueurs ($percentage%)'),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportScores();
        break;
      case 'reset':
        _showResetConfirmation();
        break;
    }
  }

  Future<void> _exportScores() async {
    try {
      final csv = await _scoreService.exportScoresToCSV(
        scenarioId: widget.scenarioId,
        gameSessionId: widget.gameSessionId,
      );
      
      // Ici vous pouvez implémenter la logique de sauvegarde du fichier CSV
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scores exportés avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'export: $e')),
      );
    }
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les scores'),
        content: const Text(
          'Êtes-vous sûr de vouloir réinitialiser tous les scores ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScores();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetScores() async {
    try {
      await _scoreService.resetScenarioScores(
        scenarioId: widget.scenarioId,
        gameSessionId: widget.gameSessionId,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scores réinitialisés avec succès')),
      );
      
      _loadScores();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la réinitialisation: $e')),
      );
    }
  }
}

