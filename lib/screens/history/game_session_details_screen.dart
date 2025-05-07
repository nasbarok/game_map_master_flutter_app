import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/history_service.dart';
import 'field_sessions_screen.dart';

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

      setState(() {
        _gameSessionData = {
          'id': gameSession.id,
          'fieldName': gameSession.field?.name,
          'fieldId': gameSession.field?.id,
          'active': gameSession.active,
          'startTime': gameSession.startTime,
          'endTime': gameSession.endTime,
        };
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Erreur lors du chargement des détails: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sessionIndex != null
            ? 'Session #${widget.sessionIndex! + 1}'
            : _gameSessionData != null
                ? 'Session #${widget.sessionIndex! + 1}'
                : 'Détails de la session'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child:
                      Text(_errorMessage!, style: TextStyle(color: Colors.red)))
              : _gameSessionData == null
                  ? Center(child: Text('Session non trouvée'))
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
        child: Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSessionInfoCard() {
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
                    'Session #${widget.sessionIndex! + 1}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.history),
                    tooltip: 'Voir les sessions de ce terrain',
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
                          const SnackBar(
                              content: Text('Aucun terrain associé trouvé')),
                        );
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Terrain: ${_gameSessionData!['fieldName']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Statut: ${_gameSessionData!['status']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_gameSessionData!['startTime'] != null)
                Text(
                  'Début: ${_formatDate(_gameSessionData!['startTime'])}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              if (_gameSessionData!['endTime'] != null)
                Text(
                  'Fin: ${_formatDate(_gameSessionData!['endTime'])}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              if (_statistics != null &&
                  _statistics!['totalParticipants'] != null)
                Text(
                  'Participants: ${_statistics!['totalParticipants']}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildScenariosSection(List<dynamic> scenarios) {
    List<Widget> widgets = [];

    widgets.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          'Scénarios',
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
                    scenario['scenarioName'] ?? 'Scénario sans nom',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  if (scenario['treasureHuntStats'] != null)
                    ..._buildTreasureHuntStatsSection(
                        scenario['treasureHuntStats']),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildTreasureHuntStatsSection(
      Map<String, dynamic> treasureHuntStats) {
    List<Widget> widgets = [];

    widgets.add(
      SizedBox(height: 16),
    );

    widgets.add(
      Text(
        'Tableau des scores',
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );

    widgets.add(
      SizedBox(height: 8),
    );

    if (treasureHuntStats['teamScores'] != null) {
      widgets.add(
        Text(
          'Scores par équipe',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      );

      widgets.add(
        SizedBox(height: 8),
      );

      // Tableau des scores par équipe
      widgets.add(
        _buildScoreTable(treasureHuntStats['teamScores']),
      );

      widgets.add(
        SizedBox(height: 16),
      );
    }

    if (treasureHuntStats['individualScores'] != null) {
      widgets.add(
        Text(
          'Scores individuels',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      );

      widgets.add(
        SizedBox(height: 8),
      );

      // Tableau des scores individuels
      widgets.add(
        _buildScoreTable(treasureHuntStats['individualScores']),
      );
    }

    return widgets;
  }

  Widget _buildScoreTable(List<dynamic> scores) {
    // Tri du tableau des scores par points (ordre décroissant)
    scores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return Table(
      border: TableBorder.all(),
      columnWidths: {
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
                  Text('Rang', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Trésors',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  Text('Score', style: TextStyle(fontWeight: FontWeight.bold)),
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
                child: Text(item['username'] ?? 'Joueur'),
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
