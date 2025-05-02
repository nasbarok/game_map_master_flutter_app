import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

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

      setState(() {
        _fieldName = field?.name ?? 'Terrain inconnu';
        _gameSessions = gameSessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteGameSession(GameSession gameSession) async {
    try {
      final historyService = Provider.of<HistoryService>(context, listen: false);
      await historyService.deleteGameSession(gameSession.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session de jeu supprimée avec succès')),
      );

      _loadFieldAndSessions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_fieldName.isNotEmpty ? 'Sessions - $_fieldName' : 'Sessions de jeu'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
          : _gameSessions.isEmpty
          ? Center(child: Text('Aucune session de jeu disponible pour ce terrain'))
          : ListView.builder(
        itemCount: _gameSessions.length,
        itemBuilder: (context, index) {
          final gameSession = _gameSessions[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('Session #${gameSession.id}'),
              subtitle: Text(
                'Statut: ${gameSession.active}\n'
                    '${gameSession.startTime != null ? 'Début: ${_formatDate(gameSession.startTime!)}' : ''}'
                    '${gameSession.endTime != null ? ' - Fin: ${_formatDate(gameSession.endTime!)}' : ''}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _showDeleteConfirmationDialog(gameSession),
                  ),
                  Icon(Icons.arrow_forward_ios),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameSessionDetailsScreen(gameSessionId: gameSession.id!),
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
        child: Icon(Icons.refresh),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Future<void> _showDeleteConfirmationDialog(GameSession gameSession) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette session de jeu ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGameSession(gameSession);
            },
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
