// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import "package:airsoft_game_map/models/coordinate.dart";
import "package:airsoft_game_map/models/game_map.dart";
import "package:airsoft_game_map/models/geocoding_result.dart";
import "package:airsoft_game_map/models/map_point_of_interest.dart";
import "package:airsoft_game_map/models/map_zone.dart";
import "package:airsoft_game_map/services/game_map_service.dart";
import "package:airsoft_game_map/services/geocoding_service.dart";
import "package:airsoft_game_map/widgets/zone_edit_dialog.dart"; // Import du nouveau dialogue
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart" as fm;
import "package:get_it/get_it.dart";
import "package:latlong2/latlong.dart";
import "package:screenshot/screenshot.dart"; // Screenshotting is temporarily disabled
import "dart:convert";
import "dart:typed_data";
import "package:uuid/uuid.dart";

// Enum to manage editor modes
enum MapEditorMode {
  view,
  drawBoundary,
  drawZone,
  placePoi
}

class InteractiveMapEditorScreen extends StatefulWidget {
  final GameMap? initialMap; // Pass a map to edit, or null to create new

  const InteractiveMapEditorScreen({Key? key, this.initialMap}) : super(key: key);

  @override
  State<InteractiveMapEditorScreen> createState() => _InteractiveMapEditorScreenState();
}

class _InteractiveMapEditorScreenState extends State<InteractiveMapEditorScreen> {
  final fm.MapController _mapController = fm.MapController();
  ScreenshotController _screenshotController = ScreenshotController(); // Screenshotting is temporarily disabled
  late GameMapService _gameMapService;
  late GeocodingService _geocodingService;
  var uuid = Uuid();

  // State for the map editor
  GameMap _currentMap = GameMap(name: "Nouvelle Carte Interactive"); // Default for new map
  MapEditorMode _editorMode = MapEditorMode.view;

  TextEditingController _mapNameController = TextEditingController();
  TextEditingController _mapDescriptionController = TextEditingController();
  TextEditingController _searchAddressController = TextEditingController();

  List<LatLng> _currentBoundaryPoints = [];
  List<MapZone> _mapZones = [];
  List<MapPointOfInterest> _mapPois = [];
  List<LatLng> _currentZonePoints = []; // For drawing a new zone

  // Geocoding results
  List<GeocodingResult> _geocodingResults = [];
  bool _showGeocodingResults = false;
  FocusNode _searchFocusNode = FocusNode(); // To manage focus of search field

  // Default map center (Paris)
  LatLng _currentMapCenter = LatLng(48.8566, 2.3522);
  double _currentZoom = 13.0;
  String? _capturedImageBase64;
  fm.LatLngBounds? _capturedImageBounds; // To store bounds at the time of capture

  @override
  void initState() {
    super.initState();
    _gameMapService = GetIt.I<GameMapService>();
    _geocodingService = GetIt.I<GeocodingService>();

    if (widget.initialMap != null) {
      _currentMap = widget.initialMap!;
      _mapNameController.text = _currentMap.name;
      _mapDescriptionController.text = _currentMap.description ?? "";
      if (_currentMap.centerLatitude != null && _currentMap.centerLongitude != null) {
        _currentMapCenter = LatLng(_currentMap.centerLatitude!, _currentMap.centerLongitude!);
      }
      if (_currentMap.initialZoom != null) {
        _currentZoom = _currentMap.initialZoom!;
      }
      _capturedImageBase64 = _currentMap.backgroundImageBase64;
      _loadMapDetails();
    } else {
      _mapNameController.text = _currentMap.name;
    }

    _searchAddressController.addListener(() {
      if (_searchAddressController.text.isEmpty) {
        setState(() {
          _showGeocodingResults = false;
          _geocodingResults.clear();
        });
      }
    });

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _showGeocodingResults) {
        // If search field loses focus and results are shown,
        // consider hiding them after a small delay or if user taps outside.
        // For now, we rely on selection or clearing the field.
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _mapNameController.dispose();
    _mapDescriptionController.dispose();
    _searchAddressController.dispose();
    super.dispose();
  }

  void _loadMapDetails() {
    if (_currentMap.fieldBoundaryJson != null && _currentMap.fieldBoundaryJson!.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(_currentMap.fieldBoundaryJson!);
        _currentBoundaryPoints = decoded.map((p) => LatLng(Coordinate.fromJson(p).latitude, Coordinate.fromJson(p).longitude)).toList();
      } catch (e) {
        print("Error decoding fieldBoundaryJson: $e");
      }
    }
    if (_currentMap.mapZonesJson != null && _currentMap.mapZonesJson!.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(_currentMap.mapZonesJson!);
        _mapZones = decoded.map((z) => MapZone.fromJson(z as Map<String, dynamic>)).toList();
      } catch (e) {
        print("Error decoding mapZonesJson: $e");
      }
    }
    if (_currentMap.mapPointsOfInterestJson != null && _currentMap.mapPointsOfInterestJson!.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(_currentMap.mapPointsOfInterestJson!);
        _mapPois = decoded.map((p) => MapPointOfInterest.fromJson(p as Map<String, dynamic>)).toList();
      } catch (e) {
        print("Error decoding mapPointsOfInterestJson: $e");
      }
    }
    setState(() {});
  }

  void _handleSearchAddress() async {
    if (_searchAddressController.text.isEmpty) {
      setState(() {
        _geocodingResults.clear();
        _showGeocodingResults = false;
      });
      return;
    }
    FocusScope.of(context).unfocus(); // Hide keyboard
    try {
      List<GeocodingResult> results = await _geocodingService.searchAddress(_searchAddressController.text);
      setState(() {
        _geocodingResults = results;
        _showGeocodingResults = results.isNotEmpty;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur de géocodage: $e")));
      setState(() {
        _geocodingResults.clear();
        _showGeocodingResults = false;
      });
    }
  }

  void _selectGeocodingResult(GeocodingResult result) {
    setState(() {
      _currentMapCenter = LatLng(result.latitude, result.longitude);
      _currentZoom = 15.0; // Zoom in on search result
      _searchAddressController.text = result.displayName; // Update search field with selected address
      _geocodingResults.clear();
      _showGeocodingResults = false;
    });
    _mapController.move(_currentMapCenter, _currentZoom);
    FocusScope.of(context).unfocus(); // Hide keyboard and results list
  }

  void _onMapTap(fm.TapPosition tapPosition, LatLng point) {
    // Hide geocoding results if user taps on map
    if (_showGeocodingResults) {
      setState(() {
        _showGeocodingResults = false;
      });
    }

    setState(() {
      if (_editorMode == MapEditorMode.drawBoundary) {
        _currentBoundaryPoints.add(point);
      } else if (_editorMode == MapEditorMode.drawZone) {
        _currentZonePoints.add(point);
      } else if (_editorMode == MapEditorMode.placePoi) {
        _mapPois.add(MapPointOfInterest(
            id: uuid.v4(),
            name: "Nouveau POI",
            latitude: point.latitude,
            longitude: point.longitude,
            iconIdentifier: "default_poi_icon",
            type: "DEFAULT"
        ));
      }
    });
  }

  void _addCurrentZone() async {
    if (_currentZonePoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Une zone doit avoir au moins 3 points.")));
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return ZoneEditDialog();
      },
    );

    if (result != null && result.containsKey("name") && result.containsKey("color")) {
      setState(() {
        _mapZones.add(MapZone(
          id: uuid.v4(),
          name: result["name"]!,
          type: "DEFAULT",
          color: result["color"]!,
          zoneShape: _currentZonePoints.map((p) => Coordinate(latitude: p.latitude, longitude: p.longitude)).toList(),
          visible: true,
        ));
        _currentZonePoints.clear();
      });
    }
  }

  void _editZone(MapZone zoneToEdit) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return ZoneEditDialog(
          initialName: zoneToEdit.name,
          initialColor: _parseColor(zoneToEdit.color),
        );
      },
    );

    if (result != null && result.containsKey("name") && result.containsKey("color")) {
      setState(() {
        final index = _mapZones.indexWhere((z) => z.id == zoneToEdit.id);
        if (index != -1) {
          _mapZones[index] = zoneToEdit.copyWith(
            name: result["name"]!,
            color: result["color"]!,
          );
        }
      });
    }
  }

  void _toggleZoneVisibility(MapZone zoneToToggle) {
    setState(() {
      final index = _mapZones.indexWhere((z) => z.id == zoneToToggle.id);
      if (index != -1) {
        _mapZones[index] = zoneToToggle.copyWith(visible: !zoneToToggle.visible);
      }
    });
  }

  void _deleteZone(MapZone zoneToDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Supprimer la Zone"),
          content: Text("Êtes-vous sûr de vouloir supprimer la zone \"${zoneToDelete.name}\" ?"),
          actions: <Widget>[
            TextButton(
              child: Text("Annuler"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Supprimer"),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _mapZones.removeWhere((z) => z.id == zoneToDelete.id);
                });
              },
            ),
          ],
        );
      },
    );
  }

  // Screenshotting is temporarily disabled
  Future<void> _captureMapBackground() async {
    try {
      Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        setState(() {
          _capturedImageBase64 = base64Encode(imageBytes);
          _capturedImageBounds = _mapController.bounds; // Store current map bounds
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fond de carte capturé!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur de capture: $e")));
    }
  }

  void _saveMap() async {
    List<Coordinate> boundaryCoords = _currentBoundaryPoints.map((p) => Coordinate(latitude: p.latitude, longitude: p.longitude)).toList();

    final updatedMap = _currentMap.copyWith(
      name: _mapNameController.text,
      description: _mapDescriptionController.text,
      sourceAddress: _searchAddressController.text.isNotEmpty ? _searchAddressController.text : null,
      centerLatitude: _mapController.center.latitude,
      centerLongitude: _mapController.center.longitude,
      initialZoom: _mapController.zoom,
      fieldBoundaryJson: boundaryCoords.isNotEmpty ? jsonEncode(boundaryCoords.map((c) => c.toJson()).toList()) : null,
      mapZonesJson: _mapZones.isNotEmpty ? jsonEncode(_mapZones.map((z) => z.toJson()).toList()) : null,
      mapPointsOfInterestJson: _mapPois.isNotEmpty ? jsonEncode(_mapPois.map((p) => p.toJson()).toList()) : null,
      backgroundImageBase64: _capturedImageBase64,
    );

    try {
      GameMap mapToReturn;
      if (updatedMap.id != null) {
        await _gameMapService.updateGameMap(updatedMap);
        mapToReturn = updatedMap;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Carte mise à jour avec succès!")));
      } else {
        await _gameMapService.addGameMap(updatedMap);
        mapToReturn = updatedMap;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Carte créée avec succès!")));
      }
      if (Navigator.canPop(context)) {
        Navigator.pop(context, mapToReturn);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de la sauvegarde: $e")));
    }
  }

  Widget _buildModeToggle() {
    return SegmentedButton<MapEditorMode>(
      segments: const <ButtonSegment<MapEditorMode>>[
        ButtonSegment<MapEditorMode>(value: MapEditorMode.view, label: Text("Vue"), icon: Icon(Icons.visibility)),
        ButtonSegment<MapEditorMode>(value: MapEditorMode.drawBoundary, label: Text("Limites"), icon: Icon(Icons.polyline)),
        ButtonSegment<MapEditorMode>(value: MapEditorMode.drawZone, label: Text("Zone"), icon: Icon(Icons.crop_square)),
        ButtonSegment<MapEditorMode>(value: MapEditorMode.placePoi, label: Text("Points"), icon: Icon(Icons.place)), // Terme POI changé
      ],
      selected: <MapEditorMode>{_editorMode},
      onSelectionChanged: (Set<MapEditorMode> newSelection) {
        setState(() {
          _editorMode = newSelection.first;
          _currentZonePoints.clear(); // Clear temp zone points when changing mode
          _showGeocodingResults = false; // Hide results when changing mode
        });
      },
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith("#")) {
        String hexColor = colorString.substring(1);
        if (hexColor.length == 6) {
          hexColor = "FF" + hexColor;
        }
        if (hexColor.length == 8) {
          return Color(int.parse(hexColor, radix: 16));
        }
      }
    } catch (e) {
      print("Error parsing color: $e, for color string: $colorString");
    }
    return Colors.grey.withOpacity(0.5);
  }

  Widget _buildGeocodingResultsList() {
    if (!_showGeocodingResults || _geocodingResults.isEmpty) {
      return SizedBox.shrink();
    }
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _geocodingResults.length,
        itemBuilder: (context, index) {
          final result = _geocodingResults[index];
          return ListTile(
            title: Text(result.displayName),
            onTap: () => _selectGeocodingResult(result),
          );
        },
      ),
    );
  }

  Widget _buildZoneManagementList() {
    if (_mapZones.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: Text("Aucune zone définie pour le moment.")),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Text("Gestion des Zones", style: Theme.of(context).textTheme.titleMedium),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(), // To use inside Column
          itemCount: _mapZones.length,
          itemBuilder: (context, index) {
            final zone = _mapZones[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _parseColor(zone.color),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black54, width: 1),
                  ),
                ),
                title: Text(zone.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(zone.visible ? Icons.visibility : Icons.visibility_off),
                      tooltip: zone.visible ? "Masquer" : "Afficher",
                      onPressed: () => _toggleZoneVisibility(zone),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit),
                      tooltip: "Éditer",
                      onPressed: () => _editZone(zone),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red[700]),
                      tooltip: "Supprimer",
                      onPressed: () => _deleteZone(zone),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<fm.Polygon> polygonsToDisplay = [];
    if (_currentBoundaryPoints.isNotEmpty) {
      polygonsToDisplay.add(fm.Polygon(
        points: _currentBoundaryPoints,
        color: Colors.blue.withOpacity(0.3),
        borderColor: Colors.blue,
        borderStrokeWidth: 2,
        isFilled: true,
      ));
    }
    for (var zone in _mapZones) {
      if (zone.visible) {
        polygonsToDisplay.add(fm.Polygon(
          points: zone.zoneShape.map((c) => LatLng(c.latitude, c.longitude)).toList(),
          color: _parseColor(zone.color).withOpacity(0.5),
          borderColor: _parseColor(zone.color),
          borderStrokeWidth: 2,
          isFilled: true,
        ));
      }
    }
    if (_currentZonePoints.isNotEmpty) {
      polygonsToDisplay.add(fm.Polygon(
        points: _currentZonePoints,
        color: Colors.green.withOpacity(0.3),
        borderColor: Colors.green,
        borderStrokeWidth: 1,
        isFilled: true,
      ));
    }

    List<fm.Marker> markersToDisplay = _mapPois.map((poi) {
      return fm.Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(poi.latitude, poi.longitude),
        child: Tooltip(
          message: poi.name,
          child: Icon(Icons.location_pin, color: Colors.red, size: 30),
        ),
      );
    }).toList();

    List<fm.OverlayImage> overlayImages = [];
    if (_capturedImageBase64 != null && _capturedImageBase64!.isNotEmpty && _capturedImageBounds != null) {
      overlayImages.add(
        fm.OverlayImage(
          bounds: _capturedImageBounds!,
          imageProvider: MemoryImage(base64Decode(_capturedImageBase64!)),
          opacity: 0.8,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialMap == null ? "Créer Carte Interactive" : "Éditer Carte Interactive"),
        actions: [
          IconButton(icon: Icon(Icons.camera_alt), onPressed: _captureMapBackground, tooltip: "Capturer fond de carte"),
          IconButton(icon: Icon(Icons.save), onPressed: _saveMap, tooltip: "Sauvegarder la carte"),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView( // Ajout de SingleChildScrollView pour les contrôles du haut
              child: Column(
                children: [
                  TextField(
                    controller: _mapNameController,
                    decoration: InputDecoration(labelText: "Nom de la carte"),
                  ),
                  TextField(
                    controller: _mapDescriptionController,
                    decoration: InputDecoration(labelText: "Description"),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchAddressController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(labelText: "Rechercher une adresse"),
                          onSubmitted: (_) => _handleSearchAddress(),
                          onChanged: (text) {
                            if (text.isEmpty) {
                              setState(() {
                                _showGeocodingResults = false;
                                _geocodingResults.clear();
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(icon: Icon(Icons.search), onPressed: _handleSearchAddress),
                    ],
                  ),
                  _buildGeocodingResultsList(),
                  SizedBox(height: 8),
                  _buildModeToggle(),
                  if (_editorMode == MapEditorMode.drawBoundary)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        alignment: WrapAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(onPressed: () {
                            if (_currentBoundaryPoints.isNotEmpty) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("Confirmer l'effacement"),
                                    content: Text("Redessiner les limites effacera toutes les zones et points stratégiques existants. Voulez-vous continuer ?"),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text("Annuler"),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                      TextButton(
                                        child: Text("Confirmer"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          setState(() {
                                            _currentBoundaryPoints.clear();
                                            _mapZones.clear();
                                            _mapPois.clear();
                                            _capturedImageBase64 = null;
                                            _capturedImageBounds = null;
                                          });
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              setState(() => _currentBoundaryPoints.clear());
                            }
                          }, child: Text("Effacer limites") ),
                          if(_currentBoundaryPoints.isNotEmpty) ElevatedButton(onPressed: () => setState(() => _currentBoundaryPoints.removeLast()), child: Text("Annuler dernier point") ),
                        ],
                      ),
                    ),
                  if (_editorMode == MapEditorMode.drawZone)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        alignment: WrapAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(onPressed: _addCurrentZone, child: Text("Terminer Zone Actuelle")),
                          ElevatedButton(onPressed: () => setState(() => _currentZonePoints.clear()), child: Text("Effacer Zone Actuelle") ),
                          if(_currentZonePoints.isNotEmpty) ElevatedButton(onPressed: () => setState(() => _currentZonePoints.removeLast()), child: Text("Annuler point") ),
                        ],
                      ),
                    ),
                  // Affichage de la liste de gestion des zones
                  if (_editorMode == MapEditorMode.view || _editorMode == MapEditorMode.drawZone)
                    _buildZoneManagementList(),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                fm.FlutterMap(
                  mapController: _mapController,
                  options: fm.MapOptions(
                    center: _currentMapCenter,
                    zoom: _currentZoom,
                    onTap: _onMapTap,
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture) {
                        setState(() {
                          _currentMapCenter = position.center!;
                          _currentZoom = position.zoom!;
                        });
                      }
                    },
                  ),
                  children: [
                    fm.TileLayer(
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: "com.airsoft.gamemapmaster",
                    ),
                    if (overlayImages.isNotEmpty)
                      fm.OverlayImageLayer(overlayImages: overlayImages),
                    if (polygonsToDisplay.isNotEmpty)
                      fm.PolygonLayer(polygons: polygonsToDisplay),
                    if (markersToDisplay.isNotEmpty)
                      fm.MarkerLayer(markers: markersToDisplay),
                  ],
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Column(
                    children: <Widget>[
                      FloatingActionButton(
                        heroTag: "zoomInButton",
                        mini: true,
                        onPressed: () {
                          setState(() {
                            _currentZoom = _mapController.zoom + 1;
                            _mapController.move(_mapController.center, _currentZoom);
                          });
                        },
                        child: Icon(Icons.add),
                      ),
                      SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: "zoomOutButton",
                        mini: true,
                        onPressed: () {
                          setState(() {
                            _currentZoom = _mapController.zoom - 1;
                            _mapController.move(_mapController.center, _currentZoom);
                          });
                        },
                        child: Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

