import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/game_session.dart';
import '../../services/history_service.dart';
import '../../widgets/adaptive_background.dart';
import '../../widgets/options/cropped_logo_button.dart';
import 'game_session_details_screen.dart';

class FieldSessionsScreen extends StatefulWidget {
  final int fieldId;

  const FieldSessionsScreen({Key? key, required this.fieldId})
      : super(key: key);

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
      final gameSessions =
          await historyService.getGameSessionsByFieldId(widget.fieldId);
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
      final historyService =
          Provider.of<HistoryService>(context, listen: false);
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
    return AdaptiveScaffold(
      gameBackgroundType: GameBackgroundType.menu,
      enableParallax: true,
      backgroundOpacity: 0.85,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        title: Text(
          _fieldName.isNotEmpty && _fieldName != l10n.unknownField
              ? l10n.fieldSessionsTitle(_fieldName)
              : l10n.gameSessionsTitle,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.7),
              ),
            ],
          ),
        ),
        leadingWidth: 100,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 4),
            // ⬇️ Contraint la taille du logo pour éviter les débordements
            const SizedBox(
              width: 36,
              height: 36,
              child: CroppedLogoButton(),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16)))
              : _gameSessions.isEmpty
                  ? Center(
                      child: Text(l10n.noGameSessionsForField,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)))
                  : ListView.builder(
                      itemCount: _gameSessions.length,
                      itemBuilder: (context, index) {
                        final gameSession = _gameSessions[index];
                        String subtitle;
                        if (gameSession.startTime != null &&
                            gameSession.endTime != null) {
                          subtitle = l10n.sessionTimeLabel(
                              _formatDate(gameSession.startTime!),
                              _formatDate(gameSession.endTime!));
                        } else if (gameSession.startTime != null) {
                          subtitle = l10n.sessionStartTimeLabel(
                              _formatDate(gameSession.startTime!));
                        } else {
                          subtitle = '';
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: Colors.black.withOpacity(0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: ListTile(
                            title: Text(
                                l10n.sessionListItemTitle(
                                    (index + 1).toString()),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                '${l10n.sessionStatusLabel(gameSession.active.toString())}\n$subtitle',
                                style: const TextStyle(color: Colors.white70)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _showDeleteConfirmationDialog(
                                          gameSession),
                                ),
                                const Icon(Icons.arrow_forward_ios, color: Colors.white),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      GameSessionDetailsScreen(
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
