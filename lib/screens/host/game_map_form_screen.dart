import 'dart:convert';

import 'package:game_map_master_flutter_app/screens/map_editor/interactive_map_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/game_map.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_map_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';
class GameMapFormScreen extends StatefulWidget {
  final GameMap? gameMap;

  const GameMapFormScreen({Key? key, this.gameMap}) : super(key: key);

  @override
  State<GameMapFormScreen> createState() => _GameMapFormScreenState();
}

class _GameMapFormScreenState extends State<GameMapFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scaleController = TextEditingController();

  bool _isLoading = false;

  // State to hold interactive map data received from the editor
  String? _sourceAddress;
  double? _centerLatitude;
  double? _centerLongitude;
  double? _initialZoom;
  String? _fieldBoundaryJson;
  String? _mapZonesJson;
  String? _mapPointsOfInterestJson;
  String? _backgroundImageBase64;
  GameMap? _localGameMap;

  @override
  void initState() {
    super.initState();
    if (widget.gameMap != null) {
      _nameController.text = widget.gameMap!.name;
      _descriptionController.text = widget.gameMap!.description ?? '';
      _scaleController.text = widget.gameMap!.scale?.toString() ?? '1.0';

      // Initialize interactive map fields if they exist
      _sourceAddress = widget.gameMap!.sourceAddress;
      _centerLatitude = widget.gameMap!.centerLatitude;
      _centerLongitude = widget.gameMap!.centerLongitude;
      _initialZoom = widget.gameMap!.initialZoom;
      _fieldBoundaryJson = widget.gameMap!.fieldBoundaryJson;
      _mapZonesJson = widget.gameMap!.mapZonesJson;
      _mapPointsOfInterestJson = widget.gameMap!.mapPointsOfInterestJson;
      _backgroundImageBase64 = widget.gameMap!.backgroundImageBase64;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _openInteractiveMapEditor() async {
    // Prepare the GameMap object to pass to the editor
    // If creating a new map, some fields might be null initially
    GameMap mapToEdit = widget.gameMap ??
        GameMap(
            name: _nameController.text.isNotEmpty
                ? _nameController.text
                : "Nouvelle Carte");

    // Ensure existing interactive data is passed if available
    mapToEdit = mapToEdit.copyWith(
      name: _nameController.text.isNotEmpty
          ? _nameController.text
          : mapToEdit.name,
      description: _descriptionController.text,
      scale: double.tryParse(_scaleController.text),
      sourceAddress: _sourceAddress,
      centerLatitude: _centerLatitude,
      centerLongitude: _centerLongitude,
      initialZoom: _initialZoom,
      fieldBoundaryJson: _fieldBoundaryJson,
      mapZonesJson: _mapZonesJson,
      mapPointsOfInterestJson: _mapPointsOfInterestJson,
      backgroundImageBase64: _backgroundImageBase64,
    );

    final GameMap? updatedMapData = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InteractiveMapEditorScreen(initialMap: mapToEdit),
      ),
    );

    if (updatedMapData != null) {
      setState(() {
        // Update the form's state with data from the editor
        // This is crucial if the editor modifies these fields directly
        // and returns the full map object.
        _localGameMap = updatedMapData;
        _nameController.text = updatedMapData.name;
        _descriptionController.text = updatedMapData.description ?? '';
        _scaleController.text =
            updatedMapData.scale?.toString() ?? _scaleController.text;

        _sourceAddress = updatedMapData.sourceAddress;
        _centerLatitude = updatedMapData.centerLatitude;
        _centerLongitude = updatedMapData.centerLongitude;
        _initialZoom = updatedMapData.initialZoom;
        _fieldBoundaryJson = updatedMapData.fieldBoundaryJson;
        _mapZonesJson = updatedMapData.mapZonesJson;
        _mapPointsOfInterestJson = updatedMapData.mapPointsOfInterestJson;
        _backgroundImageBase64 = updatedMapData.backgroundImageBase64;
      });
    }
  }

  Future<void> _saveGameMap() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Use the GameMap instance from widget.gameMap if editing, or create a new one
        // Then, apply all current field values, including those from the interactive editor
        final gameMap = GameMap(
          id: _localGameMap?.id ?? widget.gameMap?.id,
          name: _nameController.text,
          description: _descriptionController.text,
          scale: double.tryParse(_scaleController.text) ?? 1.0,
          // Interactive map fields populated from state
          sourceAddress: _sourceAddress,
          centerLatitude: _centerLatitude,
          centerLongitude: _centerLongitude,
          initialZoom: _initialZoom,
          fieldBoundaryJson: _fieldBoundaryJson,
          mapZonesJson: _mapZonesJson,
          mapPointsOfInterestJson: _mapPointsOfInterestJson,
          backgroundImageBase64: _backgroundImageBase64,
          // Preserve other fields if editing an existing map
          fieldId: _localGameMap?.fieldId ?? widget.gameMap?.fieldId,
          ownerId: _localGameMap?.ownerId ?? widget.gameMap?.ownerId,
          scenarioIds: widget.gameMap?.scenarioIds,
          imageUrl: widget.gameMap?.imageUrl,
          // Keep existing non-interactive image if any
          owner: widget.gameMap?.owner,
          field: widget.gameMap?.field,
        );

        final gameMapService = context.read<GameMapService>();

        if (_localGameMap?.id != null || widget.gameMap?.id != null) {
          logger.d('📤 [GameMapFormScreen] Données envoyées pour création :');
          logger.d(const JsonEncoder.withIndent('  ').convert(gameMap.toJson()));
          _localGameMap = await gameMapService.addGameMap(gameMap);
        } else {
          logger.d('📤 [GameMapFormScreen] Données envoyées pour update :');
          logger.d(const JsonEncoder.withIndent('  ').convert(gameMap.toJson()));
          await gameMapService.updateGameMap(gameMap);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.mapSavedSuccess),
              backgroundColor: Colors.green,
            ),
          );
          await gameMapService.loadGameMaps();
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.error + e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.gameMap == null ? l10n.newMapTitle : l10n.editMap),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.mapName,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.mapNameRequiredError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.mapDescription,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _scaleController,
                      decoration: InputDecoration(
                        labelText: l10n.scaleLabel,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final scale = double.tryParse(value);
                          if (scale == null || scale <= 0) {
                            return l10n.invalidScaleError;
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_sourceAddress != null && _sourceAddress!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: Theme.of(context).primaryColor,
                                    size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.interactiveMapAddressLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _sourceAddress!,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(
                          Icons.map_outlined), // Choose an appropriate icon
                      label: Text((_backgroundImageBase64 == null ||
                                  _backgroundImageBase64!.isEmpty) &&
                              (_fieldBoundaryJson == null ||
                                  _fieldBoundaryJson!.isEmpty)
                          ? l10n.defineInteractiveMapButton
                          : l10n.editInteractiveMapButton),
                      onPressed: _openInteractiveMapEditor,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveGameMap,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        (_localGameMap?.id != null || widget.gameMap?.id != null)
                            ? l10n.updateMapButton
                            : l10n.createMap,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
