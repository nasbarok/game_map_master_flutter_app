import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/game_session.dart';
import '../../services/history_service.dart';
import 'game_session_details_screen.dart';

class FieldSessionsScreen extends StatefulWidget {
  final int fieldId;

  const FieldSessionsScreen({Key? key, required this.fieldId}) : super(key: key);

  @override
  _FieldSessionsScreenState createState() => _FieldSessionsScreenState();
}

class _FieldSessionsScreenState extends State<FieldSessionsScreen> {
  List<GameSession> _gameSessions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _fieldName = '';

  @override
  void initState() {
    super.initState();
    _loadFieldAndSessions();
  }

  Future<void> _loadFieldAndSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final historyService = GetIt.I<HistoryService>();

      // Charger les informations du terrain
      final field = await historyService.getFieldById(widget.fieldId);

      // Charger les sessions de jeu pour ce terrain
      final gameSessions = await historyService.getGameSessionsByFieldId(widget.fieldId);
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _fieldName = field?.name ?? l10n.unknownField;
        _gameSessions = gameSessions;
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

  Future<void> _deleteGameSession(GameSession gameSession) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final historyService = Provider.of<HistoryService>(context, listen: false);
      await historyService.deleteGameSession(gameSession.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteSessionSuccess)),
      );

      _loadFieldAndSessions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.error + e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_fieldName.isNotEmpty && _fieldName != l10n.unknownField
            ? l10n.fieldSessionsTitle(_fieldName)
            : l10n.gameSessionsTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : _gameSessions.isEmpty
          ? Center(child: Text(l10n.noGameSessionsForField))
          : ListView.builder(
        itemCount: _gameSessions.length,
        itemBuilder: (context, index) {
          final gameSession = _gameSessions[index];
          String subtitle;
          if (gameSession.startTime != null && gameSession.endTime != null) {
            subtitle = l10n.sessionTimeLabel(_formatDate(gameSession.startTime!), _formatDate(gameSession.endTime!));
          } else if (gameSession.startTime != null) {
            subtitle = l10n.sessionStartTimeLabel(_formatDate(gameSession.startTime!));
          } else {
            subtitle = '';
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(l10n.sessionListItemTitle((index + 1).toString())),
              subtitle: Text(
                '${l10n.sessionStatusLabel(gameSession.active.toString())}\n$subtitle',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteConfirmationDialog(gameSession),
                  ),
                  const Icon(Icons.arrow_forward_ios),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameSessionDetailsScreen(
                      gameSessionId: gameSession.id!,
                      sessionIndex: index, // <-- nouvel argument
                    ),
                  ),
                ).then((_) => _loadFieldAndSessions());
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'field_sessions_fab',
        onPressed: _loadFieldAndSessions,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Future<void> _showDeleteConfirmationDialog(GameSession gameSession) async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmation),
        content: Text(l10n.deleteSessionConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGameSession(gameSession);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
