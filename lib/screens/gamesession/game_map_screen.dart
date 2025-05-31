import 'package:airsoft_game_map/models/coordinate.dart';
import 'package:airsoft_game_map/models/game_map.dart';
import 'package:airsoft_game_map/services/player_location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

/// Écran affichant la carte en temps réel avec les positions des joueurs
class GameMapScreen extends StatefulWidget {
  final int gameSessionId;
  final GameMap gameMap;
  final int userId;
  final int? teamId;
  
  const GameMapScreen({
    Key? key,
    required this.gameSessionId,
    required this.gameMap,
    required this.userId,
    this.teamId,
  }) : super(key: key);
  
  @override
  _GameMapScreenState createState() => _GameMapScreenState();
}

class _GameMapScreenState extends State<GameMapScreen> {
  final MapController _mapController = MapController();
  late PlayerLocationService _locationService;
  bool _isFullScreen = false;
  
  // Couleurs pour les équipes
  final Map<int, Color> _teamColors = {
    1: Colors.blue,
    2: Colors.red,
    3: Colors.green,
    4: Colors.orange,
    5: Colors.purple,
    6: Colors.teal,
    7: Colors.pink,
    8: Colors.indigo,
  };
  
  @override
  void initState() {
    super.initState();
    _locationService = GetIt.I<PlayerLocationService>();
    _locationService.initialize(widget.userId, widget.teamId, widget.gameMap.fieldId!);
    _locationService.startLocationSharing(widget.gameSessionId);
  }
  
  @override
  void dispose() {
    _locationService.stopLocationSharing();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen 
        ? null 
        : AppBar(
            title: const Text('Carte de jeu'),
            actions: [
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: () {
                  setState(() {
                    _isFullScreen = true;
                  });
                },
              ),
            ],
          ),
      body: Stack(
        children: [
          // Carte interactive
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: LatLng(
                widget.gameMap.centerLatitude ?? 48.8566,
                widget.gameMap.centerLongitude ?? 2.3522
              ),
              zoom: widget.gameMap.initialZoom ?? 13.0,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              // Couche de tuiles (fond de carte)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.airsoft.gamemapmaster',
              ),
              
              // Limites du terrain
              if (widget.gameMap.fieldBoundary != null)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: widget.gameMap.fieldBoundary!
                        .map((coord) => LatLng(coord.latitude, coord.longitude))
                        .toList(),
                      color: Colors.blue.withOpacity(0.2),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
              
              // Zones
              if (widget.gameMap.mapZones != null)
                PolygonLayer(
                  polygons: widget.gameMap.mapZones!
                    .where((zone) => zone.visible)
                    .map((zone) => Polygon(
                      points: zone.zoneShape
                        .map((coord) => LatLng(coord.latitude, coord.longitude))
                        .toList(),
                      color: _parseColor(zone.color).withOpacity(0.3),
                      borderColor: _parseColor(zone.color),
                      borderStrokeWidth: 2.0,
                    ))
                    .toList(),
                ),
              
              // Points d'intérêt
              if (widget.gameMap.mapPointsOfInterest != null)
                MarkerLayer(
                  markers: widget.gameMap.mapPointsOfInterest!
                      .where((poi) => poi.visible)
                      .map((poi) => Marker(
                    point: LatLng(poi.latitude, poi.longitude),
                    width: 40,
                    height: 40,
                    child: Tooltip(
                      message: poi.name,
                      child: Icon(
                        _getIconDataFromIdentifier(poi.iconIdentifier),
                        color: Colors.black87,
                        size: 30,
                      ),
                    ),
                  ))
                      .toList(),
                ),
              
              // Positions des joueurs
              StreamBuilder<Map<int, Coordinate>>(
                stream: _locationService.positionStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return MarkerLayer(markers: []);

                  final positions = snapshot.data!;
                  return MarkerLayer(
                    markers: positions.entries.map((entry) {
                      final userId = entry.key;
                      final position = entry.value;
                      final isCurrentUser = userId == widget.userId;

                      return Marker(
                        point: LatLng(position.latitude, position.longitude),
                        width: 40,
                        height: 40,
                        child: _buildPlayerMarker(userId, isCurrentUser),
                      );
                    }).toList(),
                  );
                },
              ),

            ],
          ),
          
          // Bouton pour quitter le mode plein écran
          if (_isFullScreen)
            Positioned(
              top: 10,
              right: 10,
              child: SafeArea(
                child: FloatingActionButton(
                  mini: true,
                  child: const Icon(Icons.fullscreen_exit),
                  onPressed: () {
                    setState(() {
                      _isFullScreen = false;
                    });
                  },
                ),
              ),
            ),
            
          // Bouton pour centrer la carte sur la position actuelle
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              child: const Icon(Icons.my_location),
              onPressed: _centerOnCurrentPosition,
            ),
          ),
        ],
      ),
    );
  }
  
  void _centerOnCurrentPosition() async {
    try {
      // Récupérer la position actuelle
      final positions = _locationService.currentPlayerPositions;
      if (positions.containsKey(widget.userId)) {
        final myPosition = positions[widget.userId]!;
        _mapController.move(
          LatLng(myPosition.latitude, myPosition.longitude),
          _mapController.zoom
        );
      }
    } catch (e) {
      print('Erreur lors du centrage sur la position actuelle: $e');
    }
  }
  
  Widget _buildPlayerMarker(int userId, bool isCurrentUser) {
    final Color markerColor = isCurrentUser 
      ? Colors.blue 
      : _teamColors[widget.teamId] ?? Colors.green;
    
    return Stack(
      children: [
        Icon(
          Icons.location_on,
          color: markerColor,
          size: 30,
        ),
        if (isCurrentUser)
          Positioned.fill(
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Color _parseColor(String colorString) {
    // Méthode pour parser une couleur depuis une chaîne
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse('0xFF${colorString.substring(1)}'));
      }
      return Colors.blue;
    } catch (e) {
      return Colors.blue;
    }
  }
  
  IconData _getIconDataFromIdentifier(String identifier) {
    // Liste des icônes disponibles (similaire à celle de InteractiveMapEditorScreen)
    final Map<String, IconData> icons = {
      "flag": Icons.flag,
      "bomb": Icons.dangerous,
      "star": Icons.star,
      "place": Icons.place,
      "pin_drop": Icons.pin_drop,
      "house": Icons.house,
      "cabin": Icons.cabin,
      "door": Icons.meeting_room,
      "skull": Icons.warning_amber_rounded,
      "navigation": Icons.navigation,
      "target": Icons.gps_fixed,
      "ammo": Icons.local_mall,
      "medical": Icons.medical_services,
      "radio": Icons.radio,
      "default_poi_icon": Icons.location_pin,
    };
    
    return icons[identifier] ?? Icons.location_pin;
  }
}
