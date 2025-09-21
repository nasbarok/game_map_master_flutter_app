import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/scenario/target_elimination/elimination.dart';

class EliminationFeedWidget extends StatelessWidget {
  final List<Elimination> eliminations;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const EliminationFeedWidget({
    Key? key,
    required this.eliminations,
    this.isLoading = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.recentEliminations,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: isLoading ? null : onRefresh,
                    tooltip: l10n.refreshFavorites,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (eliminations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    l10n.noRecentEliminations,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: eliminations.take(3).map((elimination) {
                  return _buildEliminationItem(context, elimination);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEliminationItem(BuildContext context, Elimination elimination) {
    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(context, elimination.eliminatedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Icône d'élimination
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.gps_fixed,
              size: 16,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(width: 12),
          
          // Contenu de l'élimination
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message principal
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: elimination.killerName ?? 'Joueur ${elimination.killerId}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: ' a éliminé ',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: elimination.victimName ?? 'Joueur ${elimination.victimId}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Informations supplémentaires
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Points
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${elimination.points} pts',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Équipes si applicable
                    if (elimination.killerTeamName != null && 
                        elimination.victimTeamName != null) ...[
                      Text(
                        '${elimination.killerTeamName} vs ${elimination.victimTeamName}',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    
                    // Timestamp
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }
}

