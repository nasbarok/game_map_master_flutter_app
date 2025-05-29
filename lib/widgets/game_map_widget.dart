import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:airsoft_game_map/models/coordinate.dart';
import 'package:airsoft_game_map/models/game_map.dart';
import 'package:airsoft_game_map/screens/gamesession/game_map_screen.dart';
import 'package:airsoft_game_map/services/player_location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

class GameMapWidget extends StatefulWidget {
  final int gameSessionId;
  final GameMap gameMap;
  final int userId;
  final int? teamId;

  const GameMapWidget({
    Key? key,
    required this.gameSessionId,
    required this.gameMap,
    required this.userId,
    this.teamId,
  }) : super(key: key);

  @override
  State<GameMapWidget> createState() => _GameMapWidgetState();
}

class _GameMapWidgetState extends State<GameMapWidget> {
  final MapController _mapController = MapController();
  Uint8List? _imageData;
  LatLngBounds? _bounds;
  Map<int, Coordinate> _positions = {};
  OverlayImage? _imageOverlay;
  double _lastMapWidth = 0;

  @override
  void initState() {
    super.initState();

    _imageData = _decodeBase64Image(widget.gameMap.backgroundImageBase64);
    _bounds = _parseBounds(widget.gameMap.backgroundBoundsJson);

    if (_imageData != null && _bounds != null) {
      _imageOverlay = OverlayImage(
        bounds: _bounds!,
        imageProvider: MemoryImage(_imageData!),
      );
    }

    final locationService = GetIt.I<PlayerLocationService>();
    locationService.initialize(widget.userId, widget.teamId);

    locationService.positionStream.listen((posMap) {
      setState(() {
        _positions = posMap;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.gameMap.hasInteractiveMapConfig) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Carte de jeu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  tooltip: 'Afficher en plein écran',
                  onPressed: () => _openFullMapScreen(context),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              _lastMapWidth = constraints.maxWidth;

              // ⛔ Ne plus élargir artificiellement les bounds ici
              final center = _bounds?.center ??
                  LatLng(widget.gameMap.centerLatitude ?? 0,
                      widget.gameMap.centerLongitude ?? 0);

              final zoom = _bounds != null
                  ? _computeZoomForBounds(_bounds!, constraints.maxWidth, 200)
                  : widget.gameMap.initialZoom ?? 17.0;

              return Container(
                height: 200,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      interactiveFlags: InteractiveFlag.none,
                      onMapReady: _onMapReady,
                    ),
                    children: [
                      if (_imageOverlay != null)
                        OverlayImageLayer(overlayImages: [_imageOverlay!]),
                      if (_imageOverlay?.bounds != null)
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: [
                                _imageOverlay!.bounds.northWest,
                                _imageOverlay!.bounds.northEast,
                                _imageOverlay!.bounds.southEast,
                                _imageOverlay!.bounds.southWest,
                              ],
                              color: Colors.red.withOpacity(0.2),
                              borderColor: Colors.red,
                              borderStrokeWidth: 2,
                            )
                          ],
                        ),
                      MarkerLayer(
                        markers: _positions.entries.map((entry) {
                          final userId = entry.key;
                          final position = entry.value;

                          Color color;
                          IconData icon;

                          if (userId == widget.userId) {
                            color = Colors.blue;
                            icon = Icons.person_pin_circle;
                          } else if (userId == -1) {
                            color = Colors.green;
                            icon = Icons.adjust; // expected center
                          } else if (userId == -2) {
                            color = Colors.orange;
                            icon = Icons.center_focus_strong; // bounds center
                          } else {
                            color = Colors.black;
                            icon = Icons.person_pin;
                          }

                          return Marker(
                            point: LatLng(position.latitude, position.longitude),
                            width: 40,
                            height: 40,
                            child: Icon(icon, color: color, size: 30),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Positions partagées toutes les 30 secondes',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Uint8List? _decodeBase64Image(String? base64String) {
    try {
      if (base64String == null) return null;
      String normalized = base64String.contains(',')
          ? base64String.split(',')[1]
          : base64String;
      return base64Decode(normalized);
    } catch (e) {
      print('Erreur lors du décodage de l\'image : $e');
      return null;
    }
  }

  LatLngBounds? _parseBounds(String? jsonString) {
    if (jsonString == null) return null;
    try {
      final data = jsonDecode(jsonString);
      final neLat = data['neLat'] as double;
      final neLng = data['neLng'] as double;
      final swLat = data['swLat'] as double;
      final swLng = data['swLng'] as double;
      print("🔎 Bounds parsed: NE(${neLat}, ${neLng}), SW(${swLat}, ${swLng})");
      return LatLngBounds(
        LatLng(swLat, swLng),
        LatLng(neLat, neLng),
      );

    } catch (e) {
      print('❌ Erreur lors du parsing des bounds : $e');
      return null;
    }
  }

  LatLngBounds _expandBounds(LatLngBounds bounds, double factor) {
    final latSpan = bounds.northEast.latitude - bounds.southWest.latitude;
    final lngSpan = bounds.northEast.longitude - bounds.southWest.longitude;
    return LatLngBounds.fromPoints([
      LatLng(bounds.northEast.latitude + latSpan * factor,
          bounds.northEast.longitude + lngSpan * factor),
      LatLng(bounds.southWest.latitude - latSpan * factor,
          bounds.southWest.longitude - lngSpan * factor),
    ]);
  }

  double _computeZoomForBounds(
      LatLngBounds bounds, double mapWidthPx, double mapHeightPx) {
    const tileSize = 256.0;
    const maxZoom = 22.0;
    const ln2 = 0.6931471805599453;

    final latDiff = bounds.northEast.latitude - bounds.southWest.latitude;
    final lngDiff = bounds.northEast.longitude - bounds.southWest.longitude;

    final latFraction = latDiff / 180.0;
    final lngFraction = lngDiff / 360.0;

    final latZoom = math.log(mapHeightPx / tileSize / latFraction) / ln2;
    final lngZoom = math.log(mapWidthPx / tileSize / lngFraction) / ln2;

    final zoomLat = latZoom.clamp(0, maxZoom);
    final zoomLng = lngZoom.clamp(0, maxZoom);
    final finalZoom = math.min(zoomLat, zoomLng).toDouble();

    return finalZoom;
  }

  void _openFullMapScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameMapScreen(
          gameSessionId: widget.gameSessionId,
          gameMap: widget.gameMap,
          userId: widget.userId,
          teamId: widget.teamId,
        ),
      ),
    );
  }

  void _onMapReady() {
    print("📍 [GameMapWidget] onMapReady triggered");

    if (_bounds != null) {
      final expectedCenter = LatLng(
        widget.gameMap.centerLatitude!,
        widget.gameMap.centerLongitude!,
      );

      final boundsCenter = _bounds!.center;
      final zoom = widget.gameMap.initialZoom ?? 17.0;

      print("📌 widget.gameMap.center = $expectedCenter");
      print("📌 _bounds.center          = $boundsCenter");
      print("📏 Zoom enregistré         = $zoom");

      // 🧪 Comparaison visuelle : ajoute un marker sur les deux points
      setState(() {
        _positions[-1] = Coordinate(
          latitude: expectedCenter.latitude,
          longitude: expectedCenter.longitude,
        );
        _positions[-2] = Coordinate(
          latitude: boundsCenter.latitude,
          longitude: boundsCenter.longitude,
        );
      });

      // 🧭 Affichage centré sur le vrai `centerLatitude`
      _mapController.move(expectedCenter, zoom);
    }
  }


}
