import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/field.dart';
import '../../services/history_service.dart';
import '../../widgets/adaptive_background.dart';
import '../../widgets/options/cropped_logo_button.dart';
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
      final historyService =
          Provider.of<HistoryService>(context, listen: false);

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
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.errorLoadingData(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDeleteField(Field field) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmation),
        content: Text(l10n.deleteFieldConfirmationMessage(field.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final historyService =
            Provider.of<HistoryService>(context, listen: false);
        await historyService.deleteField(field.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.fieldDeletedSuccess(field.name))),
        );

        _loadFields(); // Rafraîchir la liste
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
    return AdaptiveScaffold(
      gameBackgroundType: GameBackgroundType.menu,
      enableParallax: true,
      backgroundOpacity: 0.85,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        title: Text(
          widget.fieldId != null
              ? l10n.historyScreenTitleField
              : l10n.historyScreenTitleGeneric,
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16)))
              : _fields.isEmpty
                  ? Center(
                      child: Text(l10n.noFieldsAvailable,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)))
                  : ListView.builder(
                      itemCount: _fields.length,
                      itemBuilder: (context, index) {
                        final field = _fields[index];
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
                            title: Text(field.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.fieldOpenedOn(
                                    _formatDate(field.openedAt!))),
                                if (field.closedAt != null)
                                  Text(
                                      l10n.fieldClosedOn(
                                          _formatDate(field.closedAt!)),
                                      style: const TextStyle(
                                          color: Colors.white70))
                                else
                                  Text(l10n.fieldStatusOpen,
                                      style:
                                          const TextStyle(color: Colors.green)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (field.closedAt != null)
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    tooltip: l10n.deleteFieldTooltip,
                                    onPressed: () => _confirmDeleteField(field),
                                  ),
                                const Icon(Icons.arrow_forward_ios,
                                    color: Colors.white),
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
              tooltip: l10n.refreshTooltip,
              backgroundColor: Colors.blue.shade600,
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
