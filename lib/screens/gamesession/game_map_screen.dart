import 'dart:async';
import 'dart:math' as math show max;

import 'package:game_map_master_flutter_app/models/coordinate.dart';
import 'package:game_map_master_flutter_app/models/game_map.dart';
import 'package:game_map_master_flutter_app/services/player_location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/game_session_participant.dart';
import '../../models/scenario/bomb_operation/bomb_operation_state.dart';
import '../../services/scenario/bomb_operation/bomb_operation_service.dart';
import 'package:game_map_master_flutter_app/screens/scenario/bomb_operation/bomb_operation_map_extension.dart';

import 'package:game_map_master_flutter_app/utils/logger.dart';

import '../../services/location/location_service_locator.dart';
import '../../services/location/location_models.dart';
import '../../widgets/location/location_indicator_widget.dart';

enum TileLayerType {
  osm,
  satellite,
}

/// Écran affichant la carte en temps réel avec les positions des joueurs
class GameMapScreen extends StatefulWidget {
  final int gameSessionId;
  final GameMap gameMap;
  final int userId;
  final int? teamId;
  final int? fieldId;
  final bool hasBombOperationScenario;
  final List<GameSessionParticipant> participants;

  const GameMapScreen({
    Key? key,
    required this.gameSessionId,
    required this.gameMap,
    required this.fieldId,
    required this.userId,
    this.teamId,
    this.hasBombOperationScenario = false,
    required this.participants,
  }) : super(key: key);

  @override
  _GameMapScreenState createState() => _GameMapScreenState();
}

class _GameMapScreenState extends State<GameMapScreen> {
  final MapController _mapController = MapController();
  late PlayerLocationService _locationService;
  late BombOperationService _bombOperationService;

  StreamSubscription<Map<int, Coordinate>>? _positionSub;
  StreamSubscription<MapEvent>? _mapEventSub;

  late final Stream<Map<int, Coordinate>> _positionStream;

  Map<int, Coordinate> _positions = {};
  bool _hasCenteredOnce = false;

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
  TileLayerType _tileLayerType = TileLayerType.osm;

  final String _osmTileUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
  final String _satelliteTileUrl =
      "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}";

  // StreamSubscription<EnhancedPosition>? _positionSubscription; // Supprimé
  // EnhancedPosition? _currentPosition; // Supprimé
  // final PlayerLocationService _playerLocationService = GetIt.I<PlayerLocationService>(); // Supprimé, car PlayerLocationService est déjà obtenu via GetIt si nécessaire

  @override
  void initState() {
    super.initState();
    logger.d(
        '[GameMapScreen] [initState] ✅  initState sessionId=${widget.gameSessionId}');
    final playerLocationService = GetIt.I<PlayerLocationService>(); // Renommé pour clarté
    playerLocationService.initialize(widget.userId, widget.teamId, widget.fieldId!);
    logger.d(
        '🔄 [GameMapScreen]  [initState] [playerLocationService] Reconnecté. Chargement des positions initiales...');
    playerLocationService.loadInitialPositions(widget.fieldId!);
    playerLocationService.startLocationTracking(widget.gameSessionId); // Cet appel est crucial et conservé
    _positionSub = playerLocationService.positionStream.listen(_handlePositionStream);

    logger.d(
        '[GameMapScreen] ✅ _positionSub initialisé depuis playerLocationService.positionStream');

    if (widget.hasBombOperationScenario) {
      _bombOperationService = GetIt.I<BombOperationService>();
    }

    _mapEventSub = _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove && mounted) {
        setState(() {});
      }
    });

    // _initializeAdvancedLocation(); // Supprimé
  }

  @override
  void dispose() {
    if (widget.hasBombOperationScenario) {
      // Il est important de vérifier si _bombOperationService a été initialisé avant d'appeler dispose.
      // Cependant, la logique actuelle l'initialise uniquement si hasBombOperationScenario est vrai,
      // donc cette vérification est implicitement correcte.
      _bombOperationService.dispose();
    }
    _positionSub?.cancel();
    _mapEventSub?.cancel();
    // _positionSubscription?.cancel(); // Déjà supprimé car _positionSubscription est supprimé
    super.dispose();
  }

  // _initializeAdvancedLocation() et _sendPositionToServer() supprimés

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: Text(l10n.gameMapScreenTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  tooltip: l10n.fullscreenTooltip,
                  onPressed: () {
                    setState(() {
                      _isFullScreen = true;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    _tileLayerType == TileLayerType.osm
                        ? Icons.satellite_alt
                        : Icons.map,
                  ),
                  tooltip: _tileLayerType == TileLayerType.osm
                      ? l10n.satelliteViewTooltip
                      : l10n.standardViewTooltip,
                  onPressed: () {
                    setState(() {
                      _tileLayerType = _tileLayerType == TileLayerType.osm
                          ? TileLayerType.satellite
                          : TileLayerType.osm;
                    });
                  },
                ),
                LocationIndicatorWidget(),
              ],
            ),
      body: Stack(
        children: [
          // Carte interactive
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: LatLng(widget.gameMap.centerLatitude!,
                  widget.gameMap.centerLongitude!),
              zoom: widget.gameMap.initialZoom ?? 13.0,
              minZoom: 3.0,
              maxZoom: 22.0,
            ),
            children: [
              // Couche de tuiles (fond de carte)
              TileLayer(
                urlTemplate: _activeTileUrl,
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
              // Sites de bombe (si le scénario Bombe est actif)
              if (widget.hasBombOperationScenario)
                StreamBuilder<void>(
                  stream: _bombOperationService.bombSitesStream,
                  builder: (context, snapshot) {
                    return MarkerLayer(
                      markers: widget.generateBombSiteMarkers(
                        context: context,
                        bombScenario: _bombOperationService
                            .activeSessionScenarioBomb!.bombOperationScenario!,
                        gameState: _bombOperationService.currentState,
                        teamRoles: _bombOperationService.teamRoles,
                        userTeamId: widget.teamId,
                        toActivateBombSites:
                            _bombOperationService.toActivateBombSites,
                        disableBombSites:
                            _bombOperationService.disableBombSites,
                        activeBombSites: _bombOperationService.activeBombSites,
                        explodedBombSites:
                            _bombOperationService.explodedBombSites,
                        currentZoom: _mapController.zoom,
                      ),
                    );
                  },
                ),
              // Positions des joueurs
              MarkerLayer(
                markers: _positions.entries
                    .map((entry) {
                      final userId = entry.key;
                      final position = entry.value;
                      logger.d(
                          '[GameMapScreen] 🔄 Traitement position userId=$userId : $position');

                      final participant = _findParticipantByUserId(userId);
                      if (participant == null) {
                        logger.w(
                            '[GameMapScreen] ⚠️ Aucun participant trouvé pour userId=$userId');
                        return null;
                      }

                      final isCurrentUser = userId == widget.userId;
                      logger.d(
                          '[GameMapScreen] 👤 ${participant.username} (ID: $userId, teamId=${participant.teamId}, isMe=$isCurrentUser)');

                      if (!isCurrentUser &&
                          participant.teamId != widget.teamId) {
                        logger.d(
                            '[GameMapScreen] ❌ Marqueur ignoré pour ${participant.username} '
                            '(équipe différente) → participant.teamId=${participant.teamId} != widget.teamId=${widget.teamId}');
                        return null;
                      }

                      logger.d(
                          '[GameMapScreen] ✅ Marqueur créé pour ${participant.username}');
                      final markerWidget =
                          _buildPlayerMarker(userId, isCurrentUser);
                      return Marker(
                        point: LatLng(position.latitude, position.longitude),
                        width: 30,
                        height: 30,
                        child: markerWidget,
                      );
                    })
                    .whereType<Marker>()
                    .toList(),
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
                  tooltip: l10n.fullscreenTooltip, // Assuming exit fullscreen is similar enough
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
              tooltip: l10n.centerOnLocationTooltip,
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
                          l10n.bombTimeRemaining(_formatTime(_bombOperationService.bombTimeRemaining)),
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
    final l10n = AppLocalizations.of(context)!;
    try {
      final positions = GetIt.I<PlayerLocationService>().currentPlayerPositions;
      if (positions.containsKey(widget.userId)) {
        final myPosition = positions[widget.userId]!;
        _mapController.move(
          LatLng(myPosition.latitude, myPosition.longitude),
          _mapController.zoom,
        );
      }
    } catch (e) {
      logger.d('Erreur lors du centrage sur la position actuelle: $e');
    }
  }

  Widget _buildPlayerMarker(int userId, bool isCurrentUser) {
    final l10n = AppLocalizations.of(context)!;
    final participant = _findParticipantByUserId(userId);
    final String teamName = participant?.teamName ?? l10n.noTeam;
    final int? teamId = participant?.teamId;
    // Définir la couleur selon équipe
    Color markerColor = Colors.blue;

    final String playerName = _getPlayerName(userId);
    final double radius = 8;
    final double fontSize = math.max(8, radius);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: markerColor,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
        ),
        Positioned(
          top: radius * 2 + 2,
          child: Text(
            playerName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.deepPurple[800],
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  offset: Offset(0, 0),
                  blurRadius: 2,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

// Méthode pour récupérer le nom du joueur
  String _getPlayerName(int userId) {
    final l10n = AppLocalizations.of(context)!;
    final participant = widget.participants
        .where((p) => p.userId == userId)
        .cast<GameSessionParticipant?>()
        .firstOrNull;

    return participant?.username ?? l10n.playerMarkerLabel(userId.toString());
  }

  GameSessionParticipant? _findParticipantByUserId(int userId) {
    for (final p in widget.participants) {
      if (p.userId == userId) return p;
    }
    return null;
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

  void _handlePositionStream(Map<int, Coordinate> posMap) {
    logger.d(
        '[GameMapScreen] [handlePositionStream] 🔔 Stream position reçu : ${posMap.length} positions');

    if (!mounted) return;

    logger.d('📡 [GameMapScreen] Positions reçues (${posMap.length}) :');
    final List<int> receivedIds = posMap.keys.toList();
    final List<int> participantIds =
        widget.participants.map((p) => p.userId).toList();

    for (final entry in posMap.entries) {
      final userId = entry.key;
      final coord = entry.value;
      final participant = _findParticipantByUserId(userId);
      final username = participant?.username ?? 'Inconnu';
      final team = participant?.teamName ?? 'Sans équipe';
      final role = participant?.participantType ?? 'PLAYER';
      final isCurrentUser = userId == widget.userId ? ' 👈 (moi)' : '';
      logger.d(
          '🧭 $username (ID: $userId, équipe: $team, rôle: $role)$isCurrentUser → '
          'lat=${coord.latitude}, lng=${coord.longitude}');
    }

    final missingUsers =
        participantIds.where((id) => !receivedIds.contains(id));
    if (missingUsers.isNotEmpty) {
      logger.w('⚠️ Participants sans position reçue :');
      for (final userId in missingUsers) {
        final participant = _findParticipantByUserId(userId);
        final name = participant?.username ?? 'Inconnu';
        logger.w(
            '⛔ $name (ID: $userId, équipe: ${participant?.teamName ?? "N/A"})');
      }
    }

    setState(() {
      _positions = posMap;
    });

    if (!_hasCenteredOnce && posMap.containsKey(widget.userId)) {
      final pos = posMap[widget.userId]!;
      _mapController.move(
        LatLng(pos.latitude, pos.longitude),
        widget.gameMap.initialZoom ?? 16.0,
      );
      _hasCenteredOnce = true;
      logger.d('📍 Carte recentrée sur la position du joueur : $pos');
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {}); // Forcer le redessin
      }
    });
  }

  String get _activeTileUrl {
    return _tileLayerType == TileLayerType.osm
        ? _osmTileUrl
        : _satelliteTileUrl;
  }
}
