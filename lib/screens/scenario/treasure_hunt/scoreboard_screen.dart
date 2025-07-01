import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../models/scenario/treasure_hunt/treasure_hunt_score.dart';
import '../../../services/scenario/treasure_hunt/treasure_hunt_service.dart';
import '../../../services/websocket/treasure_hunt_websocket_handler.dart';
class ScoreboardScreen extends StatefulWidget {
  final int treasureHuntId;
  final String scenarioName;
  final bool isHost;

  const ScoreboardScreen({
    Key? key,
    required this.treasureHuntId,
    required this.scenarioName,
    this.isHost = false,
  }) : super(key: key);

  @override
  _ScoreboardScreenState createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _scoreboardData;
  List<TreasureHuntScore> _individualScores = [];
  List<TreasureHuntScore> _teamScores = [];
  bool _scoresLocked = false;

  StreamSubscription? _scoreboardSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadScoreboard();

    // S'abonner aux mises à jour WebSocket
    final treasureHuntWebSocketHandler = Provider.of<TreasureHuntWebSocketHandler>(context, listen: false);
    treasureHuntWebSocketHandler.subscribeToScenario(widget.treasureHuntId);

    _scoreboardSubscription = treasureHuntWebSocketHandler.scoreboardUpdateStream.listen((scoreboard) {
      if (mounted) {
        _updateScoreboard(scoreboard);
      }
    });

    // Rafraîchir périodiquement pour les joueurs
    if (!widget.isHost) {
      _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
        if (mounted) {
          _loadScoreboard();
        }
      });
    }
  }

  @override
  void dispose() {
    _scoreboardSubscription?.cancel();
    _refreshTimer?.cancel();

    final treasureHuntWebSocketHandler = Provider.of<TreasureHuntWebSocketHandler>(context, listen: false);
    treasureHuntWebSocketHandler.unsubscribeFromScenario(widget.treasureHuntId);

    super.dispose();
  }

  Future<void> _loadScoreboard() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final treasureHuntService = Provider.of<TreasureHuntService>(context, listen: false);
      final scoreboard = await treasureHuntService.getScoreboard(widget.treasureHuntId);

      _updateScoreboard(scoreboard);
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.errorLoadingScoreboard(e.toString());
        _isLoading = false;
      });
    }
  }

  void _updateScoreboard(Map<String, dynamic> scoreboard) {
    if (!mounted) return;

    setState(() {
      _scoreboardData = scoreboard;
      _individualScores = _parseIndividualScores(scoreboard);
      _teamScores = _parseTeamScores(scoreboard);
      _scoresLocked = scoreboard['scoresLocked'] ?? false;
      _isLoading = false;
    });
  }

  List<TreasureHuntScore> _parseIndividualScores(Map<String, dynamic> scoreboard) {
    final treasureHuntService = Provider.of<TreasureHuntService>(context, listen: false);
    return treasureHuntService.parseIndividualScores(scoreboard);
  }

  List<TreasureHuntScore> _parseTeamScores(Map<String, dynamic> scoreboard) {
    final treasureHuntService = Provider.of<TreasureHuntService>(context, listen: false);
    return treasureHuntService.parseTeamScores(scoreboard);
  }

  Future<void> _toggleLockScores() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final treasureHuntService = Provider.of<TreasureHuntService>(context, listen: false);
      await treasureHuntService.lockScores(widget.treasureHuntId, !_scoresLocked);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.error + e.toString())),
      );
    }
  }

  Future<void> _resetScores() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetScoresTitle),
        content: Text(l10n.resetScoresConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.resetButton),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final treasureHuntService = Provider.of<TreasureHuntService>(context, listen: false);
        await treasureHuntService.resetScores(widget.treasureHuntId);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error + e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scoreboardScreenTitle(widget.scenarioName)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadScoreboard,
            tooltip: l10n.refreshButton,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadScoreboard,
              child: Text(l10n.retryButton),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // En-tête avec informations sur le scénario
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.scoreboardHeader(widget.scenarioName),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _scoresLocked ? Icons.lock : Icons.lock_open,
                      size: 16,
                      color: _scoresLocked ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _scoresLocked ? l10n.scoresLockedLabel : l10n.scoresUnlockedLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: _scoresLocked ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contrôles pour l'hôte
          if (widget.isHost)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleLockScores,
                      icon: Icon(_scoresLocked ? Icons.lock_open : Icons.lock),
                      label: Text(_scoresLocked ? l10n.unlockButton : l10n.lockButton),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _scoresLocked ? Colors.orange : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _resetScores,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.resetButton),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Scores des équipes (si disponibles)
          if (_teamScores.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.teamScoresLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: _teamScores.length,
                itemBuilder: (context, index) {
                  final score = _teamScores[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    color: index == 0 ? Colors.amber[100] : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: index == 0 ? Colors.amber : Colors.blue,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        score.teamName ?? l10n.unknownTeamName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(l10n.treasuresFoundCount(score.treasuresFound.toString())),
                      trailing: Text(
                        l10n.pointsSuffix(score.score.toString()),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Scores individuels
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.individualScoresLabel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: _individualScores.length,
              itemBuilder: (context, index) {
                final score = _individualScores[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: index == 0 ? Colors.amber[100] : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: index == 0 ? Colors.amber : Colors.blue,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      score.username ?? l10n.unknownPlayerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.treasuresFoundCount(score.treasuresFound.toString())),
                        if (score.teamName != null)
                          Text(l10n.teamLabelPlayerList(score.teamName!)),
                      ],
                    ),
                    trailing: Text(
                      l10n.pointsSuffix(score.score.toString()),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
