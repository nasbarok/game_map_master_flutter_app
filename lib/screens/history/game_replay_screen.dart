import 'dart:async';
import 'package:airsoft_game_map/models/coordinate.dart';
import 'package:airsoft_game_map/models/game_map.dart';
import 'package:airsoft_game_map/models/game_session_position_history.dart';
import 'package:airsoft_game_map/models/player_position.dart';
import 'package:airsoft_game_map/services/player_location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

/// Écran de replay des déplacements des joueurs
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
  
  GameSessionPositionHistory? _positionHistory;
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
    _loadPositionHistory();
  }
  
  @override
  void dispose() {
    _stopPlayback();
    super.dispose();
  }
  
  Future<void> _loadPositionHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final history = await _locationService.getPositionHistory(widget.gameSessionId);
      
      // Déterminer les timestamps de début et de fin
      DateTime? earliest;
      DateTime? latest;
      
      // Extraire les informations d'équipe des joueurs
      history.playerPositions.forEach((userId, positions) {
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
      
      setState(() {
        _positionHistory = history;
        _startTime = earliest;
        _endTime = latest;
        _currentTime = earliest;
        _isLoading = false;
        
        // Initialiser les positions affichées au début
        _updateDisplayedPositions();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement de l\'historique: $e';
        _isLoading = false;
      });
    }
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
      
      _updateDisplayedPositions();
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
    
    // Si le replay est en cours, redémarrer avec la nouvelle vitesse
    if (_isPlaying) {
      _stopPlayback();
      _startPlayback();
    }
  }
  
  void _onTimelineChanged(double value) {
    if (_startTime == null || _endTime == null) return;
    
    // Calculer le nouveau temps en fonction de la valeur du slider
    final totalDuration = _endTime!.difference(_startTime!).inMilliseconds;
    final newTimeOffset = (totalDuration * value).round();
    final newTime = _startTime!.add(Duration(milliseconds: newTimeOffset));
    
    setState(() {
      _currentTime = newTime;
    });
    
    _updateDisplayedPositions();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Replay de la partie'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : Column(
              children: [
                // Carte interactive (prend la majorité de l'espace)
                Expanded(
                  child: FlutterMap(
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
                            child: Tooltip( // ✅ Remplace "builder" par "child"
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
                            child: _buildPlayerMarker(userId, teamId), // ✅ ici aussi
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
                          // Bouton play/pause
                          IconButton(
                            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                            onPressed: _isPlaying ? _stopPlayback : _startPlayback,
                            iconSize: 36,
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Boutons de vitesse
                          _buildSpeedButton(1.0),
                          _buildSpeedButton(2.0),
                          _buildSpeedButton(3.0),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
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
        child: Text('x${speed.toInt()}'),
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
