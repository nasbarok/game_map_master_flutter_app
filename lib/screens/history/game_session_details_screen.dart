import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/history_service.dart';
import 'field_sessions_screen.dart';
import 'game_replay_screen.dart';

class GameSessionDetailsScreen extends StatefulWidget {
  final int gameSessionId;
  final int? sessionIndex; // <-- facultatif

  const GameSessionDetailsScreen({
    Key? key,
    required this.gameSessionId,
    this.sessionIndex,
  }) : super(key: key);

  @override
  _GameSessionDetailsScreenState createState() =>
      _GameSessionDetailsScreenState();
}

class _GameSessionDetailsScreenState extends State<GameSessionDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _gameSessionData;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadGameSessionDetails();
  }

  Future<void> _loadGameSessionDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final historyService =
          Provider.of<HistoryService>(context, listen: false);

      // Charger les détails de la session de jeu
      final gameSession =
          await historyService.getGameSessionById(widget.gameSessionId);

      // Charger les statistiques de la session de jeu
      final statistics =
          await historyService.getGameSessionStatistics(widget.gameSessionId);

      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _gameSessionData = {
          'id': gameSession.id,
          'fieldName': gameSession.field?.name,
          'gameMap': gameSession.gameMap,
          'fieldId': gameSession.field?.id,
          'active': gameSession.active,
          'startTime': gameSession.startTime,
          'endTime': gameSession.endTime,
        };
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.errorLoadingData(e.toString());
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sessionIndex != null
            ? l10n.sessionTitleWithIndex((widget.sessionIndex! + 1).toString())
            : _gameSessionData != null && widget.sessionIndex != null
                ? l10n.sessionTitleWithIndex((widget.sessionIndex! + 1).toString())
                : l10n.sessionDetailsScreenTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child:
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _gameSessionData == null
                  ? Center(child: Text(l10n.noSessionFound))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSessionInfoCard(),
                          if (_statistics != null &&
                              _statistics!['scenarios'] != null)
                            ..._buildScenariosSection(
                                _statistics!['scenarios']),
                        ],
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadGameSessionDetails,
        tooltip: l10n.refreshTooltip,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSessionInfoCard() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.sessionTitleWithIndex((widget.sessionIndex! + 1).toString()),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.history),
                    tooltip: l10n.viewSessionsForFieldTooltip,
                    onPressed: () {
                      final fieldId = _gameSessionData?['fieldId'];
                      if (fieldId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FieldSessionsScreen(fieldId: fieldId),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(l10n.noAssociatedField)),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.fieldLabel(_gameSessionData!['fieldName'] ?? l10n.unknownField),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                l10n.sessionStatusLabel(_gameSessionData!['active'].toString()),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_gameSessionData!['startTime'] != null)
                Text(
                  l10n.sessionStartTimeLabel(_formatDate(_gameSessionData!['startTime'])),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              if (_gameSessionData!['endTime'] != null)
                Text(
                  l10n.endTimeLabel(_formatDate(_gameSessionData!['endTime'])),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              if (_statistics != null &&
                  _statistics!['totalParticipants'] != null)
                Text(
                  l10n.participantsLabel(_statistics!['totalParticipants'].toString()),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              const SizedBox(height: 12),
              if (_gameSessionData != null &&
                  _gameSessionData!['active'] == false)
                ElevatedButton.icon(
                  icon: const Icon(Icons.replay),
                  label: Text(l10n.viewReplayButton),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameReplayScreen(
                          gameSessionId: widget.gameSessionId,
                          gameMap: _gameSessionData!['gameMap'],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildScenariosSection(List<dynamic> scenarios) {
    final l10n = AppLocalizations.of(context)!;
    List<Widget> widgets = [];

    widgets.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          l10n.scenariosLabel,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );

    for (var scenario in scenarios) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenario['scenarioName'] ?? l10n.scenarioNameDefault,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),

                  // Scénario Treasure Hunt
                  if (scenario['treasureHuntStats'] != null)
                    ..._buildTreasureHuntStatsSection(
                        scenario['treasureHuntStats']),

                  // Scénario Bomb Operation
                  if (scenario['bombOperationStats'] != null)
                    ..._buildBombOperationStatsSection(
                        scenario['bombOperationStats']),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildBombOperationStatsSection(Map<String, dynamic> bombOperationStats) {
    final l10n = AppLocalizations.of(context)!;
    List<Widget> widgets = [];

    widgets.add(const SizedBox(height: 16));

    widgets.add(
      Text(
        l10n.bombOperationResultsTitle,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );

    widgets.add(const SizedBox(height: 12));

    // Résumé des équipes
    widgets.add(
      Row(
        children: [
          // Équipe Terroriste
          Expanded(
            child: _buildBombOperationTeamCard(
              l10n.terroristsTeam,
              Colors.red,
              bombOperationStats['armedSites'] ?? 0,
              bombOperationStats['explodedSites'] ?? 0,
              l10n.armedSitesLabel,
              l10n.explodedSitesLabel,
            ),
          ),
          const SizedBox(width: 12),
          // Équipe Anti-terroriste
          Expanded(
            child: _buildBombOperationTeamCard(
              l10n.counterTerroristsTeam,
              Colors.blue,
              bombOperationStats['activeSites'] ?? 0,
              bombOperationStats['disarmedSites'] ?? 0,
              l10n.activeSitesLabel,
              l10n.disarmedSitesLabel,
            ),
          ),
        ],
      ),
    );

    widgets.add(const SizedBox(height: 12));

    // Résultat final
    final result = bombOperationStats['result'] ?? 'DRAW';
    final resultColor = _getBombOperationResultColor(result);
    String resultText;
    switch (result) {
      case 'TERRORISTS_WIN':
        resultText = l10n.terroristsWinResult;
        break;
      case 'COUNTER_TERRORISTS_WIN':
        resultText = l10n.counterTerroristsWinResult;
        break;
      default:
        resultText = l10n.drawResult;
    }


    widgets.add(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: resultColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          resultText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );

    widgets.add(const SizedBox(height: 16));

    // Statistiques détaillées
    widgets.add(
      Text(
        l10n.detailedStatsLabel,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );

    widgets.add(const SizedBox(height: 8));

    widgets.add(
      _buildBombOperationStatsTable(bombOperationStats),
    );

    return widgets;
  }

  Widget _buildBombOperationTeamCard(String teamName, Color teamColor, int stat1, int stat2, String label1, String label2) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: teamColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: teamColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: teamColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$label1: $stat1',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '$label2: $stat2',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBombOperationStatsTable(Map<String, dynamic> stats) {
    final l10n = AppLocalizations.of(context)!;
    return Table(
      border: TableBorder.all(color: Colors.grey[300]!),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.statisticLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.valueLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        _buildBombOperationStatsRow(l10n.totalSitesStat, '${stats['totalSites'] ?? 0}'),
        _buildBombOperationStatsRow(l10n.activeSitesLabel, '${stats['activeSites'] ?? 0}'), // Re-using activeSitesLabel as it's the same text
        _buildBombOperationStatsRow(l10n.armedSitesLabel, '${stats['armedSites'] ?? 0}'),
        _buildBombOperationStatsRow(l10n.disarmedSitesLabel, '${stats['disarmedSites'] ?? 0}'),
        _buildBombOperationStatsRow(l10n.explodedSitesLabel, '${stats['explodedSites'] ?? 0}'),
        if (stats['bombTimer'] != null)
          _buildBombOperationStatsRow(l10n.bombTimerStat, '${stats['bombTimer']}s'),
        if (stats['defuseTime'] != null)
          _buildBombOperationStatsRow(l10n.defuseTimeStat, '${stats['defuseTime']}s'),
        if (stats['armingTime'] != null)
          _buildBombOperationStatsRow(l10n.armingTimeStat, '${stats['armingTime']}s'),
      ],
    );
  }

  TableRow _buildBombOperationStatsRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Color _getBombOperationResultColor(String result) {
    switch (result) {
      case 'TERRORISTS_WIN':
        return Colors.red;
      case 'COUNTER_TERRORISTS_WIN':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _getBombOperationResultText(String result) {
    // This will be replaced by l10n calls in the build method
    final l10n = AppLocalizations.of(context)!;
    switch (result) {
      case 'TERRORISTS_WIN':
        return l10n.terroristsWinResult;
      case 'COUNTER_TERRORISTS_WIN':
        return l10n.counterTerroristsWinResult;
      default:
        return l10n.drawResult;
    }
  }

  List<Widget> _buildTreasureHuntStatsSection(
      Map<String, dynamic> treasureHuntStats) {
    final l10n = AppLocalizations.of(context)!;
    List<Widget> widgets = [];

    widgets.add(
      const SizedBox(height: 16),
    );

    widgets.add(
      Text(
        l10n.treasureHuntScoreboardTitle,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );

    widgets.add(
      const SizedBox(height: 8),
    );

    if (treasureHuntStats['teamScores'] != null) {
      widgets.add(
        Text(
          l10n.teamScoresLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      );

      widgets.add(
        const SizedBox(height: 8),
      );

      // Tableau des scores par équipe
      widgets.add(
        _buildScoreTable(treasureHuntStats['teamScores']),
      );

      widgets.add(
        const SizedBox(height: 16),
      );
    }

    if (treasureHuntStats['individualScores'] != null) {
      widgets.add(
        Text(
          l10n.individualScoresLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      );

      widgets.add(
        const SizedBox(height: 8),
      );

      // Tableau des scores individuels
      widgets.add(
        _buildScoreTable(treasureHuntStats['individualScores']),
      );
    }

    return widgets;
  }

  Widget _buildScoreTable(List<dynamic> scores) {
    final l10n = AppLocalizations.of(context)!;
    // Tri du tableau des scores par points (ordre décroissant)
    scores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return Table(
      border: TableBorder.all(),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  Text(l10n.rankLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.nameLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.treasuresLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  Text(l10n.scoreLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ...scores.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return TableRow(
            decoration:
                index % 2 == 0 ? null : BoxDecoration(color: Colors.grey[100]),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${index + 1}'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(item['username'] ?? l10n.playersTab), // Fallback
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${item['treasuresFound'] ?? 0}'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${item['score'] ?? 0}'),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
