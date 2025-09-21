import 'package:flutter/material.dart';
import '../../../models/scenario/target_elimination/target_elimination_score.dart';
import '../../generated/l10n/app_localizations.dart';

class TargetEliminationScoreboardCard extends StatelessWidget {
  final List<TargetEliminationScore> scores;
  final bool isTeamMode;
  final List<TeamScore>? teamScores;
  final int? currentPlayerId;
  final bool showFullList;
  final VoidCallback? onViewAll;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const TargetEliminationScoreboardCard({
    Key? key,
    required this.scores,
    this.isTeamMode = false,
    this.teamScores,
    this.currentPlayerId,
    this.showFullList = false,
    this.onViewAll,
    this.onRefresh,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildHeader(context),
          
          // Contenu
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (isTeamMode && teamScores != null)
            _buildTeamScoreboard(context)
          else
            _buildPlayerScoreboard(context),
          
          // Actions en bas
          if (!showFullList && scores.length > 3)
            _buildViewAllButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            Icons.leaderboard,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isTeamMode ? l10n.teamScoreboard : l10n.playerScoreboard,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: theme.colorScheme.primary,
              ),
              onPressed: isLoading ? null : onRefresh,
              tooltip: l10n.refreshScores,
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerScoreboard(BuildContext context) {
    final theme = Theme.of(context);
    final displayScores = showFullList ? scores : scores.take(5).toList();

    if (displayScores.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'Aucun score disponible',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // En-tête du tableau
        _buildScoreboardHeader(context),
        
        // Liste des scores
        ...displayScores.asMap().entries.map((entry) {
          final index = entry.key;
          final score = entry.value;
          final rank = index + 1;
          final isCurrentPlayer = currentPlayerId != null && 
                                 score.playerId == currentPlayerId;
          
          return _buildPlayerScoreRow(context, score, rank, isCurrentPlayer);
        }).toList(),
      ],
    );
  }

  Widget _buildTeamScoreboard(BuildContext context) {
    final theme = Theme.of(context);
    
    if (teamScores == null || teamScores!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'Aucun score d\'équipe disponible',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    // Trier les équipes par points totaux
    final sortedTeams = List<TeamScore>.from(teamScores!)
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    return Column(
      children: [
        // En-tête du tableau équipes
        _buildTeamScoreboardHeader(context),
        
        // Liste des équipes
        ...sortedTeams.asMap().entries.map((entry) {
          final index = entry.key;
          final teamScore = entry.value;
          final rank = index + 1;
          
          return _buildTeamScoreRow(context, teamScore, rank);
        }).toList(),
      ],
    );
  }

  Widget _buildScoreboardHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              'Rang',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Joueur',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              'K/D',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              'Points',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScoreboardHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              'Rang',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Équipe',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              'K/D',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              'Points',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScoreRow(BuildContext context, TargetEliminationScore score, 
                             int rank, bool isCurrentPlayer) {
    final theme = Theme.of(context);
    final performance = score.getPerformanceLevel(scores);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentPlayer 
          ? theme.colorScheme.primaryContainer.withOpacity(0.2)
          : null,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Rang avec médaille
          SizedBox(
            width: 40,
            child: Row(
              children: [
                if (rank <= 3)
                  Icon(
                    rank == 1 ? Icons.emoji_events : 
                    rank == 2 ? Icons.military_tech : Icons.workspace_premium,
                    color: rank == 1 ? Colors.amber :
                           rank == 2 ? Colors.grey[400] : Colors.brown[300],
                    size: 16,
                  )
                else
                  Text(
                    '$rank',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          
          // Nom du joueur avec indicateur de performance
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        score.playerName ?? 'Joueur ${score.playerId}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (score.teamName != null) ...[
                        Text(
                          score.teamName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  performance.getIcon(),
                  color: performance.getColor(context),
                  size: 14,
                ),
              ],
            ),
          ),
          
          // K/D Ratio
          SizedBox(
            width: 50,
            child: Text(
              '${score.kills}/${score.deaths}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
          
          // Points
          SizedBox(
            width: 60,
            child: Text(
              score.points.toString(),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScoreRow(BuildContext context, TeamScore teamScore, int rank) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Rang avec médaille
          SizedBox(
            width: 40,
            child: Row(
              children: [
                if (rank <= 3)
                  Icon(
                    rank == 1 ? Icons.emoji_events : 
                    rank == 2 ? Icons.military_tech : Icons.workspace_premium,
                    color: rank == 1 ? Colors.amber :
                           rank == 2 ? Colors.grey[400] : Colors.brown[300],
                    size: 16,
                  )
                else
                  Text(
                    '$rank',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          
          // Nom de l'équipe
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamScore.teamName ?? 'Équipe ${teamScore.teamId}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${teamScore.playerCount} joueur${teamScore.playerCount > 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // K/D Ratio de l'équipe
          SizedBox(
            width: 50,
            child: Text(
              '${teamScore.totalKills}/${teamScore.totalDeaths}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
          
          // Points totaux
          SizedBox(
            width: 60,
            child: Text(
              teamScore.totalPoints.toString(),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: TextButton.icon(
          onPressed: onViewAll,
          icon: const Icon(Icons.expand_more),
          label: Text(l10n.viewAllScores),
        ),
      ),
    );
  }
}

