// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'dart:math' as math;

import "package:game_map_master_flutter_app/models/coordinate.dart";
import "package:game_map_master_flutter_app/models/game_map.dart";
import "package:game_map_master_flutter_app/models/geocoding_result.dart";
import "package:game_map_master_flutter_app/models/map_point_of_interest.dart";
import "package:game_map_master_flutter_app/models/map_zone.dart";
import "package:game_map_master_flutter_app/services/game_map_service.dart";
import "package:game_map_master_flutter_app/services/geocoding_service.dart";
import "package:game_map_master_flutter_app/widgets/zone_edit_dialog.dart";
import "package:game_map_master_flutter_app/widgets/poi_edit_dialog.dart"; // Import POI edit dialog
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart" as fm;
import "package:get_it/get_it.dart";
import "package:latlong2/latlong.dart";
import "package:screenshot/screenshot.dart";
import "dart:convert";
import "dart:typed_data";
import "package:uuid/uuid.dart";
import 'package:game_map_master_flutter_app/utils/logger.dart';

import "../../generated/l10n/app_localizations.dart";
// Enum to manage editor modes
enum MapEditorMode { view, drawBoundary, drawZone, placePoi }

// Enum for Tile Layer Types
enum TileLayerType {
  osm, // OpenStreetMap standard
  satellite // Satellite view
}

class InteractiveMapEditorScreen extends StatefulWidget {
  final GameMap? initialMap;

  const InteractiveMapEditorScreen({Key? key, this.initialMap})
      : super(key: key);

  @override
  State<InteractiveMapEditorScreen> createState() =>
      _InteractiveMapEditorScreenState();
}

class _InteractiveMapEditorScreenState
    extends State<InteractiveMapEditorScreen> {
  final fm.MapController _mapController = fm.MapController();
  ScreenshotController _screenshotController = ScreenshotController();
  late GameMapService _gameMapService;
  late GeocodingService _geocodingService;
  var uuid = Uuid();

  GameMap _currentMap = GameMap(name: "Nouvelle Carte Interactive");//@todo Will be set in initState with l10n
  MapEditorMode _editorMode = MapEditorMode.view;
  TileLayerType _currentTileLayerType = TileLayerType.osm;

  TextEditingController _mapNameController = TextEditingController();
  TextEditingController _mapDescriptionController = TextEditingController();
  TextEditingController _searchAddressController = TextEditingController();

  List<LatLng> _currentBoundaryPoints = [];
  List<MapZone> _mapZones = [];
  List<MapPointOfInterest> _mapPois = [];
  List<LatLng> _currentZonePoints = [];

  List<GeocodingResult> _geocodingResults = [];
  bool _showGeocodingResults = false;
  FocusNode _searchFocusNode = FocusNode();

  LatLng _currentMapCenter = LatLng(48.8566, 2.3522);
  double _currentZoom = 13.0;

  // Définir les limites de zoom min et max
  final double _minZoom = 3.0;
  final double _maxZoom = 20.0; // Augmenté pour permettre plus de zoom

  final String _osmTileUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
  final String _esriWorldImageryTileUrl =
      "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}";

  String _activeTileUrl = "";
  List<String> _activeTileSubdomains = [];

  // Available icons for POIs (mirrored from PoiEditDialog for now)
  List<Map<String, dynamic>> _getAvailableIcons(AppLocalizations l10n) {
    return [
      {"identifier": "flag", "icon": Icons.flag, "label": l10n.poiIconFlag},
      {"identifier": "bomb", "icon": Icons.dangerous, "label": l10n.poiIconBomb},
      {"identifier": "star", "icon": Icons.star, "label": l10n.poiIconStar},
      {"identifier": "place", "icon": Icons.place, "label": l10n.poiIconPlace},
      {"identifier": "pin_drop", "icon": Icons.pin_drop, "label": l10n.poiIconPinDrop},
      {"identifier": "house", "icon": Icons.house, "label": l10n.poiIconHouse},
      {"identifier": "cabin", "icon": Icons.cabin, "label": l10n.poiIconCabin},
      {"identifier": "door", "icon": Icons.meeting_room, "label": l10n.poiIconDoor},
      {"identifier": "skull", "icon": Icons.warning_amber_rounded, "label": l10n.poiIconSkull},
      {"identifier": "navigation", "icon": Icons.navigation, "label": l10n.poiIconNavigation},
      {"identifier": "target", "icon": Icons.gps_fixed, "label": l10n.poiIconTarget},
      {"identifier": "ammo", "icon": Icons.local_mall, "label": l10n.poiIconAmmo},
      {"identifier": "medical", "icon": Icons.medical_services, "label": l10n.poiIconMedical},
      {"identifier": "radio", "icon": Icons.radio, "label": l10n.poiIconRadio},
      {"identifier": "default_poi_icon", "icon": Icons.location_pin, "label": l10n.poiIconDefault},
    ];
  }

  IconData _getIconDataFromIdentifier(String identifier) {
    final l10n = AppLocalizations.of(context)!;
    final icons = _getAvailableIcons(l10n);
    final iconData = icons.firstWhere(
        (icon) => icon["identifier"] == identifier,
        orElse: () => icons.firstWhere(
            (icon) => icon["identifier"] == "default_poi_icon")
        );
    return iconData["icon"] as IconData;
  }

  @override
  void initState() {
    super.initState();
    _gameMapService = GetIt.I<GameMapService>();
    _geocodingService = GetIt.I<GeocodingService>();

    _updateActiveTileLayer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context)!;
      if (widget.initialMap != null) {
        _currentMap = widget.initialMap!;
        _mapNameController.text = _currentMap.name;
        _mapDescriptionController.text = _currentMap.description ?? "";
        _searchAddressController.text = _currentMap.sourceAddress ?? "";
        if (_currentMap.centerLatitude != null &&
            _currentMap.centerLongitude != null) {
          _currentMapCenter =
              LatLng(_currentMap.centerLatitude!, _currentMap.centerLongitude!);
        }
        if (_currentMap.initialZoom != null) {
          _currentZoom = _currentMap.initialZoom!
              .clamp(_minZoom, _maxZoom);
        }
        if (_currentMap.centerLatitude != null &&
            _currentMap.centerLongitude != null) {
          _mapController.move(
              LatLng(_currentMap.centerLatitude!, _currentMap.centerLongitude!),
              _currentZoom);
        }
        _loadMapDetails();
      } else {
        _currentMap = GameMap(name: l10n.interactiveMapEditorTitleCreate);
        _mapNameController.text = _currentMap.name;
      }
    });

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
        // Optionnel: Masquer les résultats si le focus est perdu et qu'ils sont affichés
        // setState(() {
        //   _showGeocodingResults = false;
        // });
      }
    });
  }

  void _updateActiveTileLayer() {
    setState(() {
      if (_currentTileLayerType == TileLayerType.satellite) {
        _activeTileUrl = _esriWorldImageryTileUrl;
        _activeTileSubdomains = []; // Pas de sous-domaines pour Esri
      } else {
        _activeTileUrl = _osmTileUrl;
        _activeTileSubdomains =
            []; // OSM recommande de ne plus utiliser de sous-domaines
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
        logger.d("Error decoding fieldBoundaryJson: $e");
        _currentBoundaryPoints = [];
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
        logger.d("Error decoding mapZonesJson: $e");
        _mapZones = [];
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
        logger.d("Error decoding mapPointsOfInterestJson: $e");
        _mapPois = [];
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
    FocusScope.of(context).unfocus();
    try {
      List<GeocodingResult> results =
          await _geocodingService.searchAddress(_searchAddressController.text);
      setState(() {
        _geocodingResults = results;
        _showGeocodingResults = results.isNotEmpty;
      });
    } catch (e) {
        final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorGeocodingSnackbar(e.toString()))));
      setState(() {
        _geocodingResults.clear();
        _showGeocodingResults = false;
      });
    }
  }

  void _selectGeocodingResult(GeocodingResult result) {
    setState(() {
      _currentMapCenter = LatLng(result.latitude, result.longitude);
      _currentZoom = 15.0.clamp(_minZoom, _maxZoom);
      _searchAddressController.text = result.displayName;
      _geocodingResults.clear();
      _showGeocodingResults = false;
    });
    _mapController.move(_currentMapCenter, _currentZoom);
    FocusScope.of(context).unfocus();
  }

  void _onMapTap(fm.TapPosition tapPosition, LatLng point) async {
      // final l10n = AppLocalizations.of(context)!; // Removed, as it's not used in this specific block after changes
    if (_showGeocodingResults) {
      setState(() {
        _showGeocodingResults = false;
      });
    }

    if (_editorMode == MapEditorMode.drawBoundary) {
      setState(() {
        _currentBoundaryPoints.add(point);
      });
    } else if (_editorMode == MapEditorMode.drawZone) {
      setState(() {
        _currentZonePoints.add(point);
      });
    } else if (_editorMode == MapEditorMode.placePoi) {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (BuildContext context) {
          return PoiEditDialog();
        },
      );
      if (result != null &&
          result.containsKey("name") &&
          result.containsKey("iconIdentifier")) {
        setState(() {
          _mapPois.add(MapPointOfInterest(
            id: uuid.v4(),
            name: result["name"]! as String,
            latitude: point.latitude,
            longitude: point.longitude,
            iconIdentifier: result["iconIdentifier"]! as String,
            type: "DEFAULT",
            visible: true,
          ));
        });
      }
    }
  }

  void _addCurrentZone() async {
      final l10n = AppLocalizations.of(context)!;
    if (_currentZonePoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.zoneMinPointsError)));
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

  void _editPoi(MapPointOfInterest poiToEdit) async {
      final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return PoiEditDialog(
          initialName: poiToEdit.name,
          initialIconIdentifier: poiToEdit.iconIdentifier,
        );
      },
    );

    if (result != null &&
        result.containsKey("name") &&
        result.containsKey("iconIdentifier")) {
      setState(() {
        final index = _mapPois.indexWhere((p) => p.id == poiToEdit.id);
        if (index != -1) {
          _mapPois[index] = poiToEdit.copyWith(
            name: result["name"]! as String,
            iconIdentifier: result["iconIdentifier"]! as String,
            visible: poiToEdit.visible,
          );
        }
      });
    }
  }

  void _togglePoiVisibility(MapPointOfInterest poiToToggle) {
    setState(() {
      final index = _mapPois.indexWhere((p) => p.id == poiToToggle.id);
      if (index != -1) {
        _mapPois[index] = poiToToggle.copyWith(
            visible: !poiToToggle.visible,
            name: poiToToggle.name,
            iconIdentifier: poiToToggle.iconIdentifier);
      }
    });
  }

  void _deletePoi(MapPointOfInterest poiToDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Supprimer le Point Stratégique"),
          content: Text(
              "Êtes-vous sûr de vouloir supprimer le point \"${poiToDelete.name}\" ?"),
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
                  _mapPois.removeWhere((p) => p.id == poiToDelete.id);
                });
              },
            ),
          ],
        );
      },
    );
  }

  Color _parseColor(String? colorString) {
    logger.d("Parsing color string: '$colorString'");
    if (colorString == null || colorString.isEmpty) {
      logger.d("Color string is null or empty, returning default grey.");
      return Colors.grey.withOpacity(0.5);
    }

    String cs = colorString.trim();

    try {
      if (cs.startsWith('#')) {
        String hexColor = cs.substring(1);
        if (hexColor.length == 6) {
          hexColor = "FF" + hexColor;
        }
        if (hexColor.length == 8) {
          return Color(int.parse(hexColor, radix: 16));
        }
      } else if (cs.startsWith('Color(0x') && cs.endsWith(')')) {
        String hexValue = cs.substring(8, cs.length - 1);
        return Color(int.parse(hexValue, radix: 16));
      } else if (cs.length == 6 || cs.length == 8) {
        final buffer = StringBuffer();
        if (cs.length == 6) buffer.write('ff');
        buffer.write(cs);
        return Color(int.parse(buffer.toString(), radix: 16));
      }

      switch (cs.toLowerCase()) {
        case 'red':
          return Colors.red;
        case 'green':
          return Colors.green;
        case 'blue':
          return Colors.blue;
        default:
          logger.d("Couleur non reconnue '$cs', utilisation du gris par défaut.");
          return Colors.grey.withOpacity(0.5);
      }
    } catch (e) {
      logger.d("Erreur lors du parsing de la couleur '$cs': $e");
      return Colors.grey.withOpacity(0.5);
    }
  }

  String _latLngBoundsToJson(fm.LatLngBounds bounds) {
    final ne = bounds.northEast;
    final sw = bounds.southWest;

    return jsonEncode({
      "neLat": ne.latitude,
      "neLng": ne.longitude,
      "swLat": sw.latitude,
      "swLng": sw.longitude,
    });
  }

  /*Future<void> _captureAndStoreMapBackground(
      TileLayerType layerType, bool isSatelliteViewForStorage) async {
    String tileUrlToCapture;
    List<String> subdomainsToCapture;

    if (layerType == TileLayerType.satellite) {
      tileUrlToCapture = _esriWorldImageryTileUrl;
      subdomainsToCapture = [];
    } else {
      tileUrlToCapture = _osmTileUrl;
      subdomainsToCapture = [];
    }

    if (_currentBoundaryPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Veuillez définir une zone de terrain (au moins 3 points) avant de capturer le fond.")));
      return;
    }
// Étend de 1 km dans toutes les directions
    fm.LatLngBounds currentBounds = _expandBoundsByKm(
        fm.LatLngBounds.fromPoints(_currentBoundaryPoints),
        1.0); // +20% padding

    _screenshotController = ScreenshotController();


    Uint8List? imageBytes;

    final center = LatLng(
      _currentMap.centerLatitude!,
      _currentMap.centerLongitude!,
    );
    try {
      await Future.delayed(Duration(milliseconds: 500));
      imageBytes = await _screenshotController.captureFromWidget(
        MediaQuery(
          // Fournir un MediaQueryData explicite avec une taille fixe
          data: MediaQueryData(size: Size(800, 600)),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: fm.FlutterMap(
                  options: fm.MapOptions(
                    initialCenter: center,
                    initialZoom:_currentMap.initialZoom!,
                    minZoom: _minZoom,
                    maxZoom: _maxZoom,
                  ),
                  children: [
                    fm.TileLayer(
                      urlTemplate: tileUrlToCapture,
                      subdomains: subdomainsToCapture,
                      userAgentPackageName: "com.airsoft.gamemapmaster",
                    ),
                    fm.PolygonLayer(
                      polygons: [
                        fm.Polygon(
                          points: _currentBoundaryPoints,
                          color: Colors.transparent,
                          borderColor: Colors.red.withOpacity(0.5),
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        delay: Duration(seconds: 1),
      );
    } catch (e) {
      logger.d("Error capturing map background: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur technique lors de la capture: $e")));
      return;
    }

    if (imageBytes != null) {
      String base64Image = base64Encode(imageBytes);

      if (isSatelliteViewForStorage) {
        _currentMap.satelliteImageBase64 = base64Image;
        _currentMap.satelliteBoundsJson = _latLngBoundsToJson(currentBounds);
      } else {
        _currentMap.backgroundImageBase64 = base64Image;
        _currentMap.backgroundBoundsJson = _latLngBoundsToJson(currentBounds);
      }
      logger.d(
          "🟡 [InteractiveMapEditorScreen] [_captureAndStoreMapBackground] Captured ${isSatelliteViewForStorage ? 'satellite' : 'standard'} bounds: ${_latLngBoundsToJson(currentBounds)}");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Fond de carte ${isSatelliteViewForStorage ? 'satellite' : 'standard'} capturé.")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Erreur lors de la capture du fond de carte.")));
    }

    _updateActiveTileLayer();
    setState(() {});
  }*/

  void _defineFieldBoundary() async {
    if (_currentBoundaryPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("La limite du terrain doit avoir au moins 3 points.")));
      return;
    }

    if (_mapZones.isNotEmpty || _mapPois.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Redéfinir les Limites"),
            content: Text(
                "Redéfinir les limites du terrain effacera toutes les zones et points stratégiques existants. Voulez-vous continuer ?"),
            actions: <Widget>[
              TextButton(
                child: Text("Annuler"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text("Continuer"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
      if (confirm != true) {
        return;
      }
    }

    setState(() {
      _currentMap.fieldBoundaryJson = jsonEncode(_currentBoundaryPoints
          .map((p) =>
              Coordinate(latitude: p.latitude, longitude: p.longitude).toJson())
          .toList());

      _mapZones.clear();
      _mapPois.clear();
      _currentMap.mapZonesJson = null;
      _currentMap.mapPointsOfInterestJson = null;

      _editorMode = MapEditorMode.view;
    });

  /*  await _captureAndStoreMapBackground(TileLayerType.osm, false);
    await _captureAndStoreMapBackground(TileLayerType.satellite, true);
*/
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text("Limites du terrain définies et fonds de carte capturés.")));
  }

  void _saveMap() async {
    if (_mapNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Veuillez donner un nom à la carte.")));
      return;
    }

    _currentMap.name = _mapNameController.text;
    _currentMap.description = _mapDescriptionController.text;
    _currentMap.centerLatitude = _currentMapCenter.latitude;
    _currentMap.centerLongitude = _currentMapCenter.longitude;
    _currentMap.initialZoom = _currentZoom;
    _currentMap.sourceAddress = _searchAddressController.text;

    _currentMap.mapZonesJson =
        jsonEncode(_mapZones.map((z) => z.toJson()).toList());
    _currentMap.mapPointsOfInterestJson =
        jsonEncode(_mapPois.map((p) => p.toJson()).toList());

    try {

      if (_currentMap.id == null) {
        _currentMap = await _gameMapService.addGameMap(_currentMap);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Carte créée avec succès !")));
      } else {
        await _gameMapService.updateGameMap(_currentMap);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Carte mise à jour avec succès !")));
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop(_currentMap);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la sauvegarde: $e")));
    }
  }

  fm.LatLngBounds _expandBoundsByKm(fm.LatLngBounds original, double km) {
      final l10n = AppLocalizations.of(context)!; // Ensure l10n is available
    const double degreesPerKm = 1 / 111.0; // approximation (valable en France)
    final delta = km * degreesPerKm;

    final newNE = LatLng(
      original.northEast.latitude + delta,
      original.northEast.longitude + delta,
    );
    final newSW = LatLng(
      original.southWest.latitude - delta,
      original.southWest.longitude - delta,
    );

    return fm.LatLngBounds.fromPoints([newNE, newSW]);
  }

  Widget _buildModeSelector() {
      final l10n = AppLocalizations.of(context)!; // Ensure l10n is available
    return SegmentedButton<MapEditorMode>(
      segments: <ButtonSegment<MapEditorMode>>[
        ButtonSegment<MapEditorMode>(
            value: MapEditorMode.view,
            label: Text(l10n.viewModeLabel),
            icon: const Icon(Icons.visibility)),
        ButtonSegment<MapEditorMode>(
            value: MapEditorMode.drawBoundary,
            label: Text(l10n.drawBoundaryModeLabel),
            icon: const Icon(Icons.hexagon_outlined)),
        ButtonSegment<MapEditorMode>(
            value: MapEditorMode.drawZone,
            label: Text(l10n.drawZoneModeLabel),
            icon: const Icon(Icons.layers)),
        ButtonSegment<MapEditorMode>(
            value: MapEditorMode.placePoi,
            label: Text(l10n.placePOIModeLabel),
            icon: const Icon(Icons.place)),
      ],
      selected: <MapEditorMode>{_editorMode},
      onSelectionChanged: (Set<MapEditorMode> newSelection) {
        setState(() {
          _editorMode = newSelection.first;
          if (_editorMode != MapEditorMode.drawZone) {
            _currentZonePoints.clear();
          }
        });
      },
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.blue,
        selectedForegroundColor: Colors.white,
        selectedBackgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildActionButtons() {
      final l10n = AppLocalizations.of(context)!; // Ensure l10n is available
    if (_editorMode == MapEditorMode.drawBoundary) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(l10n.defineBoundariesButton),
              onPressed: _defineFieldBoundary,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, foregroundColor: Colors.white),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.undo),
              label: Text(l10n.undoPointButton),
              onPressed: () {
                if (_currentBoundaryPoints.isNotEmpty) {
                  setState(() {
                    _currentBoundaryPoints.removeLast();
                  });
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_sweep),
              label: Text(l10n.clearAllButton),
              onPressed: () {
                setState(() {
                  _currentBoundaryPoints.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    if (_editorMode == MapEditorMode.drawZone) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt),
              label: Text(l10n.addZoneButton),
              onPressed: _addCurrentZone,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, foregroundColor: Colors.white),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.undo),
              label: Text(l10n.undoPointButton),
              onPressed: () {
                if (_currentZonePoints.isNotEmpty) {
                  setState(() {
                    _currentZonePoints.removeLast();
                  });
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.clear_all),
              label: Text(l10n.clearCurrentZoneButton),
              onPressed: () {
                setState(() {
                  _currentZonePoints.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildZoneManagementPanel() {
    final l10n = AppLocalizations.of(context)!;
    if (_mapZones.isEmpty) {
      return Center(child: Text(l10n.noZoneDefined));
    }
    return ListView.builder(
      itemCount: _mapZones.length,
      itemBuilder: (context, index) {
        final zone = _mapZones[index];
        Color displayColor = _parseColor(zone.color);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Icon(Icons.layers, color: displayColor.withOpacity(1)),
            title: Text(zone.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                      zone.visible ? Icons.visibility : Icons.visibility_off),
                  tooltip: zone.visible ? l10n.hideTooltip : l10n.showTooltip,
                  onPressed: () => _toggleZoneVisibility(zone),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.edit,
                  onPressed: () => _editZone(zone),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: l10n.delete,
                  onPressed: () => _deleteZone(zone),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPoiManagementPanel() {
    final l10n = AppLocalizations.of(context)!;
    if (_mapPois.isEmpty) {
      return Center(child: Text(l10n.noPOIDefined));
    }
    return ListView.builder(
      itemCount: _mapPois.length,
      itemBuilder: (context, index) {
        final poi = _mapPois[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Icon(_getIconDataFromIdentifier(poi.iconIdentifier)),
            title: Text(poi.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                      poi.visible ? Icons.visibility : Icons.visibility_off),
                  tooltip: poi.visible ? l10n.hideTooltip : l10n.showTooltip,
                  onPressed: () => _togglePoiVisibility(poi),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.edit,
                  onPressed: () => _editPoi(poi),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: l10n.delete,
                  onPressed: () => _deletePoi(poi),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  fm.LatLngBounds _expandBounds(fm.LatLngBounds original, double factor) {
    final ne = original.northEast;
    final sw = original.southWest;

    final latSpan = ne.latitude - sw.latitude;
    final lngSpan = ne.longitude - sw.longitude;

    final newNE = LatLng(
      ne.latitude + latSpan * factor,
      ne.longitude + lngSpan * factor,
    );
    final newSW = LatLng(
      sw.latitude - latSpan * factor,
      sw.longitude - lngSpan * factor,
    );

    return fm.LatLngBounds.fromPoints([newNE, newSW]);
  }


  // Fonctions pour le zoom
  void _zoomIn() {
    double newZoom =
        (_mapController.camera.zoom + 1.0).clamp(_minZoom, _maxZoom);
    _mapController.move(_mapController.camera.center, newZoom);
    setState(() {
      _currentZoom = newZoom;
    });
  }

  void _zoomOut() {
    double newZoom =
        (_mapController.camera.zoom - 1.0).clamp(_minZoom, _maxZoom);
    _mapController.move(_mapController.camera.center, newZoom);
    setState(() {
      _currentZoom = newZoom;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> layers = [
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
                color: Colors.red,
                strokeWidth: 3),
          ],
        ),
      if (_currentBoundaryPoints.length > 2 &&
          _editorMode == MapEditorMode.drawBoundary)
        fm.PolygonLayer(
          polygons: [
            fm.Polygon(
              points: _currentBoundaryPoints,
              color: Colors.red.withOpacity(0.1),
              borderColor: Colors.red,
              borderStrokeWidth: 1,
              isFilled: true,
            )
          ],
        ),
      if (_mapZones.isNotEmpty)
        fm.PolygonLayer(
          polygons: _mapZones.where((zone) => zone.visible).map((zone) {
            Color zoneColor = _parseColor(zone.color);
            return fm.Polygon(
              points: zone.zoneShape
                  .map((c) => LatLng(c.latitude, c.longitude))
                  .toList(),
              color: zoneColor.withOpacity(0.3),
              borderColor: zoneColor,
              borderStrokeWidth: 2,
              isFilled: true,
            );
          }).toList(),
        ),
      if (_currentZonePoints.length > 1)
        fm.PolylineLayer(
          polylines: [
            fm.Polyline(
                points: _currentZonePoints,
                color: Colors.blueAccent,
                strokeWidth: 2,
                isDotted: true),
          ],
        ),
      if (_mapPois.isNotEmpty)
        fm.MarkerLayer(
          markers: _mapPois.where((poi) => poi.visible).map((poi) {
            return fm.Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(poi.latitude, poi.longitude),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getIconDataFromIdentifier(poi.iconIdentifier),
                      color: Colors.blue, size: 30),
                ],
              ),
            );
          }).toList(),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialMap == null
            ? "Créer Carte Interactive"
            : "Modifier: ${_currentMap.name}"),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            tooltip: "Sauvegarder la Carte",
            onPressed: _saveMap,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _mapNameController,
              decoration: InputDecoration(labelText: "Nom de la carte"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: TextField(
              controller: _mapDescriptionController,
              decoration: InputDecoration(labelText: "Description (optionnel)"),
              maxLines: 2,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
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
                SizedBox(width: 8),
                Tooltip(
                  message: _currentTileLayerType == TileLayerType.osm
                      ? "Vue Satellite"
                      : "Vue Standard",
                  child: IconButton(
                    icon: Icon(_currentTileLayerType == TileLayerType.osm
                        ? Icons.satellite_alt
                        : Icons.map),
                    onPressed: _toggleTileLayer,
                  ),
                )
              ],
            ),
          ),
          if (_showGeocodingResults)
            Container(
              constraints: BoxConstraints(maxHeight: 150),
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
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildModeSelector(),
          ),
          _buildActionButtons(),
          Expanded(
            child: Stack(
              children: [
                Screenshot(
                  controller: _screenshotController,
                  child: fm.FlutterMap(
                    mapController: _mapController,
                    options: fm.MapOptions(
                      initialCenter: _currentMapCenter,
                      initialZoom: _currentZoom,
                      minZoom: _minZoom,
                      maxZoom: _maxZoom,
                      onTap: _onMapTap,
                      onPositionChanged: (position, hasGesture) {
                        if (hasGesture) {
                          // Mise à jour de _currentMapCenter et _currentZoom uniquement si le mouvement est initié par un geste utilisateur
                          // pour éviter des mises à jour pendant les mouvements programmatiques (comme _mapController.move)
                          if (position.center != null)
                            _currentMapCenter = position.center!;
                          if (position.zoom != null)
                            _currentZoom = position.zoom!;
                          // Pas besoin de setState ici si cela cause des rebuilds non désirés pendant le geste
                          // La carte se met à jour visuellement. Sauvegarder ces valeurs lors d'une action explicite (ex: _saveMap)
                        }
                      },
                    ),
                    children: layers,
                  ),
                ),
                // Panneaux de gestion (Zones et POI) - affichés conditionnellement
                if (_editorMode == MapEditorMode.drawZone &&
                    _mapZones.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.25,
                      color: Colors.black.withOpacity(0.7),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("Gestion des Zones",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Expanded(child: _buildZoneManagementPanel()),
                        ],
                      ),
                    ),
                  ),
                if (_editorMode == MapEditorMode.placePoi &&
                    _mapPois.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.25,
                      color: Colors.black.withOpacity(0.7),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("Gestion des Points Stratégiques",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Expanded(child: _buildPoiManagementPanel()),
                        ],
                      ),
                    ),
                  ),
                // Boutons de Zoom
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Column(
                    children: <Widget>[
                      FloatingActionButton(
                        heroTag: "zoomInButton", // HeroTag unique
                        mini: true,
                        onPressed: _zoomIn,
                        child: Icon(Icons.add),
                      ),
                      SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: "zoomOutButton", // HeroTag unique
                        mini: true,
                        onPressed: _zoomOut,
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
