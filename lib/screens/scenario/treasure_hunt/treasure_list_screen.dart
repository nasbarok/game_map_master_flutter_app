import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/scenario/treasure_hunt/treasure.dart';
import '../../../services/scenario/treasure_hunt/treasure_hunt_service.dart';
import 'qr_codes_display_screen.dart';
import 'treasure_edit_screen.dart';

class TreasureListScreen extends StatefulWidget {
  final int treasureHuntId;
  final String scenarioName;

  const TreasureListScreen({
    Key? key,
    required this.treasureHuntId,
    required this.scenarioName,
  }) : super(key: key);

  @override
  _TreasureListScreenState createState() => _TreasureListScreenState();
}

class _TreasureListScreenState extends State<TreasureListScreen> {
  bool _isLoading = true;
  bool _isGeneratingQRCodes = false;
  String? _errorMessage;
  List<Treasure> _treasures = [];
  List<Map<String, dynamic>>? _qrCodes;

  @override
  void initState() {
    super.initState();
    _loadTreasures();
  }

  Future<void> _loadTreasures() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final treasureHuntService = Provider.of<TreasureHuntService>(context, listen: false);
      final treasures = await treasureHuntService.getTreasures(widget.treasureHuntId);

      setState(() {
        _treasures = treasures;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des trésors: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateQRCodes() async {
    setState(() {
      _isGeneratingQRCodes = true;
      _errorMessage = null;
    });

    try {
      final treasureHuntService = Provider.of<TreasureHuntService>(context, listen: false);
      final qrCodes = await treasureHuntService.generateQRCodes(widget.treasureHuntId);

      setState(() {
        _qrCodes = qrCodes;
        _isGeneratingQRCodes = false;
      });

      // Afficher la page de QR codes
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRCodesDisplayScreen(
              qrCodes: _qrCodes!,
              scenarioName: widget.scenarioName,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la génération des QR codes: $e';
        _isGeneratingQRCodes = false;
      });
    }
  }

  Future<void> _editTreasure(Treasure treasure) async {
    final result = await Navigator.push<Treasure>(
      context,
      MaterialPageRoute(
        builder: (context) => TreasureEditScreen(
          treasure: treasure,
        ),
      ),
    );

    if (result != null) {
      // Rafraîchir la liste
      _loadTreasures();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trésors - ${widget.scenarioName}'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true); // On signale qu'on veut reload à la remontée
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTreasures,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTreasures,
              child: Text('Réessayer'),
            ),
          ],
        ),
      )
          : _treasures.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun trésor trouvé pour ce scénario',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : Column(
        children: [
          // En-tête avec informations sur le scénario
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scénario: ${widget.scenarioName}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Nombre de trésors: ${_treasures.length}',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),

          // Liste des trésors
          Expanded(
            child: ListView.builder(
              itemCount: _treasures.length,
              itemBuilder: (context, index) {
                final treasure = _treasures[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Text(
                        treasure.symbol,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Text(
                      treasure.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Valeur: ${treasure.points} points'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _editTreasure(treasure),
                          tooltip: 'Modifier',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () => _confirmDeleteTreasure(treasure),
                          tooltip: 'Supprimer',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isGeneratingQRCodes
          ? FloatingActionButton(
        onPressed: null,
        backgroundColor: Colors.grey,
        child: CircularProgressIndicator(color: Colors.white),
      )
          : FloatingActionButton.extended(
        onPressed: _generateQRCodes,
        icon: Icon(Icons.qr_code),
        label: Text('Voir les QR Codes'),
        tooltip: 'Voir les QR codes pour tous les trésors',
      ),
    );
  }

  Future<void> _confirmDeleteTreasure(Treasure treasure) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ce trésor ?'),
        content: Text('Es-tu sûr de vouloir supprimer "${treasure.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final treasureHuntService = Provider.of<TreasureHuntService>(context, listen: false);
        await treasureHuntService.deleteTreasure(treasure.id!);
        _loadTreasures();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression du trésor: $e')),
        );
      }
    }
  }

}
