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
enum MapEditorMode { view, drawBoundary, drawZone, placePoi }

// Enum for Tile Layer Types
enum TileLayerType {
  osm, // OpenStreetMap standard
  satellite // Satellite view
}

class InteractiveMapEditorScreen extends StatefulWidget {
  final GameMap? initialMap; // Pass a map to edit, or null to create new

  const InteractiveMapEditorScreen({Key? key, this.initialMap})
      : super(key: key);

  @override
  State<InteractiveMapEditorScreen> createState() =>
      _InteractiveMapEditorScreenState();
}

class _InteractiveMapEditorScreenState
    extends State<InteractiveMapEditorScreen> {
  final fm.MapController _mapController = fm.MapController();
  ScreenshotController _screenshotController =
      ScreenshotController(); // Screenshotting is temporarily disabled
  late GameMapService _gameMapService;
  late GeocodingService _geocodingService;
  var uuid = Uuid();

  // State for the map editor
  GameMap _currentMap =
      GameMap(name: "Nouvelle Carte Interactive"); // Default for new map
  MapEditorMode _editorMode = MapEditorMode.view;
  TileLayerType _currentTileLayerType = TileLayerType.osm;

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

  // Tile layer URLs
  final String _osmTileUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
  final String _esriWorldImageryTileUrl =
      "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}";

  // Google Maps Satellite URL (requires API key, to be added if Esri fails or user prefers)
  // final String _googleSatelliteTileUrl = "https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}&key=YOUR_API_KEY";

  String _activeTileUrl = "";
  List<String> _activeTileSubdomains = [];

  String? _capturedImageBase64;
  fm.LatLngBounds?
      _capturedImageBounds; // To store bounds at the time of capture

  @override
  void initState() {
    super.initState();
    _gameMapService = GetIt.I<GameMapService>();
    _geocodingService = GetIt.I<GeocodingService>();

    _updateActiveTileLayer(); // Set initial tile layer based on _currentTileLayerType

    if (widget.initialMap != null) {
      _currentMap = widget.initialMap!;
      _mapNameController.text = _currentMap.name;
      _mapDescriptionController.text = _currentMap.description ?? "";
      if (_currentMap.centerLatitude != null &&
          _currentMap.centerLongitude != null) {
        _currentMapCenter =
            LatLng(_currentMap.centerLatitude!, _currentMap.centerLongitude!);
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
        // Optional: hide results if focus is lost and no result was clicked
      }
    });
  }

  void _updateActiveTileLayer() {
    setState(() {
      if (_currentTileLayerType == TileLayerType.satellite) {
        _activeTileUrl = _esriWorldImageryTileUrl;
        _activeTileSubdomains =
            []; // Esri typically doesn't use subdomains like a,b,c
      } else {
        // Default to OSM
        _activeTileUrl = _osmTileUrl;
        _activeTileSubdomains = [];
      }
    });
  }

  void _toggleTileLayer() {
    setState(() {
      if (_currentTileLayerType == TileLayerType.osm) {
        _currentTileLayerType = TileLayerType.satellite;
      } else {
        _currentTileLayerType = TileLayerType.osm;
      }
      _updateActiveTileLayer();
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
    if (_currentMap.fieldBoundaryJson != null &&
        _currentMap.fieldBoundaryJson!.isNotEmpty) {
      try {
        final List<dynamic> decoded =
            jsonDecode(_currentMap.fieldBoundaryJson!);
        _currentBoundaryPoints = decoded
            .map((p) => LatLng(Coordinate.fromJson(p).latitude,
                Coordinate.fromJson(p).longitude))
            .toList();
      } catch (e) {
        print("Error decoding fieldBoundaryJson: $e");
      }
    }
    if (_currentMap.mapZonesJson != null &&
        _currentMap.mapZonesJson!.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(_currentMap.mapZonesJson!);
        _mapZones = decoded
            .map((z) => MapZone.fromJson(z as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print("Error decoding mapZonesJson: $e");
      }
    }
    if (_currentMap.mapPointsOfInterestJson != null &&
        _currentMap.mapPointsOfInterestJson!.isNotEmpty) {
      try {
        final List<dynamic> decoded =
            jsonDecode(_currentMap.mapPointsOfInterestJson!);
        _mapPois = decoded
            .map((p) => MapPointOfInterest.fromJson(p as Map<String, dynamic>))
            .toList();
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
      List<GeocodingResult> results =
          await _geocodingService.searchAddress(_searchAddressController.text);
      setState(() {
        _geocodingResults = results;
        _showGeocodingResults = results.isNotEmpty;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur de géocodage: $e")));
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
      _searchAddressController.text =
          result.displayName; // Update search field with selected address
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
            type: "DEFAULT"));
      }
    });
  }

  void _addCurrentZone() async {
    if (_currentZonePoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Une zone doit avoir au moins 3 points.")));
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return ZoneEditDialog();
      },
    );

    if (result != null &&
        result.containsKey("name") &&
        result.containsKey("color")) {
      setState(() {
        _mapZones.add(MapZone(
          id: uuid.v4(),
          name: result["name"]!,
          type: "DEFAULT",
          color: result["color"]!,
          zoneShape: _currentZonePoints
              .map((p) =>
                  Coordinate(latitude: p.latitude, longitude: p.longitude))
              .toList(),
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

    if (result != null &&
        result.containsKey("name") &&
        result.containsKey("color")) {
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
        _mapZones[index] =
            zoneToToggle.copyWith(visible: !zoneToToggle.visible);
      }
    });
  }

  void _deleteZone(MapZone zoneToDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Supprimer la Zone"),
          content: Text(
              "Êtes-vous sûr de vouloir supprimer la zone \"${zoneToDelete.name}\" ?"),
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

  String? _latLngBoundsToJson(fm.LatLngBounds? bounds) {
    if (bounds == null) return null;
    return jsonEncode({
      "neLat": bounds.northEast.latitude,
      "neLng": bounds.northEast.longitude,
      "swLat": bounds.southWest.latitude,
      "swLng": bounds.southWest.longitude,
    });
  }

  Future<void> _captureAndStoreMapBackground(
      TileLayerType layerType, bool isSatelliteViewForStorage) async {
    String tileUrlToCapture;
    List<String> subdomainsToCapture;

    if (layerType == TileLayerType.satellite) {
      tileUrlToCapture = _esriWorldImageryTileUrl; // Ou Google si Esri échoue
      subdomainsToCapture = [];
    } else {
      tileUrlToCapture = _osmTileUrl;
      subdomainsToCapture = [];
    }

    // Forcer le changement de la couche active pour la capture
    setState(() {
      _activeTileUrl = tileUrlToCapture;
      _activeTileSubdomains = subdomainsToCapture;
    });

    // Attendre que flutter_map ait une chance de charger les nouvelles tuiles
    // Ce délai est empirique. Une meilleure solution serait un callback onTilesLoaded.
    await Future.delayed(Duration(milliseconds: 2000));

    try {
      Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        final String imageBase64 = base64Encode(imageBytes);
        final fm.LatLngBounds? capturedBounds = _mapController.bounds;
        final String? boundsJson = _latLngBoundsToJson(capturedBounds);

        setState(() {
          if (isSatelliteViewForStorage) {
            _currentMap = _currentMap.copyWith(
              satelliteImageBase64: imageBase64,
              satelliteBoundsJson: boundsJson,
            );
          } else {
            _currentMap = _currentMap.copyWith(
              backgroundImageBase64: imageBase64,
              backgroundBoundsJson: boundsJson,
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Erreur de capture (imageBytes est null) pour ${layerType.name}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de capture (${layerType.name}): $e")));
    }
  }

  Future<void> _captureDualMapBackgrounds() async {
    if (_currentBoundaryPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Veuillez d\"abord délimiter le terrain avec au moins 3 points.")));
      return;
    }

    TileLayerType originalView = _currentTileLayerType;

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Capture du fond de carte standard...")));
    await _captureAndStoreMapBackground(TileLayerType.osm, false);

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Capture du fond de carte satellite...")));
    await _captureAndStoreMapBackground(TileLayerType.satellite, true);

    // Restaurer la vue active initiale après les captures
    setState(() {
      _currentTileLayerType = originalView;
      _updateActiveTileLayer();
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Fonds de carte capturés!")));
  }

  void _saveMap() async {
    List<Coordinate> boundaryCoords = _currentBoundaryPoints
        .map((p) => Coordinate(latitude: p.latitude, longitude: p.longitude))
        .toList();

    final updatedMap = _currentMap.copyWith(
      name: _mapNameController.text,
      description: _mapDescriptionController.text,
      sourceAddress: _searchAddressController.text.isNotEmpty
          ? _searchAddressController.text
          : null,
      centerLatitude: _mapController.center.latitude,
      centerLongitude: _mapController.center.longitude,
      initialZoom: _mapController.zoom,
      fieldBoundaryJson: boundaryCoords.isNotEmpty
          ? jsonEncode(boundaryCoords.map((c) => c.toJson()).toList())
          : null,
      mapZonesJson: _mapZones.isNotEmpty
          ? jsonEncode(_mapZones.map((z) => z.toJson()).toList())
          : null,
      mapPointsOfInterestJson: _mapPois.isNotEmpty
          ? jsonEncode(_mapPois.map((p) => p.toJson()).toList())
          : null,
    );

    try {
      GameMap mapToReturn;
      if (updatedMap.id != null) {
        await _gameMapService.updateGameMap(updatedMap);
        mapToReturn = updatedMap;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Carte mise à jour avec succès!")));
      } else {
        await _gameMapService.addGameMap(updatedMap);
        mapToReturn = updatedMap;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Carte créée avec succès!")));
      }
      if (Navigator.canPop(context)) {
        Navigator.pop(context, mapToReturn);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la sauvegarde: $e")));
    }
  }

  Widget _buildModeToggle() {
    return SegmentedButton<MapEditorMode>(
      segments: const <ButtonSegment<MapEditorMode>>[
        ButtonSegment<MapEditorMode>(
            value: MapEditorMode.view,
            label: Text("Vue"),
            icon: Icon(Icons.visibility)),
        ButtonSegment<MapEditorMode>(
            value: MapEditorMode.drawBoundary,
            label: Text("Limites"),
            icon: Icon(Icons.polyline)),
        ButtonSegment<MapEditorMode>(
            value: MapEditorMode.drawZone,
            label: Text("Zone"),
            icon: Icon(Icons.crop_square)),
        ButtonSegment<MapEditorMode>(
            value: MapEditorMode.placePoi,
            label: Text("Points"),
            icon: Icon(Icons.place)), // Terme POI changé
      ],
      selected: <MapEditorMode>{_editorMode},
      onSelectionChanged: (Set<MapEditorMode> newSelection) {
        setState(() {
          _editorMode = newSelection.first;
          _currentZonePoints
              .clear(); // Clear temp zone points when changing mode
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
          child: Text("Gestion des Zones",
              style: Theme.of(context).textTheme.titleMedium),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(), // To use inside Column
          itemCount: _mapZones.length,
          itemBuilder: (context, index) {
            final zone = _mapZones[index];
            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                      icon: Icon(zone.visible
                          ? Icons.visibility
                          : Icons.visibility_off),
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
  @override
  Widget build(BuildContext context) {
    List<fm.Polygon> polygons =
        _mapZones.where((zone) => zone.visible).map((zone) {
      return fm.Polygon(
        points:
            zone.zoneShape.map((p) => LatLng(p.latitude, p.longitude)).toList(),
        color: _parseColor(zone.color),
        borderColor: Colors.black,
        borderStrokeWidth: 1,
        isFilled: true,
      );
    }).toList();

    if (_currentZonePoints.isNotEmpty) {
      polygons.add(fm.Polygon(
        points: _currentZonePoints,
        color: Colors.blue.withOpacity(0.3),
        borderColor: Colors.blueAccent,
        borderStrokeWidth: 2,
        isFilled: true,
      ));
    }

    List<fm.Marker> markers = _mapPois.map((poi) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialMap == null
            ? "Créer Carte Interactive"
            : "Éditer Carte Interactive"),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            tooltip: "Sauvegarder la carte",
            onPressed: _saveMap,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildModeToggle(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: _searchAddressController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                labelText: "Rechercher une adresse",
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _handleSearchAddress,
                ),
              ),
              onSubmitted: (_) => _handleSearchAddress(),
            ),
          ),
          _buildGeocodingResultsList(),
          Expanded(
            child: Screenshot(
              controller: _screenshotController,
              child: fm.FlutterMap(
                mapController: _mapController,
                options: fm.MapOptions(
                  center: _currentMapCenter,
                  zoom: _currentZoom,
                  onTap: _onMapTap,
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture) {
                      _currentMapCenter = position.center ?? _currentMapCenter;
                      _currentZoom = position.zoom ?? _currentZoom;
                    }
                  },
                ),
                children: [
                  fm.TileLayer(
                    urlTemplate: _activeTileUrl,
                    subdomains: _activeTileSubdomains,
                    userAgentPackageName: "com.airsoft.gamemapmaster",
                  ),
                  if (_currentBoundaryPoints.length > 1)
                    fm.PolylineLayer(
                      polylines: [
                        fm.Polyline(
                          points: _currentBoundaryPoints,
                          strokeWidth: 3.0,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  if (_currentBoundaryPoints.length > 2 &&
                      _editorMode == MapEditorMode.drawBoundary)
                    fm.PolygonLayer(polygons: [
                      fm.Polygon(
                        points: _currentBoundaryPoints,
                        color: Colors.red.withOpacity(0.1),
                        borderColor: Colors.red,
                        borderStrokeWidth: 1,
                        isFilled: true,
                      )
                    ]),
                  fm.PolygonLayer(polygons: polygons),
                  fm.MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
          if (_editorMode == MapEditorMode.drawBoundary)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.check_circle_outline),
                    label: Text("Fixer Limites & Capturer Fonds"),
                    onPressed: _captureDualMapBackgrounds,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700]),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.undo),
                    label: Text("Annuler Dernier Point"),
                    onPressed: () {
                      setState(() {
                        if (_currentBoundaryPoints.isNotEmpty)
                          _currentBoundaryPoints.removeLast();
                      });
                    },
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.delete_sweep),
                    label: Text("Effacer Limites"),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Confirmation"),
                            content: Text(
                                "Effacer les limites effacera également les fonds de carte capturés, les zones et les points stratégiques. Continuer ?"),
                            actions: <Widget>[
                              TextButton(
                                child: Text("Annuler"),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              TextButton(
                                child: Text("Effacer"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    _currentBoundaryPoints.clear();
                                    _currentMap = _currentMap.copyWith(
                                      backgroundImageBase64: null,
                                      backgroundBoundsJson: null,
                                      satelliteImageBase64: null,
                                      satelliteBoundsJson: null,
                                      mapZonesJson: null,
                                      mapPointsOfInterestJson: null,
                                    );
                                    _mapZones.clear();
                                    _mapPois.clear();
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700]),
                  ),
                ],
              ),
            ),
          if (_editorMode == MapEditorMode.drawZone)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.check_circle_outline),
                    label: Text("Valider Zone"),
                    onPressed: _addCurrentZone,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700]),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.undo),
                    label: Text("Annuler Dernier Point"),
                    onPressed: () {
                      setState(() {
                        if (_currentZonePoints.isNotEmpty)
                          _currentZonePoints.removeLast();
                      });
                    },
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.delete_sweep),
                    label: Text("Effacer Zone en Cours"),
                    onPressed: () {
                      setState(() {
                        _currentZonePoints.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700]),
                  ),
                ],
              ),
            ),
          if (_editorMode == MapEditorMode.view) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                      icon: Icon(Icons.zoom_in),
                      onPressed: () => _mapController.move(
                          _mapController.center, _mapController.zoom + 1),
                      tooltip: "Zoom In"),
                  IconButton(
                      icon: Icon(Icons.layers),
                      onPressed: _toggleTileLayer,
                      tooltip: "Changer Vue (Carte/Satellite)"),
                  IconButton(
                      icon: Icon(Icons.zoom_out),
                      onPressed: () => _mapController.move(
                          _mapController.center, _mapController.zoom - 1),
                      tooltip: "Zoom Out"),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildZoneManagementList(),
                  // TODO: Ajouter la liste de gestion des POI ici
                ],
              ),
            )
          ]
        ],
      ),
    );
  }
}
