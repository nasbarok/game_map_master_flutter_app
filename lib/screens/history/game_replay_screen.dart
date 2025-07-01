import 'dart:async';
import 'package:game_map_master_flutter_app/models/coordinate.dart';
import 'package:game_map_master_flutter_app/models/game_map.dart';
import 'package:game_map_master_flutter_app/models/game_session_position_history.dart';
import 'package:game_map_master_flutter_app/models/player_position.dart';
import 'package:game_map_master_flutter_app/services/player_location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/scenario/scenario_detector_service.dart';
import '../../models/scenario/scenario_replay_extension.dart';

/// Écran de replay extensible des déplacements des joueurs et des scénarios
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
  late ScenarioDetectorService _scenarioDetector;

  GameSessionPositionHistory? _positionHistory;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Extensions de scénarios (peut supporter plusieurs scénarios simultanés)
  List<ScenarioReplayExtension> _scenarioExtensions = [];

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
    _scenarioDetector = ScenarioDetectorService();

    // Écoute du zoom pour mise à jour des extensions
    _mapController.mapEventStream.listen((event) {
      final currentZoom = _mapController.zoom;
      for (final extension in _scenarioExtensions) {
        extension.updateZoom(currentZoom);
      }
    });

    _loadReplayData();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _scenarioDetector.disposeExtensions(_scenarioExtensions);
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

      // Détecter et charger les extensions de scénarios appropriées
      _scenarioExtensions = await _scenarioDetector.detectAndLoadScenarios(widget.gameSessionId);
      
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
      
      // Étendre la plage de temps avec les données des scénarios si disponibles
      for (final extension in _scenarioExtensions) {
        if (extension.hasData) {
          // Les extensions peuvent avoir leurs propres timestamps
          // Pour l'instant, on garde la logique simple
        }
      }

      setState(() {
        _positionHistory = positionHistory;
        _startTime = earliest;
        _endTime = latest;
        _currentTime = earliest;
        _isLoading = false;
        
        // Initialiser les positions et états affichés au début
        _updateDisplayedData();
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.errorLoadingHistory(e.toString());
        _isLoading = false;
      });
    }
  }
  
  void _updateDisplayedData() {
    if (_currentTime == null) return;

    _updateDisplayedPositions();

    // Mettre à jour l'état de tous les scénarios chargés
    for (final extension in _scenarioExtensions) {
      extension.updateState(_currentTime!);
    }
  }

  void _updateDisplayedPositions() {
    if (_currentTime == null || _positionHistory == null) return;
    
    final newPositions = <int, Coordinate>{};
    
    _positionHistory!.playerPositions.forEach((userId, positions) {
      // Trouver la position la plus récente avant ou égale au temps actuel
      PlayerPosition? lastValidPosition;
      
      for (final position in positions) {
        if (position.timestamp.isAfter(_currentTime!)) {
          break; // Les positions sont triées par timestamp
        }
        lastValidPosition = position;
      }
      
      if (lastValidPosition != null) {
        newPositions[userId] = Coordinate(
          latitude: lastValidPosition.latitude,
          longitude: lastValidPosition.longitude,
        );
      }
    });
    
    setState(() {
      _displayedPositions = newPositions;
    });
  }

  void _startPlayback() {
    if (_startTime == null || _endTime == null || _currentTime == null) return;
    
    setState(() {
      _isPlaying = true;
    });
    
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(Duration(milliseconds: (1000 / _playbackSpeed).round()), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.replayScreenTitle),
            if (_scenarioExtensions.isNotEmpty)
              Text(
                _scenarioExtensions.map((e) => e.scenarioName).join(', '),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (_scenarioExtensions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showScenarioSummary,
              tooltip: l10n.scenarioSummaryTitle,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReplayData,
                        child: Text(l10n.retryButton),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Panneaux d'information des scénarios (si disponibles)
                    for (final extension in _scenarioExtensions)
                      if (extension.hasData && extension.buildInfoPanel() != null)
                        extension.buildInfoPanel()!,

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
                          minZoom: 3.0,
                          maxZoom: 20.0,
                        ),
                        children: [
                          // Couche de tuiles
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),

                          // Marqueurs des scénarios (si extensions disponibles)
                          for (final extension in _scenarioExtensions)
                            if (extension.hasData)
                              MarkerLayer(
                                markers: extension.buildMarkers(),
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
                                width: 30,
                                height: 30,
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

                          // Slider de timeline
                          if (_startTime != null && _endTime != null && _currentTime != null)
                            Slider(
                              value: _endTime!.difference(_startTime!).inMilliseconds > 0
                                  ? _currentTime!.difference(_startTime!).inMilliseconds /
                                    _endTime!.difference(_startTime!).inMilliseconds
                                  : 0.0,
                              onChanged: _onTimelineChanged,
                              min: 0.0,
                              max: 1.0,
                            ),

                          const SizedBox(height: 8),

                          // Contrôles de lecture
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Bouton Play/Pause
                                IconButton(
                                  onPressed: _isPlaying ? _stopPlayback : _startPlayback,
                                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                                  iconSize: 32,
                                ),

                                const SizedBox(width: 16),

                                // Sélecteur de vitesse
                                Text(l10n.playbackSpeedLabel(_playbackSpeed.toString())),
                                const SizedBox(width: 8),

                                _buildSpeedButton(0.5),
                                _buildSpeedButton(1.0),
                                _buildSpeedButton(2.0),
                                _buildSpeedButton(4.0),
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

  Widget _buildSpeedButton(double speed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ElevatedButton(
        onPressed: () => _setPlaybackSpeed(speed),
        style: ElevatedButton.styleFrom(
          backgroundColor: _playbackSpeed == speed ? Colors.blue : Colors.grey[300],
          foregroundColor: _playbackSpeed == speed ? Colors.white : Colors.black,
          minimumSize: const Size(30, 24),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: Text('${speed}x', style: const TextStyle(fontSize: 12)),
      ),
    );
  }

    Widget _buildPlayerMarker(int userId, int? teamId) {
    final color = teamId != null ? _teamColors[teamId] ?? Colors.grey : Colors.grey;
    // final String playerName = userId.toString(); // Remplacé par l10n si nécessaire
    final l10n = AppLocalizations.of(context)!;
    final String playerName = l10n.playerMarkerLabel(userId.toString());
    final double radius = 8;
    final double fontSize = 8;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Point du joueur
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
        ),
        // Nom du joueur en dessous
        Positioned(
          top: radius * 2 + 2,
          child: Text(
            playerName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black87,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: const Offset(0.5, 0.5),
                  blurRadius: 1.0,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  IconData _getIconDataFromIdentifier(String identifier) {
    switch (identifier) {
      case 'location_on':
        return Icons.location_on;
      case 'flag':
        return Icons.flag;
      case 'star':
        return Icons.star;
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'directions_car':
        return Icons.directions_car;
      default:
        return Icons.place;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }

  void _showScenarioSummary() {
    final l10n = AppLocalizations.of(context)!;
    if (_scenarioExtensions.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.scenarioSummaryTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final extension in _scenarioExtensions)
                if (extension.hasData) ...[
                  Text(
                    extension.scenarioName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  extension.buildInfoPanel() ?? Text(l10n.scenarioInfoNotAvailable),
                  const SizedBox(height: 16),
                ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok), // Utilisation de l10n.ok comme bouton de fermeture
          ),
        ],
      ),
    );
  }
}

