import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n/app_localizations.dart' show AppLocalizations;
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
      final treasureHuntService =
          Provider.of<TreasureHuntService>(context, listen: false);
      final treasures =
          await treasureHuntService.getTreasures(widget.treasureHuntId);

      setState(() {
        _treasures = treasures;
        _isLoading = false;
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.errorLoadingTreasures(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _generateQRCodes() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isGeneratingQRCodes = true;
      _errorMessage = null;
    });

    try {
      final treasureHuntService =
          Provider.of<TreasureHuntService>(context, listen: false);
      final qrCodes =
          await treasureHuntService.generateQRCodes(widget.treasureHuntId);

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
        _errorMessage = l10n.error + e.toString();
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.treasuresScreenTitle(widget.scenarioName)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTreasures,
            tooltip: l10n.refreshButton,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTreasures,
                        child: Text(l10n.retryButton),
                      ),
                    ],
                  ),
                )
              : _treasures.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noTreasuresFoundForScenario,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // En-tête avec informations sur le scénario
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.blue[50],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.scenarioNameHeader(widget.scenarioName),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.numberOfTreasuresLabel(
                                    _treasures.length.toString()),
                                style: const TextStyle(fontSize: 16),
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
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.amber,
                                    child: Text(
                                      treasure.symbol,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                  title: Text(
                                    treasure.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(l10n.treasureValueSubtitle(
                                      treasure.points.toString())),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            _editTreasure(treasure),
                                        tooltip: l10n.edit,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        color: Colors.red,
                                        onPressed: () =>
                                            _confirmDeleteTreasure(treasure),
                                        tooltip: l10n.delete,
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
              child: const CircularProgressIndicator(color: Colors.white),
            )
          : FloatingActionButton.extended(
              onPressed: _generateQRCodes,
              icon: const Icon(Icons.qr_code),
              label: Text(l10n.viewQRCodesButton),
              tooltip: l10n.viewQRCodesButton,
            ),
    );
  }

  Future<void> _confirmDeleteTreasure(Treasure treasure) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTreasureTitle),
        content: Text(l10n.confirmDeleteTreasureMessage(treasure.name)),
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

    if (confirmed == true) {
      try {
        final treasureHuntService =
            Provider.of<TreasureHuntService>(context, listen: false);
        await treasureHuntService.deleteTreasure(treasure.id!);
        _loadTreasures();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorDeletingTreasure(e.toString()))),
        );
      }
    }
  }
}
