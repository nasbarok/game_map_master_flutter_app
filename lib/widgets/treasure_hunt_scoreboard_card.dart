import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/scenario/scenario_dto.dart';
import '../models/scenario/treasure_hunt/treasure_hunt_score.dart';

class TreasureHuntScoreboardCard extends StatelessWidget {
  final TreasureHuntScoreboard scoreboard;
  final int? currentUserId;
  final int? currentTeamId;
  final Map<int, Color> teamColors;
  final ScenarioDTO? scenarioDTO;

  const TreasureHuntScoreboardCard({
    Key? key,
    required this.scoreboard,
    this.currentUserId,
    this.currentTeamId,
    required this.teamColors,
    required this.scenarioDTO,
  }) : super(key: key);

  int _totalPoints() {
    return scoreboard.individualScores.fold(0, (sum, s) => sum + s.score);
  }

  int _totalTreasuresFound() {
    return scoreboard.individualScores.fold(0, (sum, s) => sum + s.treasuresFound);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(l10n),
            const SizedBox(height: 12),
            if (scoreboard.teamScores.isNotEmpty) _buildTeamRanking(l10n),
            const SizedBox(height: 12),
            _buildIndividualRanking(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final treasure = scenarioDTO?.treasureHuntScenario;
    final scenario = scenarioDTO?.scenario;

    final symbol = treasure?.defaultSymbol ?? '🏆';
    final total = treasure?.totalTreasures ?? 0;
    final found = _totalTreasuresFound();
    final totalPoints = _totalPoints();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                scenario?.name ?? l10n.unknownScenario,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (scoreboard.scoresLocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(l10n.locked, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.scenarioType(
            scenario?.type == 'treasure_hunt' ? l10n.treasureHunt : (scenario?.type ?? l10n.unknown)
          ),
          style: const TextStyle(color: Colors.grey),
        ),
        if (scenario?.description != null && scenario!.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              scenario.description!,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          l10n.qrCodesFound(found, totalPoints, symbol, total),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[700]),
        ),
      ],
    );
  }

  Widget _buildTeamRanking(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.teamRanking, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scoreboard.teamScores.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final team = scoreboard.teamScores[index];
              final isCurrent = team.teamId == currentTeamId;
              final color = teamColors[team.teamId] ?? Colors.grey;

              return Container(
                color: isCurrent ? color.withOpacity(0.1) : null,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  children: [
                    _buildPositionCircle(index),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: color,
                      child: Text(team.teamName?.substring(0, 1).toUpperCase() ?? 'T',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        team.teamName ?? l10n.teamName.replaceAll('{teamId}', team.teamId.toString()),
                        style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)
                      ),
                    ),
                    _buildScoreBadge(l10n.points(team.score.toString()), color),
                    const SizedBox(width: 8),
                    Text('${team.treasuresFound} 🏆', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIndividualRanking(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.individualRanking, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scoreboard.individualScores.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final player = scoreboard.individualScores[index];
              final isCurrent = player.userId == currentUserId;
              final color = teamColors[player.teamId] ?? Colors.grey;

              return Container(
                color: isCurrent ? Colors.blue.withOpacity(0.1) : null,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  children: [
                    _buildPositionCircle(index),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: color,
                      radius: 12,
                      child: Text(player.username?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.username ?? l10n.playerName(player.userId.toString()),
                            style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)
                          ),
                          if (player.teamName != null)
                            Text(player.teamName!, style: TextStyle(fontSize: 12, color: color)),
                        ],
                      ),
                    ),
                    _buildScoreBadge(l10n.points(player.score.toString()), Colors.blue),
                    const SizedBox(width: 8),
                    Text('${player.treasuresFound} 🏆', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPositionCircle(int index) {
    final colors = [Colors.amber, Colors.grey.shade400, Colors.brown.shade300];
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: index < 3 ? colors[index] : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text('${index + 1}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: index < 3 ? Colors.white : Colors.black,
            )),
      ),
    );
  }

  Widget _buildScoreBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    );
  }
}
