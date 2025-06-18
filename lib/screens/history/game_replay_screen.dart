import 'dart:async';
import 'package:airsoft_game_map/models/coordinate.dart';
import 'package:airsoft_game_map/models/game_map.dart';
import 'package:airsoft_game_map/models/game_session_position_history.dart';
import 'package:airsoft_game_map/models/player_position.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_history.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_site_history.dart';
import 'package:airsoft_game_map/services/player_location_service.dart';
import 'package:airsoft_game_map/services/scenario/bomb_operation/bomb_operation_history_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:airsoft_game_map/utils/logger.dart';

/// Écran de replay des déplacements des joueurs et des événements Bomb Operation
class GameReplayScreen extends StatefulWidget {
  final int gameSessionId;
  final GameMap gameMap;
  
  const GameReplayScreen({
    Key? key,
    required this.gameSessionId,
    required this.gameMap,
  }) : super(key: key);
  
  @override
  _GameReplayScreenState createState() => _GameReplayScreenState();
}

class _GameReplayScreenState extends State<GameReplayScreen> {
  final MapController _mapController = MapController();
  late PlayerLocationService _locationService;
  late BombOperationHistoryService _bombHistoryService;

  GameSessionPositionHistory? _positionHistory;
  BombOperationHistory? _bombHistory;
  bool _isLoading = true;
  String? _errorMessage;
  
  // État du replay
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  Timer? _playbackTimer;
  
  // Curseur de temps
  DateTime? _startTime;
  DateTime? _endTime;
  DateTime? _currentTime;
  
  // Positions affichées actuellement
  Map<int, Coordinate> _displayedPositions = {};
  
  // État des sites de bombe au temps actuel
  Map<int, BombSiteHistory> _currentBombSitesState = {};

  // Événements visibles jusqu'au temps actuel
  List<BombEvent> _visibleEvents = [];

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
  
  // Informations sur les équipes des joueurs
  final Map<int, int?> _playerTeams = {};
  
  @override
  void initState() {
    super.initState();
    _locationService = GetIt.I<PlayerLocationService>();
    _bombHistoryService = BombOperationHistoryService();
    _loadReplayData();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    super.dispose();
  }
  
  Future<void> _loadReplayData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Charger l'historique des positions
      final positionHistory = await _locationService.getPositionHistory(widget.gameSessionId);

      // Charger l'historique Bomb Operation (si disponible)
      BombOperationHistory? bombHistory;
      try {
        bombHistory = await _bombHistoryService.getSessionHistory(widget.gameSessionId);
      } catch (e) {
        // Pas d'historique Bomb Operation disponible, continuer sans
        logger.d('Aucun historique Bomb Operation trouvé: $e');
      }
      
      // Déterminer les timestamps de début et de fin
      DateTime? earliest;
      DateTime? latest;
      
      // Extraire les informations d'équipe des joueurs
      positionHistory.playerPositions.forEach((userId, positions) {
        for (final position in positions) {
          if (earliest == null || position.timestamp.isBefore(earliest!)) {
            earliest = position.timestamp;
          }
          if (latest == null || position.timestamp.isAfter(latest!)) {
            latest = position.timestamp;
          }
          
          // Stocker l'équipe du joueur (utiliser la dernière valeur connue)
          if (position.teamId != null) {
            _playerTeams[userId] = position.teamId;
          }
        }
      });
      
      // Étendre la plage de temps avec les événements Bomb Operation
      if (bombHistory != null) {
        for (final event in bombHistory.timeline) {
          if (earliest == null || event.timestamp.isBefore(earliest!)) {
            earliest = event.timestamp;
          }
          if (latest == null || event.timestamp.isAfter(latest!)) {
            latest = event.timestamp;
          }
        }
      }

      setState(() {
        _positionHistory = positionHistory;
        _bombHistory = bombHistory;
        _startTime = earliest;
        _endTime = latest;
        _currentTime = earliest;
        _isLoading = false;
        
        // Initialiser les positions et états affichés au début
        _updateDisplayedData();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement de l\'historique: $e';
        _isLoading = false;
      });
    }
  }
  
  void _updateDisplayedData() {
    if (_currentTime == null) return;

    _updateDisplayedPositions();
    _updateBombSitesState();
    _updateVisibleEvents();
  }

  void _updateDisplayedPositions() {
    if (_currentTime == null || _positionHistory == null) return;
    
    final newPositions = <int, Coordinate>{};
    
    _positionHistory!.playerPositions.forEach((userId, positions) {
      // Trouver la position la plus proche du temps actuel
      PlayerPosition? closestPosition;
      Duration? smallestDifference;
      
      for (final position in positions) {
        final difference = position.timestamp.difference(_currentTime!).abs();
        if (smallestDifference == null || difference < smallestDifference) {
          smallestDifference = difference;
          closestPosition = position;
        }
      }
      
      if (closestPosition != null) {
        newPositions[userId] = Coordinate(
          latitude: closestPosition.latitude,
          longitude: closestPosition.longitude
        );
      }
    });
    
    setState(() {
      _displayedPositions = newPositions;
    });
  }
  
  void _updateBombSitesState() {
    if (_currentTime == null || _bombHistory == null) return;

    final newSitesState = <int, BombSiteHistory>{};

    for (final siteHistory in _bombHistory!.bombSitesHistory) {
      // Créer un nouvel état basé sur l'état actuel
      BombSiteHistory currentState = BombSiteHistory(
        id: siteHistory.id,
        gameSessionId: siteHistory.gameSessionId,
        originalBombSiteId: siteHistory.originalBombSiteId,
        name: siteHistory.name,
        latitude: siteHistory.latitude,
        longitude: siteHistory.longitude,
        radius: siteHistory.radius,
        status: _calculateStatusAtTime(siteHistory, _currentTime!),
        createdAt: siteHistory.createdAt,
        updatedAt: siteHistory.updatedAt,
        activatedAt: siteHistory.activatedAt,
        armedAt: siteHistory.armedAt,
        disarmedAt: siteHistory.disarmedAt,
        explodedAt: siteHistory.explodedAt,
        armedByUserId: siteHistory.armedByUserId,
        armedByUserName: siteHistory.armedByUserName,
        disarmedByUserId: siteHistory.disarmedByUserId,
        disarmedByUserName: siteHistory.disarmedByUserName,
        bombTimer: siteHistory.bombTimer,
        expectedExplosionAt: siteHistory.expectedExplosionAt,
        timeRemainingSeconds: siteHistory.timeRemainingSeconds,
        shouldHaveExploded: siteHistory.shouldHaveExploded,
      );

      // Vérifier si le site était créé à ce moment
      if (siteHistory.createdAt.isAfter(_currentTime!)) {
        continue; // Site pas encore créé
      }

      newSitesState[siteHistory.originalBombSiteId] = currentState;
    }

    setState(() {
      _currentBombSitesState = newSitesState;
    });
  }

  String _calculateStatusAtTime(BombSiteHistory siteHistory, DateTime time) {
    // Déterminer le statut au temps donné
    String status = 'INACTIVE';

    if (siteHistory.activatedAt != null && !time.isBefore(siteHistory.activatedAt!)) {
      status = 'ACTIVE';
    }

    if (siteHistory.armedAt != null && !time.isBefore(siteHistory.armedAt!)) {
      status = 'ARMED';
    }

    if (siteHistory.disarmedAt != null && !time.isBefore(siteHistory.disarmedAt!)) {
      status = 'DISARMED';
    }

    if (siteHistory.explodedAt != null && !time.isBefore(siteHistory.explodedAt!)) {
      status = 'EXPLODED';
    }

    return status;
  }

  void _updateVisibleEvents() {
    if (_currentTime == null || _bombHistory == null) return;

    final visibleEvents = _bombHistory!.timeline
        .where((event) => !event.timestamp.isAfter(_currentTime!))
        .toList();

    setState(() {
      _visibleEvents = visibleEvents;
    });
  }

  void _startPlayback() {
    if (_currentTime == null || _endTime == null) return;
    
    _stopPlayback();
    
    setState(() {
      _isPlaying = true;
    });
    
    // Calculer l'intervalle en fonction de la vitesse
    final interval = Duration(milliseconds: (1000 / _playbackSpeed).round());
    
    _playbackTimer = Timer.periodic(interval, (timer) {
      if (_currentTime == null || _endTime == null) {
        _stopPlayback();
        return;
      }
      
      // Avancer le temps de 1 seconde * vitesse
      final newTime = _currentTime!.add(Duration(seconds: 1));
      
      // Si on a dépassé la fin, arrêter le replay
      if (newTime.isAfter(_endTime!)) {
        _stopPlayback();
        return;
      }
      
      setState(() {
        _currentTime = newTime;
      });
      
      _updateDisplayedData();
    });
  }
  
  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;

    if (!mounted) return;

    setState(() {
      _isPlaying = false;
    });
  }
  
  void _setPlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    
    // Redémarrer le timer avec la nouvelle vitesse si en cours de lecture
    if (_isPlaying) {
      _startPlayback();
    }
  }
  
  void _onTimelineChanged(double value) {
    if (_startTime == null || _endTime == null) return;
    
    final totalDuration = _endTime!.difference(_startTime!);
    final newTime = _startTime!.add(Duration(
      milliseconds: (totalDuration.inMilliseconds * value).round(),
    ));
    
    setState(() {
      _currentTime = newTime;
    });
    
    _updateDisplayedData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Replay de la session'),
        actions: [
          if (_bombHistory != null)
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: _showBombOperationSummary,
              tooltip: 'Résumé Bomb Operation',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReplayData,
                        child: Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Panneau d'information Bomb Operation (si disponible)
                    if (_bombHistory != null)
                      _buildBombOperationInfoPanel(),

                    // Carte
                    Expanded(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(
                            widget.gameMap.centerLatitude ?? 0.0,
                            widget.gameMap.centerLongitude ?? 0.0,
                          ),
                          initialZoom: widget.gameMap.initialZoom ?? 13.0,
                          minZoom: 5.0,
                          maxZoom: 18.0,
                        ),
                        children: [
                          // Couche de tuiles
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),

                          // Sites de bombe (si disponibles)
                          if (_bombHistory != null)
                            MarkerLayer(
                              markers: _currentBombSitesState.values.map((siteState) {
                                return Marker(
                                  point: LatLng(siteState.latitude, siteState.longitude),
                                  width: 60,
                                  height: 60,
                                  child: _buildBombSiteMarker(siteState),
                                );
                              }).toList(),
                            ),

                          // Points d'intérêt
                          if (widget.gameMap.mapPointsOfInterest != null)
                            MarkerLayer(
                              markers: widget.gameMap.mapPointsOfInterest!
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
                          MarkerLayer(
                            markers: _displayedPositions.entries.map((entry) {
                              final userId = entry.key;
                              final position = entry.value;
                              final teamId = _playerTeams[userId];

                              return Marker(
                                point: LatLng(position.latitude, position.longitude),
                                width: 40,
                                height: 40,
                                child: _buildPlayerMarker(userId, teamId),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // Contrôles de replay
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[200],
                      child: Column(
                        children: [
                          // Affichage du temps actuel
                          Text(
                            _currentTime != null
                              ? _formatDateTime(_currentTime!)
                              : '--:--:--',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Timeline (slider)
                          Slider(
                            value: _calculateTimelineValue(),
                            onChanged: _onTimelineChanged,
                            min: 0.0,
                            max: 1.0,
                          ),

                          // Contrôles de lecture
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                                onPressed: _isPlaying ? _stopPlayback : _startPlayback,
                                iconSize: 36,
                              ),
                              const SizedBox(width: 16),
                              Flexible(
                                child: Wrap(
                                  spacing: 8,
                                  children: [
                                    _buildSpeedButton(0.5),
                                    _buildSpeedButton(1.0),
                                    _buildSpeedButton(2.0),
                                    _buildSpeedButton(4.0),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ===== MÉTHODES POUR L'INTERFACE BOMB OPERATION =====

  Widget _buildBombOperationInfoPanel() {
    if (_bombHistory == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Résumé des équipes
          Row(
            children: [
              // Équipe Terroriste
              Expanded(
                child: _buildTeamSummary(
                  'Terroristes',
                  Colors.red,
                  _bombHistory!.finalStats.armedSites,
                  _bombHistory!.finalStats.explodedSites,
                  'Bombes armées',
                  'Bombes explosées',
                ),
              ),
              SizedBox(width: 16),
              // Équipe Anti-terroriste
              Expanded(
                child: _buildTeamSummary(
                  'Anti-terroristes',
                  Colors.blue,
                  _bombHistory!.finalStats.totalSites - _bombHistory!.finalStats.armedSites,
                  _bombHistory!.finalStats.disarmedSites,
                  'Sites protégés',
                  'Bombes désarmées',
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Résultat final
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: _getResultColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getResultText(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          SizedBox(height: 12),

          // Timeline des événements visibles
          if (_visibleEvents.isNotEmpty)
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _visibleEvents.length,
                itemBuilder: (context, index) {
                  final event = _visibleEvents[index];
                  return Container(
                    width: 200,
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getEventIcon(event.eventType),
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(height: 4),
                        Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          event.siteName,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeamSummary(String teamName, Color teamColor, int stat1, int stat2, String label1, String label2) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: teamColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: teamColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: teamColor,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text('$label1: $stat1'),
          Text('$label2: $stat2'),
        ],
      ),
    );
  }
  
  Widget _buildBombSiteMarker(BombSiteHistory siteState) {
    Color markerColor;
    IconData markerIcon;

    switch (siteState.status) {
      case 'ACTIVE':
        markerColor = Colors.orange;
        markerIcon = Icons.radio_button_checked;
        break;
      case 'ARMED':
        markerColor = Colors.red;
        markerIcon = Icons.dangerous;
        break;
      case 'DISARMED':
        markerColor = Colors.blue;
        markerIcon = Icons.check_circle;
        break;
      case 'EXPLODED':
        markerColor = Colors.black;
        markerIcon = Icons.whatshot;
        break;
      default:
        markerColor = Colors.grey;
        markerIcon = Icons.radio_button_unchecked;
    }

    return Container(
      decoration: BoxDecoration(
        color: markerColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(
        markerIcon,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  void _showBombOperationSummary() {
    if (_bombHistory == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Résumé Bomb Operation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Scénario: ${_bombHistory!.scenarioName}'),
              Text('Sites actifs: ${_bombHistory!.activeSites}'),
              Text('Timer bombe: ${_bombHistory!.bombTimer}s'),
              Text('Temps désarmement: ${_bombHistory!.defuseTime}s'),
              SizedBox(height: 16),
              Text('Résultat final:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_getResultText()),
              SizedBox(height: 16),
              Text('Statistiques:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Bombes armées: ${_bombHistory!.finalStats.armedSites}'),
              Text('Bombes désarmées: ${_bombHistory!.finalStats.disarmedSites}'),
              Text('Bombes explosées: ${_bombHistory!.finalStats.explodedSites}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Color _getResultColor() {
    if (_bombHistory == null) return Colors.grey;

    final winningTeam = _bombHistory!.finalStats.winningTeam;
    switch (winningTeam) {
      case 'ATTACK':
        return Colors.red;
      case 'DEFENSE':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _getResultText() {
    if (_bombHistory == null) return 'Aucun résultat';

    final winningTeam = _bombHistory!.finalStats.winningTeam;
    switch (winningTeam) {
      case 'ATTACK':
        return '🔥 Victoire des Terroristes';
      case 'DEFENSE':
        return '🛡️ Victoire des Anti-terroristes';
      default:
        return '🤝 Match nul';
    }
  }

  Widget _buildSpeedButton(double speed) {
    final isSelected = _playbackSpeed == speed;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black,
        ),
        onPressed: () => _setPlaybackSpeed(speed),
        child: Text('x${speed == speed.toInt() ? speed.toInt().toString() : speed.toString()}'),
      ),
    );
  }
  
  Widget _buildPlayerMarker(int userId, int? teamId) {
    final Color markerColor = teamId != null 
      ? _teamColors[teamId] ?? Colors.grey
      : Colors.grey;
    
    return Icon(
      Icons.location_on,
      color: markerColor,
      size: 30,
    );
  }
  
  double _calculateTimelineValue() {
    if (_startTime == null || _endTime == null || _currentTime == null) {
      return 0.0;
    }
    
    final totalDuration = _endTime!.difference(_startTime!).inMilliseconds;
    if (totalDuration <= 0) return 0.0;
    
    final currentOffset = _currentTime!.difference(_startTime!).inMilliseconds;
    return currentOffset / totalDuration;
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
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
  

  String _getEventIcon(String eventType) {
    switch (eventType) {
      case 'ACTIVATED':
        return '🟠';
      case 'ARMED':
        return '💣';
      case 'DISARMED':
        return '🛡️';
      case 'EXPLODED':
        return '💥';
      default:
        return '📍';
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

