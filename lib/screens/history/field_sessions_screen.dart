import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/game_session.dart';
import '../../models/pagination/paginated_response.dart';
import '../../services/history_service.dart';
import '../../widgets/adaptive_background.dart';
import '../../widgets/options/cropped_logo_button.dart';
import '../../widgets/pagination/pagination_controls.dart';
import 'game_session_details_screen.dart';

class FieldSessionsScreen extends StatefulWidget {
  final int fieldId;

  const FieldSessionsScreen({Key? key, required this.fieldId}) : super(key: key);

  @override
  _FieldSessionsScreenState createState() => _FieldSessionsScreenState();
}

class _FieldSessionsScreenState extends State<FieldSessionsScreen> {
  // --- Pagination ---
  PaginatedResponse<GameSession>? _currentPage;
  int _currentPageNumber = 0;
  final int _pageSize = 10;

  // --- Données/UI ---
  List<GameSession> _gameSessions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _fieldName = '';

  // --- filtres temporels ---
  DateTime? _startDateUtc;
  DateTime? _endDateUtc;

  @override
  void initState() {
    super.initState();
    _loadFieldAndSessions(page: 0);
  }

  Future<void> _loadFieldAndSessions({required int page}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final historyService = GetIt.I<HistoryService>();

      // Charger les infos du terrain
      final field = await historyService.getFieldById(widget.fieldId);

      // Charger les sessions paginées
      final pageObj = await historyService.getGameSessionsByFieldIdPaginated(
        widget.fieldId,
        page: page,
        size: _pageSize,
        startDate: _startDateUtc, // null si pas de filtre
        endDate: _endDateUtc,     // null si pas de filtre
      );

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      setState(() {
        _fieldName = field?.name ?? l10n.unknownField;
        _currentPage = pageObj;
        _currentPageNumber = pageObj.number;
        _gameSessions = pageObj.content;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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

      // Si on vient de supprimer le dernier élément de la page courante,
      // on revient à la page précédente (si possible) pour éviter une page vide.
      final bool lastItemOnPage = (_gameSessions.length <= 1);
      final int targetPage = (lastItemOnPage && _currentPageNumber > 0)
          ? _currentPageNumber - 1
          : _currentPageNumber;

      _loadFieldAndSessions(page: targetPage);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.error + e.toString())),
      );
    }
  }

  void _goToPage(int target) {
    final totalPages = (_currentPage?.totalPages ?? 1);
    final next = target.clamp(0, totalPages > 0 ? totalPages - 1 : 0);
    _loadFieldAndSessions(page: next);
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
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 4),
            const SizedBox(width: 36, height: 36, child: CroppedLogoButton()),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _errorMessage != null
          ? Center(
          child: Text(_errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16)))
          : (_currentPage == null || _gameSessions.isEmpty)
          ? Center(
          child: Text(l10n.noGameSessionsForField,
              style:
              const TextStyle(color: Colors.white, fontSize: 16)))
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
                onPrevious: () => _goToPage(_currentPageNumber - 1),
                onNext: () => _goToPage(_currentPageNumber + 1),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadFieldAndSessions(page: _currentPageNumber),
              color: const Color(0xFF48BB78),
              child: ListView.builder(
                itemCount: _gameSessions.length,
                itemBuilder: (context, index) {
                  final gameSession = _gameSessions[index];

                  String subtitle;
                  if (gameSession.startTime != null && gameSession.endTime != null) {
                    subtitle = l10n.sessionTimeLabel(
                      _formatDate(gameSession.startTime!),
                      _formatDate(gameSession.endTime!),
                    );
                  } else if (gameSession.startTime != null) {
                    subtitle = l10n.sessionStartTimeLabel(
                      _formatDate(gameSession.startTime!),
                    );
                  } else {
                    subtitle = '';
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.black.withOpacity(0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: ListTile(
                      title: Text(
                        l10n.sessionListItemTitle((index + 1 + _currentPageNumber * _pageSize).toString()),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${l10n.sessionStatusLabel(gameSession.active.toString())}\n$subtitle',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _showDeleteConfirmationDialog(gameSession),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameSessionDetailsScreen(
                              gameSessionId: gameSession.id!,
                              sessionIndex: index,
                            ),
                          ),
                        ).then((_) => _loadFieldAndSessions(page: _currentPageNumber));
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'field_sessions_fab',
        onPressed: () => _loadFieldAndSessions(page: _currentPageNumber),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
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
