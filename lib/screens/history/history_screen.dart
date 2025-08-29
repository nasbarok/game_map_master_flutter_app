import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/field.dart';
import '../../models/pagination/paginated_response.dart';
import '../../services/history_service.dart';
import '../../widgets/adaptive_background.dart';
import '../../widgets/options/cropped_logo_button.dart';
import '../../widgets/pagination/pagination_controls.dart';
import 'field_sessions_screen.dart';
import '../../utils/logger.dart';

class HistoryScreen extends StatefulWidget {
  final int? fieldId;

  const HistoryScreen({Key? key, this.fieldId}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // --- Pagination (nouveau) ---
  PaginatedResponse<Field>? _currentPage;
  int _currentPageNumber = 0;

  List<Field> _fields = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFieldsPaginated(0);
  }

  Future<void> _loadFieldsPaginated([int page = 0]) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final historyService =
          Provider.of<HistoryService>(context, listen: false);
      late PaginatedResponse<Field> fieldsPage;
      if (widget.fieldId != null) {
        // Mode "terrain spécifique" — on garde l’ancien comportement et on enveloppe dans une page simulée
        final field = await historyService.getFieldById(widget.fieldId!);
        final List<Field> list = (field != null) ? <Field>[field] : <Field>[];

        fieldsPage = PaginatedResponse<Field>(
          content: list,
          totalElements: list.length,
          totalPages: 1,
          number: 0,
          size: list.length,
          first: true,
          last: true,
          numberOfElements: list.length,
        );
      } else {
        // Mode liste complète — on utilise la pagination réelle
        fieldsPage = await historyService.getFieldsPaginated(
          page: page,
          size: 15,
        );
      }

      if (!mounted) return;
      setState(() {
        _currentPage = fieldsPage;
        _currentPageNumber = page;
        _fields = fieldsPage.content;
        _isLoading = false;
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      logger.e(l10n.errorLoadingData(e.toString()));

      if (!mounted) return;
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

        _loadFieldsPaginated(_currentPageNumber); // Rafraîchir la liste
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
      appBar: null,
      /*appBar: AppBar(
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
      ),*/
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16)))
              : (_currentPage == null || _fields.isEmpty)
                  ? Center(
                      child: Text(l10n.noFieldsAvailable,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)))
                  : Column(
                      children: [
                        if ((_currentPage?.totalPages ?? 0) > 1)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: PaginationControls(
                              currentPage: _currentPage!.number,
                              totalPages: _currentPage!.totalPages,
                              totalElements: _currentPage!.totalElements,
                              isFirst: _currentPage!.first,
                              isLast: _currentPage!.last,
                              onPrevious: () =>
                                  _goToPage(_currentPageNumber - 1),
                              onNext: () => _goToPage(_currentPageNumber + 1),
                            ),
                          ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () =>
                                _loadFieldsPaginated(_currentPageNumber),
                            color: const Color(0xFF48BB78),
                            child: ListView.builder(
                              itemCount: _fields.length,
                              itemBuilder: (context, index) {
                                final field = _fields[index];
                                // ... ton Card + ListTile inchangés
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  color: Colors.black.withOpacity(0.7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1),
                                  ),
                                  child: ListTile(
                                    title: Text(field.name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (field.openedAt != null)
                                          Text(l10n.fieldOpenedOn(
                                              _formatDate(field.openedAt!))),
                                        if (field.closedAt != null)
                                          Text(
                                            l10n.fieldClosedOn(
                                                _formatDate(field.closedAt!)),
                                            style: const TextStyle(
                                                color: Colors.white70),
                                          )
                                        else
                                          Text(l10n.fieldStatusOpen,
                                              style: const TextStyle(
                                                  color: Colors.green)),
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
                                            onPressed: () =>
                                                _confirmDeleteField(field),
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
                                              FieldSessionsScreen(
                                                  fieldId: field.id!),
                                        ),
                                      ).then(
                                          (_) => _goToPage(_currentPageNumber));
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: widget.fieldId == null
          ? FloatingActionButton(
              heroTag: 'history_fab',
              onPressed: () => _loadFieldsPaginated(_currentPageNumber),
              tooltip: l10n.refreshTooltip,
              backgroundColor: Colors.blue.shade600,
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
    );
  }

  void _goToPage(int target) {
    final tp = (_currentPage?.totalPages ?? 1);
    final next = target.clamp(0, tp > 0 ? tp - 1 : 0);
    _loadFieldsPaginated(next);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
