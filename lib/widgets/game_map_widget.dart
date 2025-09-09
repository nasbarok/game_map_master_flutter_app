import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:game_map_master_flutter_app/models/game_map.dart';
import 'package:game_map_master_flutter_app/screens/gamesession/game_map_screen.dart';
import 'package:game_map_master_flutter_app/services/player_location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/coordinate.dart';
import '../models/game_session_participant.dart';
import '../models/team.dart';
import '../services/game_state_service.dart';
import '../services/scenario/bomb_operation/bomb_operation_service.dart';
import 'package:game_map_master_flutter_app/widgets/bomb_operation_map_widget_extension.dart';

import '../services/team_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

import '../../services/location/location_service_locator.dart';
import '../../services/location/location_models.dart';
import '../../widgets/location/location_indicator_widget.dart';

/// Widget pour afficher une carte miniature dans l'écran de session de jeu
class GameMapWidget extends StatefulWidget {
  final int gameSessionId;
  final GameMap gameMap;
  final int? fieldId;
  final int userId;
  final int? teamId;
  final bool hasBombOperationScenario;
  final List<GameSessionParticipant> participants;

  const GameMapWidget({
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
  State<GameMapWidget> createState() => _GameMapWidgetState();
}

class _GameMapWidgetState extends State<GameMapWidget> {
  final MapController _mapController = MapController();
  Map<int, Coordinate> _positions = {};
  StreamSubscription<Map<int, Coordinate>>? _positionSub;
  StreamSubscription<MapEvent>? _mapEventSub;
  late final Stream<Map<int, Coordinate>> _positionStream;

  bool _hasCenteredOnce = false;
  final BombOperationService bombOperationService =
      GetIt.I<BombOperationService>();
  StreamSubscription<EnhancedPosition>? _positionSubscription;
  EnhancedPosition? _currentPosition;
  final PlayerLocationService _playerLocationService =
      GetIt.I<PlayerLocationService>();

  @override
  void initState() {
    super.initState();
    logger.d('📍 [GameMapWidget] [initState] Initialisation du widget');

    final playerLocationService = GetIt.I<PlayerLocationService>();
    final l10n = AppLocalizations.of(context)!;

    // 🚀 Initialisation complète du tracking
    playerLocationService.initialize(
        widget.userId, widget.teamId, widget.fieldId!);
    playerLocationService.loadInitialPositions(widget.fieldId!);
    playerLocationService.startLocationTracking(widget.gameSessionId);

    _positionStream = playerLocationService.positionStream;

    // 🔄 Abonnement aux positions
    _positionSub = _positionStream.listen((posMap) {
      logger.d('📡 [GameMapWidget] Positions reçues : ${posMap.length}');

      if (!mounted) return;

      final participantIds = widget.participants.map((p) => p.userId).toList();
      final receivedIds = posMap.keys.toList();

      for (final entry in posMap.entries) {
        final userId = entry.key;
        final coord = entry.value;
        final participant = _findParticipantByUserId(userId);
        final username = participant?.username ?? l10n.unknownPlayerName;
        final team = participant?.teamName ?? l10n.noTeam;
        final isMe = userId == widget.userId ? ' 👈 (moi)' : '';
        logger.d(
            '🧭 $username (ID: $userId, équipe: $team)$isMe → lat=${coord.latitude}, lng=${coord.longitude}');
      }

      final missingUsers =
          participantIds.where((id) => !receivedIds.contains(id));
      if (missingUsers.isNotEmpty) {
        logger.w('⚠️ Participants sans position reçue :');
        for (final userId in missingUsers) {
          final participant = _findParticipantByUserId(userId);
          final name = participant?.username ?? l10n.unknownPlayerName;
          logger.w('⛔ $name (ID: $userId)');
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
        if (mounted) setState(() {});
      });
    });

    _mapEventSub = _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove && mounted) setState(() {});
    });
  }

  Future<void> _initializeAdvancedLocation() async {
    try {
      if (!locationService.isActive) {
        await locationService.start();
      }

      _positionSubscription = locationService.positionStream.listen(
        (position) {
          setState(() {
            _currentPosition = position;
          });
          // Intégrer avec votre WebSocket existant
          _sendPositionToServer(position);
        },
      );
    } catch (e) {
      logger.e('Erreur géolocalisation: $e');
    }
  }

  void _sendPositionToServer(EnhancedPosition position) {
    if (widget.fieldId == null) {
      logger.w('⚠️ Aucun fieldId disponible pour envoyer la position');
      return;
    }

    final correctedLat = position.latitude;
    final correctedLng = position.longitude;

    _playerLocationService.updatePlayerPosition(
      widget.userId,
      Coordinate(latitude: correctedLat, longitude: correctedLng),
    );

    _playerLocationService.shareEnhancedPosition(
      gameSessionId: widget.gameSessionId,
      fieldId: widget.fieldId!,
      userId: widget.userId,
      latitude: correctedLat,
      longitude: correctedLng,
      teamId: widget.teamId,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.gameMap.hasInteractiveMapConfig) {
      return const SizedBox.shrink();
    }

    final bombScenario = bombOperationService.activeSessionScenarioBomb;
    final gameState = bombOperationService.currentState;
    final roles = bombOperationService.teamRoles;
    final l10n = AppLocalizations.of(context)!;
/*    logger.d(
        '[GameMapWidget] [build] hasBombOperationScenario=${widget.hasBombOperationScenario}, bombScenario=$bombScenario, gameState=$gameState, roles=$roles');*/

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
                Text(
                  l10n.gameMapScreenTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  tooltip: l10n.showFullScreen,
                  onPressed: () => _openFullMapScreen(context, l10n),
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
                  if (widget.hasBombOperationScenario && bombScenario != null)
                    StreamBuilder<void>(
                      stream: bombOperationService.bombSitesStream,
                      builder: (context, snapshot) {
                        return MarkerLayer(
                          markers: generateBombSiteMarkers(
                            context: context,
                            bombScenario: bombScenario.bombOperationScenario!,
                            gameState: gameState,
                            teamRoles: roles,
                            userTeamId: widget.teamId,
                            toActivateBombSites:
                                bombOperationService.toActivateBombSites,
                            disableBombSites:
                                bombOperationService.disableBombSites,
                            activeBombSites:
                                bombOperationService.activeBombSites,
                            explodedBombSites:
                                bombOperationService.explodedBombSites,
                            currentZoom: _mapController.zoom,
                          ),
                        );
                      },
                    ),
                  MarkerLayer(
                    markers: _positions.entries
                        .map((entry) {
                          final userId = entry.key;
                          final position = entry.value;
                          if (userId == -1) {
                            return Marker(
                              point:
                                  LatLng(position.latitude, position.longitude),
                              width: 30,
                              height: 30,
                              child: const Icon(Icons.adjust,
                                  color: Colors.green, size: 20),
                            );
                          }
                          if (userId == -2) {
                            return Marker(
                              point:
                                  LatLng(position.latitude, position.longitude),
                              width: 30,
                              height: 30,
                              child: const Icon(Icons.center_focus_strong,
                                  color: Colors.orange, size: 20),
                            );
                          }
                          final participant = _findParticipantByUserId(userId);
                          if (participant?.teamId != widget.teamId) return null;

                          final isCurrentUser = userId == widget.userId;
                          final markerWidget =
                              _buildPlayerMarker(userId, isCurrentUser, l10n);
                          return Marker(
                            point:
                                LatLng(position.latitude, position.longitude),
                            width: 30,
                            height: 30,
                            child: markerWidget,
                          );
                        })
                        .whereType<Marker>() // pour filtrer les null
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          LocationIndicatorWidget(),
        ],
      ),
    );
  }

  void _openFullMapScreen(BuildContext context, AppLocalizations l10n) {
    try {
      // Pas besoin de réinitialiser le service de localisation, il est déjà initialisé dans le widget

      // Ouvrir l'écran de carte en plein écran
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameMapScreen(
            gameSessionId: widget.gameSessionId,
            gameMap: widget.gameMap,
            userId: widget.userId,
            teamId: widget.teamId,
            hasBombOperationScenario: widget.hasBombOperationScenario,
            participants: widget.participants,
            fieldId: widget.fieldId,
          ),
        ),
      );
    } catch (e) {
      logger.e(
          '❌ [_openFullMapScreen] Erreur lors de l\'ouverture de la carte en plein écran : $e');
      // Afficher un message d'erreur à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fullScreenMapError(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Widget _buildPlayerMarker(
      int userId, bool isCurrentUser, AppLocalizations l10n) {
    final participant = _findParticipantByUserId(userId);
    final String teamName = participant?.teamName ?? l10n.noTeam;
    final int? teamId = participant?.teamId;
    // Définir la couleur selon équipe
    Color markerColor = Colors.blue;

    final String playerName = _getPlayerName(userId, l10n);
    final double radius = 8;
    final double fontSize = math.max(8, radius);

    /*logger.d(
      '🎯 [GameMapWidget] [_buildPlayerMarker] '
      '${isCurrentUser ? "Moi" : playerName} '
      '(ID: $userId, équipe: $teamName, teamId: ${teamId ?? "N/A"}) '
      '→ couleur: $markerColor',
    );*/

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
  String _getPlayerName(int userId, AppLocalizations l10n) {
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

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapEventSub?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
