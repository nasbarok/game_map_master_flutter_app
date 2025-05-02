import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/field.dart';
import '../../services/history_service.dart';
import 'field_sessions_screen.dart';

class HistoryScreen extends StatefulWidget {
  final int? fieldId;

  const HistoryScreen({Key? key, this.fieldId}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Field> _fields = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final historyService = Provider.of<HistoryService>(context, listen: false);

      List<Field> fields;

      if (widget.fieldId != null) {
        final field = await historyService.getFieldById(widget.fieldId!);
        fields = field != null ? [field] : [];
      } else {
        fields = await historyService.getFields();
      }

      setState(() {
        _fields = fields;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des terrains: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDeleteField(Field field) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer le terrain "${field.name}" et tout son historique ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final historyService = Provider.of<HistoryService>(context, listen: false);
        await historyService.deleteField(field.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terrain "${field.name}" supprimé')),
        );

        _loadFields(); // Rafraîchir la liste
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fieldId != null ? 'Historique du terrain' : 'Historique des terrains'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : _fields.isEmpty
          ? const Center(child: Text('Aucun terrain disponible'))
          : ListView.builder(
        itemCount: _fields.length,
        itemBuilder: (context, index) {
          final field = _fields[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(field.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ouvert le ${_formatDate(field.openedAt!)}'),
                  if (field.closedAt != null)
                    Text('Fermé le ${_formatDate(field.closedAt!)}')
                  else
                    const Text('Ouvert', style: TextStyle(color: Colors.green)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (field.closedAt != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Supprimer ce terrain',
                    onPressed: () => _confirmDeleteField(field),
                  ),
                  const Icon(Icons.arrow_forward_ios),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FieldSessionsScreen(fieldId: field.id!),
                  ),
                ).then((_) => _loadFields());
              },
            ),
          );
        },
      ),
      floatingActionButton: widget.fieldId == null
          ? FloatingActionButton(
        heroTag: 'history_fab',
        onPressed: _loadFields,
        child: const Icon(Icons.refresh),
      )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
