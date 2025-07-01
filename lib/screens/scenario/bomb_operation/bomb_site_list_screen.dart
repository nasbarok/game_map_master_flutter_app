import 'package:game_map_master_flutter_app/models/game_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../models/scenario/bomb_operation/bomb_site.dart';
import '../../../services/scenario/bomb_operation/bomb_operation_scenario_service.dart';
import 'bomb_site_edit_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';
/// Écran de gestion des sites de bombe pour un scénario Opération Bombe
class BombSiteListScreen extends StatefulWidget {
  /// Identifiant du scénario
  final int scenarioId;
  final int bombOperationScenarioId;

  /// Nom du scénario
  final String scenarioName;

  /// Carte de jeu associée
  final GameMap gameMap;

  /// Constructeur
  const BombSiteListScreen({
    Key? key,
    required this.scenarioId,
    required this.scenarioName,
    GameMap? gampMap,
    required this.gameMap,
    required this.bombOperationScenarioId,
  }) : super(key: key);

  @override
  State<BombSiteListScreen> createState() => _BombSiteListScreenState();
}

class _BombSiteListScreenState extends State<BombSiteListScreen> {
  late BombOperationScenarioService _bombOperationService;
  List<BombSite> _sites = [];
  bool _isLoading = true;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _bombOperationService = GetIt.I<BombOperationScenarioService>();
    _loadSites();
  }

  /// Charge la liste des sites de bombe depuis le backend
  Future<void> _loadSites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sites = await _bombOperationService
          .getBombSites(widget.bombOperationScenarioId);
      setState(() {
        _sites = sites;
        _isLoading = false;
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLoadingSites(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Navigue vers l'écran d'édition d'un site de bombe
  Future<void> _navigateToEditSite(BombSite? site) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BombSiteEditScreen(
          scenarioId: widget.scenarioId,
          bombOperationScenarioId: widget.bombOperationScenarioId,
          site: site,
          gameMap: widget.gameMap,
          otherSites: _sites.where((s) => s.id != site?.id).toList(),
        ),
      ),
    );

    if (result == true) {
      logger.d(
          '[BombSiteListScreen] Un site a été ajouté ou modifié, on recharge la liste...');
      _hasChanged = true;
      _loadSites();
    }
  }

  /// Supprime un site de bombe
  Future<void> _deleteSite(BombSite site) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteSiteMessage(site.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _bombOperationService.deleteBombSite(site.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.siteDeletedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        _hasChanged = true;
        _loadSites();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorDeletingSite(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.bombSiteListScreenTitle(widget.scenarioName)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _sites.isEmpty
            ? _buildEmptyState()
            : _buildSiteList(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToEditSite(null),
          tooltip: l10n.addSiteButton,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }


  /// Construit l'état vide (aucun site)
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.place_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noBombSitesDefined,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addSitesInstruction,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToEditSite(null),
            icon: const Icon(Icons.add),
            label: Text(l10n.addSiteButton),
          ),
        ],
      ),
    );
  }

  /// Construit la liste des sites
  Widget _buildSiteList() {
    final l10n = AppLocalizations.of(context)!;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sites.length,
      itemBuilder: (context, index) {
        final site = _sites[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getSiteColor(site, context),
              child: Text(
                site.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(site.name),
            subtitle: Text(
              l10n.siteDetailsSubtitle(
                site.radius.toString(),
                site.latitude.toStringAsFixed(6),
                site.longitude.toStringAsFixed(6),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _navigateToEditSite(site),
                  tooltip: l10n.edit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteSite(site),
                  tooltip: l10n.delete,
                ),
              ],
            ),
            onTap: () => _navigateToEditSite(site),
          ),
        );
      },
    );
  }

  /// Obtient la couleur d'un site
  Color _getSiteColor(BombSite site, BuildContext context) {
    if (site.color == null || site.color!.isEmpty) {
      return Theme.of(context).colorScheme.primary;
    }

    try {
      final colorValue = int.parse(site.color!.replaceAll('#', '0xFF'));
      return Color(colorValue);
    } catch (e) {
      return Theme.of(context).colorScheme.primary;
    }
  }
}
