import 'dart:convert';
import 'dart:typed_data';

import 'package:airsoft_game_map/models/game_map.dart';
import 'package:airsoft_game_map/screens/gamesession/game_map_screen.dart';
import 'package:airsoft_game_map/services/player_location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

import '../models/coordinate.dart';
import '../models/team.dart';
import '../services/game_state_service.dart';
import '../services/scenario/bomb_operation/bomb_operation_service.dart';
import 'package:airsoft_game_map/widgets/bomb_operation_map_widget_extension.dart';

import '../services/team_service.dart';

/// Widget pour afficher une carte miniature dans l'écran de session de jeu
class GameMapWidget extends StatefulWidget {
  final int gameSessionId;
  final GameMap gameMap;
  final int userId;
  final int? teamId;
  final bool hasBombOperationScenario;
  final BombOperationService? bombOperationService;

  const GameMapWidget({
    Key? key,
    required this.gameSessionId,
    required this.gameMap,
    required this.userId,
    this.teamId,
    this.hasBombOperationScenario = false,
    this.bombOperationService,
  }) : super(key: key);

  @override
  State<GameMapWidget> createState() => _GameMapWidgetState();
}

class _GameMapWidgetState extends State<GameMapWidget> {
  final MapController _mapController = MapController();
  LatLngBounds? _bounds;
  Map<int, Coordinate> _positions = {};

  bool _hasCenteredOnce = false;


  @override
  void initState() {
    super.initState();

    GetIt.I<PlayerLocationService>().positionStream.listen((posMap) {
      print('📡 [GameMapWidget] Received positions: $posMap');

      setState(() {
        _positions = posMap;
      });

      // Centrer une seule fois dès que la position du joueur est disponible
      if (!_hasCenteredOnce && posMap.containsKey(widget.userId)) {
        final pos = posMap[widget.userId]!;
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          widget.gameMap.initialZoom ?? 16.0,
        );
        _hasCenteredOnce = true;
        print('📍 Carte recentrée sur la position du joueur : $pos');
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si la carte a une configuration interactive
    if (!widget.gameMap.hasInteractiveMapConfig) {
      return const SizedBox.shrink(); // Ne rien afficher si pas de carte interactive
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Titre de la section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Carte de jeu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  tooltip: 'Afficher en plein écran',
                  onPressed: () => _openFullMapScreen(context),
                ),
              ],
            ),
          ),

          // Aperçu de la carte (version réduite avec FlutterMap)
          Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  // Carte interactive miniature
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: LatLng(
                          widget.gameMap.centerLatitude!,
                          widget.gameMap.centerLongitude!
                      ),
                      zoom: widget.gameMap.initialZoom ?? 13.0,
                      minZoom: 3.0,
                      maxZoom: 18.0,
                      interactiveFlags: InteractiveFlag.none, // Désactiver les interactions
                      onMapReady: () {
                        print('📍 [GameMapWidget] onMapReady triggered');

                        // Afficher les coordonnées du centre pour le débogage
                        final center = LatLng(
                            widget.gameMap.centerLatitude!,
                            widget.gameMap.centerLongitude!
                        );
                      },
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
                            color: _parseColor(zone.color)?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
                            borderColor: _parseColor(zone.color) ?? Colors.blue,
                            borderStrokeWidth: 2.0,
                          ))
                              .toList(),
                        ),

                      // Marqueur pour la position actuelle (centré)
                      MarkerLayer(
                        markers: _positions.entries.map((entry) {
                          final userId = entry.key;
                          final position = entry.value;

                          // 🔹 Cas spéciaux (-1 et -2 utilisés pour des marqueurs techniques)
                          if (userId == -1) {
                            return Marker(
                              point: LatLng(position.latitude, position.longitude),
                              width: 30,
                              height: 30,
                              child: const Icon(Icons.adjust, color: Colors.green, size: 20),
                            );
                          }
                          if (userId == -2) {
                            return Marker(
                              point: LatLng(position.latitude, position.longitude),
                              width: 30,
                              height: 30,
                              child: const Icon(Icons.center_focus_strong, color: Colors.orange, size: 20),
                            );
                          }

                          // ✅ Ici on appelle _buildPlayerMarker(...)
                          final isCurrentUser = userId == widget.userId;
                          final markerWidget = _buildPlayerMarker(userId, isCurrentUser);

                          return Marker(
                            point: LatLng(position.latitude, position.longitude),
                            width: 30,
                            height: 30,
                            child: markerWidget,
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // Bouton pour ouvrir la carte en plein écran
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: FloatingActionButton(
                      mini: true,
                      child: const Icon(Icons.fullscreen),
                      onPressed: () => _openFullMapScreen(context),
                    ),
                  ),
                  // Sites de bombe (si le scénario Bombe est actif)
                  if (widget.hasBombOperationScenario && widget.bombOperationService != null)
                    StreamBuilder<void>(
                      stream: widget.bombOperationService!.bombSitesStream,
                      builder: (context, snapshot) {
                        return MarkerLayer(
                          markers: generateBombSiteMarkers(
                            context: context,
                            bombScenario: widget.bombOperationService!.activeScenario!,
                            gameState: widget.bombOperationService!.currentState,
                            teamRoles: widget.bombOperationService!.teamRoles,
                            userTeamId: widget.teamId,
                            activeBombSites: widget.bombOperationService!.activeBombSites,
                            plantedBombSites: widget.bombOperationService!.plantedBombSites,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Informations sur la géolocalisation
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Positions partagées toutes les 30 secondes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _openFullMapScreen(BuildContext context) {
    // S'assurer que le service de localisation est initialisé
    final locationService = GetIt.I<PlayerLocationService>();
    locationService.initialize(widget.userId, widget.teamId, widget.gameMap.fieldId!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameMapScreen(
          gameSessionId: widget.gameSessionId,
          gameMap: widget.gameMap,
          userId: widget.userId,
          teamId: widget.teamId,
          hasBombOperationScenario: widget.hasBombOperationScenario,
        ),
      ),
    );
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
  Widget _buildPlayerMarker(int userId, bool isCurrentUser) {
    Color markerColor = isCurrentUser ? Colors.blue : Colors.green;
    final teamService = GetIt.I<TeamService>();
    final int? teamId = teamService.getTeamIdForPlayer(userId);
    if (!isCurrentUser && teamId != null) {
      final team = teamService.teams.firstWhere(
            (t) => t.id == teamId,
        orElse: () => Team(id: -1, name: 'Inconnue'),
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



}
