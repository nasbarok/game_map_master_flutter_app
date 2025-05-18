import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import '../../../models/scenario/bomb_operation/bomb_site.dart';
import '../../../services/scenario/bomb_operation/bomb_operation_scenario_service.dart';
import 'bomb_site_edit_screen.dart';

/// Écran de gestion des sites de bombe pour un scénario Opération Bombe
class BombSiteListScreen extends StatefulWidget {
  /// Identifiant du scénario
  final int scenarioId;
  
  /// Nom du scénario
  final String scenarioName;

  /// Constructeur
  const BombSiteListScreen({
    Key? key,
    required this.scenarioId,
    required this.scenarioName,
  }) : super(key: key);

  @override
  State<BombSiteListScreen> createState() => _BombSiteListScreenState();
}

class _BombSiteListScreenState extends State<BombSiteListScreen> {
  late BombOperationScenarioService _bombOperationService;
  List<BombSite> _sites = [];
  bool _isLoading = true;
  
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
      final sites = await _bombOperationService.getBombSites(widget.scenarioId);
      setState(() {
        _sites = sites;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des sites: $e'),
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
          site: site,
        ),
      ),
    );
    
    if (result == true) {
      _loadSites();
    }
  }
  
  /// Supprime un site de bombe
  Future<void> _deleteSite(BombSite site) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le site "${site.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      await _bombOperationService.deleteBombSite(site.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Site supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSites();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sites de bombe: ${widget.scenarioName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sites.isEmpty
              ? _buildEmptyState()
              : _buildSiteList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditSite(null),
        tooltip: 'Ajouter un site',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  /// Construit l'état vide (aucun site)
  Widget _buildEmptyState() {
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
          const Text(
            'Aucun site de bombe défini',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez des sites où les bombes pourront être posées et désamorcées',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToEditSite(null),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un site'),
          ),
        ],
      ),
    );
  }
  
  /// Construit la liste des sites
  Widget _buildSiteList() {
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
              'Rayon: ${site.radius}m • Position: ${site.latitude.toStringAsFixed(6)}, ${site.longitude.toStringAsFixed(6)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _navigateToEditSite(site),
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteSite(site),
                  tooltip: 'Supprimer',
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
