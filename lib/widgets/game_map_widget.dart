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
import '../models/scenario/bomb_operation/bomb_operation_team.dart';
import '../models/scenario/bomb_operation/bomb_site.dart';
import '../models/scenario/bomb_operation/bomb_site_state.dart';
import '../models/team.dart';
import '../services/game_state_service.dart';
import '../services/scenario/bomb_operation/bomb_operation_service.dart';
import 'package:airsoft_game_map/widgets/bomb_operation_map_widget_extension.dart';

import '../services/team_service.dart';
import 'package:airsoft_game_map/utils/logger.dart';

/// Widget pour afficher une carte miniature dans l'écran de session de jeu
class GameMapWidget extends StatefulWidget {
  final int gameSessionId;
  final GameMap gameMap;
  final int userId;
  final int? teamId;
  final bool hasBombOperationScenario;

  const GameMapWidget({
    Key? key,
    required this.gameSessionId,
    required this.gameMap,
    required this.userId,
    this.teamId,
    this.hasBombOperationScenario = false,
  }) : super(key: key);

  @override
  State<GameMapWidget> createState() => _GameMapWidgetState();
}

class _GameMapWidgetState extends State<GameMapWidget> {
  final MapController _mapController = MapController();
  LatLngBounds? _bounds;
  Map<int, Coordinate> _positions = {};

  bool _hasCenteredOnce = false;
  final BombOperationService bombOperationService =
      GetIt.I<BombOperationService>();

  @override
  void initState() {
    super.initState();

    GetIt.I<PlayerLocationService>().positionStream.listen((posMap) {
      logger.d('📡 [GameMapWidget] Received positions: $posMap');

      setState(() {
        _positions = posMap;
      });

      // Centrer une seule fois dès que la position du joueur est disponible
      if (!_hasCenteredOnce && posMap.containsKey(widget.userId)) {
        final pos = posMap[widget.userId]!;
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          _mapController.zoom,
        );
        _hasCenteredOnce = true;
        logger.d('📍 Carte recentrée sur la position du joueur : $pos');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.gameMap.hasInteractiveMapConfig) {
      return const SizedBox.shrink();
    }

    final bombScenario = bombOperationService.activeSessionScenarioBomb;
    final gameState = bombOperationService.currentState;
    final roles = bombOperationService.teamRoles;

    logger.d(
        '[GameMapWidget] [build] hasBombOperationScenario=${widget.hasBombOperationScenario}, bombScenario=$bombScenario, gameState=$gameState, roles=$roles');

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
          Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: LatLng(widget.gameMap.centerLatitude!,
                      widget.gameMap.centerLongitude!),
                  zoom: widget.gameMap.initialZoom ?? 13.0,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                  interactiveFlags: InteractiveFlag.none,
                  onMapReady: () =>
                      logger.d('📍 [GameMapWidget] onMapReady triggered'),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.airsoft.gamemapmaster',
                  ),
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
                  if (widget.gameMap.mapZones != null)
                    PolygonLayer(
                      polygons: widget.gameMap.mapZones!
                          .where((zone) => zone.visible)
                          .map((zone) => Polygon(
                                points: zone.zoneShape
                                    .map((coord) =>
                                        LatLng(coord.latitude, coord.longitude))
                                    .toList(),
                                color:
                                    _parseColor(zone.color)?.withOpacity(0.3) ??
                                        Colors.blue.withOpacity(0.3),
                                borderColor:
                                    _parseColor(zone.color) ?? Colors.blue,
                                borderStrokeWidth: 2.0,
                              ))
                          .toList(),
                    ),
                  MarkerLayer(
                    markers: _positions.entries.map((entry) {
                      final userId = entry.key;
                      final position = entry.value;
                      if (userId == -1) {
                        return Marker(
                          point: LatLng(position.latitude, position.longitude),
                          width: 30,
                          height: 30,
                          child: const Icon(Icons.adjust,
                              color: Colors.green, size: 20),
                        );
                      }
                      if (userId == -2) {
                        return Marker(
                          point: LatLng(position.latitude, position.longitude),
                          width: 30,
                          height: 30,
                          child: const Icon(Icons.center_focus_strong,
                              color: Colors.orange, size: 20),
                        );
                      }
                      final isCurrentUser = userId == widget.userId;
                      final markerWidget =
                          _buildPlayerMarker(userId, isCurrentUser);
                      return Marker(
                        point: LatLng(position.latitude, position.longitude),
                        width: 30,
                        height: 30,
                        child: markerWidget,
                      );
                    }).toList(),
                  ),
                  // Cercles des sites de bombe
                  if (widget.hasBombOperationScenario && bombScenario != null)
                    CircleLayer(
                      circles: _generateBombSiteCircles(
                        context: context,
                        bombSites: bombOperationService
                                .activeSessionScenarioBomb
                                ?.bombOperationScenario
                                ?.bombSites ??
                            [],
                        teamRoles: bombOperationService.teamRoles,
                        userTeamId: widget.teamId,
                        toActivateBombSites:
                            bombOperationService.toActivateBombSites,
                        disableBombSites: bombOperationService.disableBombSites,
                        activeBombSites: bombOperationService.activeBombSites,
                      ),
                    ),

                  // Icônes et noms des sites de bombe
                  if (widget.hasBombOperationScenario && bombScenario != null)
                    MarkerLayer(
                      markers: _generateBombSiteMarkers(
                        context: context,
                        bombSites: bombOperationService
                                .activeSessionScenarioBomb
                                ?.bombOperationScenario
                                ?.bombSites ??
                            [],
                        teamRoles: bombOperationService.teamRoles,
                        userTeamId: widget.teamId,
                        toActivateBombSites:
                            bombOperationService.toActivateBombSites,
                        disableBombSites: bombOperationService.disableBombSites,
                        activeBombSites: bombOperationService.activeBombSites,
                      ),
                    ),
                ],
              ),
            ),
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

  void _openFullMapScreen(BuildContext context) {
    // S'assurer que le service de localisation est initialisé
    final locationService = GetIt.I<PlayerLocationService>();
    locationService.initialize(
        widget.userId, widget.teamId, widget.gameMap.fieldId!);

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

  // Méthode pour générer les cercles des sites de bombes
  List<CircleMarker> _generateBombSiteCircles({
    required BuildContext context,
    required List<BombSite> bombSites,
    required Map<int, BombOperationTeam> teamRoles,
    required int? userTeamId,
    required List<BombSite> toActivateBombSites,
    required List<BombSite> disableBombSites,
    required List<BombSite> activeBombSites,
  }) {
    if (bombSites.isEmpty) {
      return [];
    }

    final List<CircleMarker> circles = [];

    // Filtrer les sites visibles
    final visibleSites = _getVisibleBombSites(
      bombSites: bombSites,
      teamRoles: teamRoles,
      userTeamId: userTeamId,
      toActivateBombSites: toActivateBombSites,
      disableBombSites: disableBombSites,
      activeBombSites: activeBombSites,
    );

    // Créer un cercle pour chaque site visible
    for (final site in visibleSites) {
      // Déterminer l'état du site
      final siteState = _getBombSiteState(
        site: site,
        teamRoles: teamRoles,
        userTeamId: userTeamId,
        toActivateBombSites: toActivateBombSites,
        disableBombSites: disableBombSites,
        activeBombSites: activeBombSites,
      );

      // Ajouter le cercle
      circles.add(
        CircleMarker(
          point: LatLng(site.latitude, site.longitude),
          color: siteState.color.withOpacity(0.2),
          borderColor: siteState.color,
          borderStrokeWidth: 2.0,
          radius:
              site.radius, // Rayon en mètres (CircleLayer gère la conversion)
        ),
      );
    }

    return circles;
  }

// Méthode pour générer les marqueurs des icônes et noms des sites de bombes
  List<Marker> _generateBombSiteMarkers({
    required BuildContext context,
    required List<BombSite> bombSites,
    required Map<int, BombOperationTeam> teamRoles,
    required int? userTeamId,
    required List<BombSite> toActivateBombSites,
    required List<BombSite> disableBombSites,
    required List<BombSite> activeBombSites,
  }) {
    if (bombSites.isEmpty) {
      return [];
    }

    final List<Marker> markers = [];

    // Filtrer les sites visibles
    final visibleSites = _getVisibleBombSites(
      bombSites: bombSites,
      teamRoles: teamRoles,
      userTeamId: userTeamId,
      toActivateBombSites: toActivateBombSites,
      disableBombSites: disableBombSites,
      activeBombSites: activeBombSites,
    );

    // Créer un marqueur pour chaque site visible
    for (final site in visibleSites) {
      // Déterminer l'état du site
      final siteState = _getBombSiteState(
        site: site,
        teamRoles: teamRoles,
        userTeamId: userTeamId,
        toActivateBombSites: toActivateBombSites,
        disableBombSites: disableBombSites,
        activeBombSites: activeBombSites,
      );

      // Ajouter le marqueur
      markers.add(
        Marker(
          point: LatLng(site.latitude, site.longitude),
          width: 40,
          height: 40,
          child: _buildBombSiteMarkerContent(
            context: context,
            site: site,
            color: siteState.color,
            isPlanted: siteState.isPlanted,
          ),
        ),
      );
    }

    return markers;
  }

// Méthode pour filtrer les sites de bombes visibles selon le rôle de l'utilisateur
  List<BombSite> _getVisibleBombSites({
    required List<BombSite> bombSites,
    required Map<int, BombOperationTeam> teamRoles,
    required int? userTeamId,
    required List<BombSite> toActivateBombSites,
    required List<BombSite> disableBombSites,
    required List<BombSite> activeBombSites,
  }) {
    if (bombSites.isEmpty) {
      return [];
    }

    final bool isAttacker = isAttackTeam(userTeamId, teamRoles);
    final bool isDefender = isDefenseTeam(userTeamId, teamRoles);

    return bombSites.where((site) {
      final bool isActive = activeBombSites.any((s) => s.id == site.id);
      final bool isInToActivate =
          toActivateBombSites.any((s) => s.id == site.id);
      final bool isInDisabled = disableBombSites.any((s) => s.id == site.id);

      if (isAttacker) {
        // Les attaquants voient uniquement les bombes "à activer"
        return isInToActivate || isActive;
      } else if (isDefender) {
        // Les défenseurs voient toutes les bombes désactivées + celles activées
        return isInDisabled || isActive;
      }

      return false;
    }).toList();
  }

  // Méthode pour déterminer l'état d'un site de bombe
  BombSiteState _getBombSiteState({
    required BombSite site,
    required Map<int, BombOperationTeam> teamRoles,
    required int? userTeamId,
    required List<BombSite> toActivateBombSites,
    required List<BombSite> disableBombSites,
    required List<BombSite> activeBombSites,
  }) {
    // Déterminer si ce site est actif/planté
    final bool isActive = activeBombSites.any((s) => s.id == site.id);
    final bool isPlanted = activeBombSites.any((s) => s.id == site.id);

    // Déterminer si ce site doit être grisé
    final bool isAttacker = isAttackTeam(userTeamId, teamRoles);
    final bool isDefender = isDefenseTeam(userTeamId, teamRoles);
    final bool isGreyed = isDefender && !isPlanted && !isActive;

    // Couleur du site selon l'état
    Color color;
    if (isGreyed) {
      color = Colors.grey;
    } else if (isPlanted) {
      color = Colors.red;
    } else {
      color = site.getColor(context);
    }

    return BombSiteState(
      color: color,
      isPlanted: isPlanted,
      isGreyed: isGreyed,
    );
  }

// Méthode pour construire le contenu du marqueur (icône + nom)
  Widget _buildBombSiteMarkerContent({
    required BuildContext context,
    required BombSite site,
    required Color color,
    required bool isPlanted,
  }) {
    // Icône selon l'état
    final IconData iconData = isPlanted
        ? Icons.warning_amber_rounded // Bombe active
        : Icons.dangerous; // Site de bombe normal

    return Stack(
      children: [
        // Icône centrale
        Center(
          child: Icon(
            iconData,
            color: color,
            size: 30,
          ),
        ),

        // Nom du site
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              site.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
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
