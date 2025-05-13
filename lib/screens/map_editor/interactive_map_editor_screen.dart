// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import "package:airsoft_game_map/models/coordinate.dart";
import "package:airsoft_game_map/models/game_map.dart";
import "package:airsoft_game_map/models/geocoding_result.dart";
import "package:airsoft_game_map/models/map_point_of_interest.dart";
import "package:airsoft_game_map/models/map_zone.dart";
import "package:airsoft_game_map/services/game_map_service.dart";
import "package:airsoft_game_map/services/geocoding_service.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:get_it/get_it.dart";
import "package:latlong2/latlong.dart";
import "package:screenshot/screenshot.dart";
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
  final MapController _mapController = MapController();
  ScreenshotController _screenshotController = ScreenshotController();
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

  // Default map center (Paris)
  LatLng _currentMapCenter = LatLng(48.8566, 2.3522);
  double _currentZoom = 13.0;
  String? _capturedImageBase64;
  LatLngBounds? _capturedImageBounds; // To store bounds at the time of capture

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
    if (_searchAddressController.text.isEmpty) return;
    try {
      List<GeocodingResult> results = await _geocodingService.searchAddress(_searchAddressController.text);
      if (results.isNotEmpty) {
        final firstResult = results.first;
        setState(() {
          _currentMapCenter = LatLng(firstResult.latitude, firstResult.longitude);
          _currentZoom = 15.0; // Zoom in on search result
        });
        _mapController.move(_currentMapCenter, _currentZoom);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur de géocodage: $e")));
    }
  }
  
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      if (_editorMode == MapEditorMode.drawBoundary) {
        _currentBoundaryPoints.add(point);
      } else if (_editorMode == MapEditorMode.drawZone) {
        _currentZonePoints.add(point);
      } else if (_editorMode == MapEditorMode.placePoi) {
        // For simplicity, add a default POI. In a real app, show a dialog to enter details.
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

  void _addCurrentZone() {
    if (_currentZonePoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Une zone doit avoir au moins 3 points.")));
      return;
    }
    // For simplicity, add a default Zone. In a real app, show a dialog to enter details.
    setState(() {
      _mapZones.add(MapZone(
        id: uuid.v4(), 
        name: "Nouvelle Zone", 
        type: "DEFAULT", 
        color: "#FF0000FF", // Red with alpha 
        zoneShape: _currentZonePoints.map((p) => Coordinate(latitude: p.latitude, longitude: p.longitude)).toList()
      ));
      _currentZonePoints.clear();
    });
  }

  Future<void> _captureMapBackground() async {
    try {
      Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        setState(() {
          _capturedImageBase64 = base64Encode(imageBytes);
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
        ButtonSegment<MapEditorMode>(value: MapEditorMode.placePoi, label: Text("POI"), icon: Icon(Icons.place)),
      ],
      selected: <MapEditorMode>{_editorMode},
      onSelectionChanged: (Set<MapEditorMode> newSelection) {
        setState(() {
          _editorMode = newSelection.first;
          _currentZonePoints.clear(); // Clear temp zone points when changing mode
        });
      },
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith("#")) {
        return Color(int.parse(colorString.substring(1), radix: 16));
      }
    } catch (e) {
      print("Error parsing color: $e");
    }
    return Colors.grey.withOpacity(0.5); // Default color
  }

  @override
  Widget build(BuildContext context) {
    List<Polygon> polygonsToDisplay = [];
    if (_currentBoundaryPoints.isNotEmpty) {
      polygonsToDisplay.add(Polygon(
        points: _currentBoundaryPoints,
        color: Colors.blue.withOpacity(0.3),
        borderColor: Colors.blue,
        borderStrokeWidth: 2,
        isFilled: true,
      ));
    }
    for (var zone in _mapZones) {
      polygonsToDisplay.add(Polygon(
        points: zone.zoneShape.map((c) => LatLng(c.latitude, c.longitude)).toList(),
        color: _parseColor(zone.color).withOpacity(0.5),
        borderColor: _parseColor(zone.color),
        borderStrokeWidth: 2,
        isFilled: true,
      ));
    }
    if (_currentZonePoints.isNotEmpty) { // Display zone being currently drawn
        polygonsToDisplay.add(Polygon(
            points: _currentZonePoints,
            color: Colors.green.withOpacity(0.3),
            borderColor: Colors.green,
            borderStrokeWidth: 1,
            isFilled: true,
        ));
    }

    List<Marker> markersToDisplay = _mapPois.map((poi) {
      return Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(poi.latitude, poi.longitude),
        child: Tooltip(
          message: poi.name,
          child: Icon(Icons.location_pin, color: Colors.red, size: 30),
        ),
      );
    }).toList();

    List<OverlayImage> overlayImages = [];
    if (_capturedImageBase64 != null && _capturedImageBase64!.isNotEmpty && _capturedImageBounds != null) {
      overlayImages.add(
        OverlayImage(
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
                        decoration: InputDecoration(labelText: "Rechercher une adresse"),
                        onSubmitted: (_) => _handleSearchAddress(),
                      ),
                    ),
                    IconButton(icon: Icon(Icons.search), onPressed: _handleSearchAddress),
                  ],
                ),
                SizedBox(height: 8),
                _buildModeToggle(),
                if (_editorMode == MapEditorMode.drawBoundary)
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                     ElevatedButton(onPressed: () => setState(() => _currentBoundaryPoints.clear()), child: Text("Effacer limites") ),
                     if(_currentBoundaryPoints.isNotEmpty) ElevatedButton(onPressed: () => setState(() => _currentBoundaryPoints.removeLast()), child: Text("Annuler dernier point") ),
                  ]),
                if (_editorMode == MapEditorMode.drawZone)
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    ElevatedButton(onPressed: _addCurrentZone, child: Text("Ajouter Zone Actuelle")),
                    ElevatedButton(onPressed: () => setState(() => _currentZonePoints.clear()), child: Text("Effacer Zone Actuelle") ),
                    if(_currentZonePoints.isNotEmpty) ElevatedButton(onPressed: () => setState(() => _currentZonePoints.removeLast()), child: Text("Annuler point") ),
                  ]),
              ],
            ),
          ),
          Expanded(
            child: Screenshot(
              controller: _screenshotController,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _currentMapCenter,
                  zoom: _currentZoom,
                  onTap: _onMapTap,
                  onPositionChanged: (position, hasGesture) {
                    // If we want the overlay to stick to the map while panning/zooming *after* capture,
                    // we might need to update _capturedImageBounds here, or re-capture.
                    // For now, the captured image is fixed to the bounds at the moment of capture.
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ["a", "b", "c"],
                    userAgentPackageName: "com.airsoft.gamemapmaster",
                  ),
                  if (overlayImages.isNotEmpty)
                    OverlayImageLayer(overlayImages: overlayImages),
                  if (polygonsToDisplay.isNotEmpty)
                    PolygonLayer(polygons: polygonsToDisplay),
                  if (markersToDisplay.isNotEmpty)
                    MarkerLayer(markers: markersToDisplay),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

