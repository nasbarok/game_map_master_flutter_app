import 'package:airsoft_game_map/models/coordinate.dart';
import 'package:airsoft_game_map/models/game_map.dart';
import 'package:airsoft_game_map/services/player_location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

import '../../models/scenario/bomb_operation/bomb_operation_state.dart';
import '../../models/team.dart';
import '../../services/game_state_service.dart';
import '../../services/scenario/bomb_operation/bomb_operation_service.dart';
import 'package:airsoft_game_map/screens/scenario/bomb_operation/bomb_operation_map_extension.dart';

import '../../services/team_service.dart';
import 'package:airsoft_game_map/utils/logger.dart';

/// Écran affichant la carte en temps réel avec les positions des joueurs
class GameMapScreen extends StatefulWidget {
  final int gameSessionId;
  final GameMap gameMap;
  final int userId;
  final int? teamId;
  final bool hasBombOperationScenario;

  const GameMapScreen({
    Key? key,
    required this.gameSessionId,
    required this.gameMap,
    required this.userId,
    this.teamId,
    this.hasBombOperationScenario = false,
  }) : super(key: key);

  @override
  _GameMapScreenState createState() => _GameMapScreenState();
}

class _GameMapScreenState extends State<GameMapScreen> {
  final MapController _mapController = MapController();
  late PlayerLocationService _locationService;
  late BombOperationService _bombOperationService;

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
    _locationService.initialize(
        widget.userId, widget.teamId, widget.gameMap.fieldId!);
    _locationService.startLocationSharing(widget.gameSessionId);
  }

  @override
  void dispose() {
    _locationService.stopLocationSharing();
    if (widget.hasBombOperationScenario) {
      _bombOperationService.dispose();
    }
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
              center: LatLng(widget.gameMap.centerLatitude ?? 48.8566,
                  widget.gameMap.centerLongitude ?? 2.3522),
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
                          .map((coord) =>
                              LatLng(coord.latitude, coord.longitude))
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
                                .map((coord) =>
                                    LatLng(coord.latitude, coord.longitude))
                                .toList(),
                            color: _parseColor(zone.color)?.withOpacity(0.3) ??
                                Colors.blue.withOpacity(0.3),
                            borderColor: _parseColor(zone.color) ?? Colors.blue,
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
              // Sites de bombe (si le scénario Bombe est actif)
              if (widget.hasBombOperationScenario)
                StreamBuilder<void>(
                  stream: _bombOperationService.bombSitesStream,
                  builder: (context, snapshot) {
                    return MarkerLayer(
                      markers: widget.generateBombSiteMarkers(
                        context: context,
                        bombScenario: _bombOperationService.activeSessionScenarioBomb!.bombOperationScenario!,
                        gameState: _bombOperationService.currentState,
                        teamRoles: _bombOperationService.teamRoles,
                        userTeamId: widget.teamId,
                        toActivateBombSites: _bombOperationService.toActivateBombSites,
                        disableBombSites: _bombOperationService.disableBombSites,
                        activeBombSites:_bombOperationService.activeBombSites,
                        currentZoom: _mapController.zoom,
                      ),
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
          // Affichage du compte à rebours de la bombe (si une bombe est plantée)
          if (widget.hasBombOperationScenario)
            StreamBuilder<void>(
              stream: _bombOperationService.bombSitesStream,
              builder: (context, snapshot) {
                if (_bombOperationService.currentState ==
                    BombOperationState.bombPlanted) {
                  return Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'BOMBE: ${_formatTime(_bombOperationService.bombTimeRemaining)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
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
        _mapController.move(LatLng(myPosition.latitude, myPosition.longitude),
            _mapController.zoom);
      }
    } catch (e) {
      logger.d('Erreur lors du centrage sur la position actuelle: $e');
    }
  }

  Widget _buildPlayerMarker(int userId, bool isCurrentUser) {
    final teamService = GetIt.I<TeamService>();
    final int? teamId = teamService.getTeamIdForPlayer(userId);

    Color markerColor = Colors.green; // défaut si aucune équipe trouvée

    if (teamId != null) {
      final team = teamService.teams.firstWhere(
        (t) => t.id == teamId,
        orElse: () => Team(id: -1, name: 'Aucune', color: null),
      );

      markerColor = _parseColor(team.color) ?? Colors.green;
    }

    // Récupérer le nom du joueur (à adapter selon votre structure de données)
    final String playerName = _getPlayerName(userId);

    return Stack(
      children: [
        // Point rond pour le joueur
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: markerColor,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
        ),

        // Nom du joueur
        Positioned(
          bottom: -5,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              playerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

// Méthode pour récupérer le nom du joueur
  String _getPlayerName(int userId) {
    final gameStateService = GetIt.I<GameStateService>();
    final player = gameStateService.connectedPlayersList.firstWhere(
      (p) => p['id'] == userId,
      orElse: () => {},
    );
    return player['username'] ?? 'Joueur $userId';
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse('0xFF${colorString.substring(1)}'));
      }
      return Colors.blue;
    } catch (_) {
      return null;
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

  // Ajoutez cette méthode
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
