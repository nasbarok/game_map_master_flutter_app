import 'dart:async';
import 'package:game_map_master_flutter_app/models/coordinate.dart';
import 'package:game_map_master_flutter_app/models/player_position.dart';
import 'package:game_map_master_flutter_app/models/game_session_position_history.dart';
import 'package:game_map_master_flutter_app/services/api_service.dart';
import 'package:game_map_master_flutter_app/services/team_service.dart';
import 'package:game_map_master_flutter_app/services/websocket_service.dart';
import 'package:get_it/get_it.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

import 'location/location_models.dart';
import 'location/advanced_location_service.dart';

/// Service pour gérer la géolocalisation des joueurs
class PlayerLocationService {
  final ApiService _apiService;
  final WebSocketService _webSocketService;

  // Position en cache
  double? _lastLatitude;
  double? _lastLongitude;
  DateTime? _lastTimestamp;

  // Flux des positions partagées
  final _positionStreamController = StreamController<Map<int, Coordinate>>.broadcast();
  Stream<Map<int, Coordinate>> get positionStream => _positionStreamController.stream;

  final Map<int, Coordinate> _currentPlayerPositions = {};
  Map<int, Coordinate> get currentPlayerPositions => Map.unmodifiable(_currentPlayerPositions);

  int? _currentUserTeamId;
  int? _currentUserId;
  int? _currentFieldId;
  int? _currentGameSessionId;

  StreamSubscription<EnhancedPosition>? _advancedLocationSubscription;
  final AdvancedLocationService _advancedLocationService;

  PlayerLocationService(this._apiService, this._webSocketService,
      this._advancedLocationService) {
    _webSocketService.registerOnPlayerPositionUpdate(_handlePositionUpdate);
  }
  AdvancedLocationService get advancedLocationService => _advancedLocationService;

  void initialize(int userId, int? teamId, int fieldId) {
    if (fieldId <= 0) {
      logger.e('❌ [PlayerLocationService] [initialize] fieldId invalide ($fieldId), abandon');
      return;
    }
    _currentUserId = userId;
    _currentUserTeamId = teamId;
    _currentFieldId = fieldId;
  }

  void updateCurrentUserTeam(int? teamId) {
    _currentUserTeamId = teamId;
  }

  Future<void> startLocationTracking(int gameSessionId) async {
    try {
      final advancedLocationService = GetIt.instance<AdvancedLocationService>();
      _currentGameSessionId = gameSessionId;

      if (!advancedLocationService.isInitialized) {
        logger.i('[PlayerLocationService] Initializing AdvancedLocationService...');
        await advancedLocationService.initialize();
        logger.i('[PlayerLocationService] AdvancedLocationService initialized.');
      }

      if (!advancedLocationService.isActive) {
        logger.i('[PlayerLocationService] Starting AdvancedLocationService...');
        await advancedLocationService.start();
        logger.i('[PlayerLocationService] AdvancedLocationService started.');
      }

      _advancedLocationSubscription = advancedLocationService.positionStream.listen(
            (enhancedPosition) {
          _handleEnhancedPosition(enhancedPosition);
        },
        onError: (error) => logger.e('❌ Erreur AdvancedLocation: $error'),
      );

      logger.d('✅ [PlayerLocationService] Utilise AdvancedLocationService');
    } catch (e) {
      logger.e('❌ Erreur configuration PlayerLocationService: $e');
    }
  }

  void stopLocationTracking() {
    _advancedLocationSubscription?.cancel();
    _advancedLocationSubscription = null;
  }

  void _handleEnhancedPosition(EnhancedPosition position) {
    if (_currentFieldId == null || _currentUserId == null || _currentGameSessionId == null) return;

    if (position.timestamp == _lastTimestamp) return;
    _lastTimestamp = position.timestamp;

    if (position.accuracy > 25.0) {
      logger.w('[GPS] Précision insuffisante (${position.accuracy} m), ignorée');
      return;
    }

    const latOffset = 0.000035;
    const lngOffset = -0.000085;

    final correctedLat = position.latitude + latOffset;
    final correctedLng = position.longitude + lngOffset;

    if (_lastLatitude == correctedLat && _lastLongitude == correctedLng) return;

    _lastLatitude = correctedLat;
    _lastLongitude = correctedLng;

    shareEnhancedPosition(
      gameSessionId: _currentGameSessionId!,
      fieldId: _currentFieldId!,
      userId: _currentUserId!,
      latitude: correctedLat,
      longitude: correctedLng,
      teamId: _currentUserTeamId,
    );
  }

  void shareEnhancedPosition({
    required int gameSessionId,
    required int fieldId,
    required int userId,
    required double latitude,
    required double longitude,
    int? teamId,
  }) {
    _currentPlayerPositions[userId] = Coordinate(
      latitude: latitude,
      longitude: longitude,
    );
    _positionStreamController.add(Map.unmodifiable(_currentPlayerPositions));

    _webSocketService.sendPlayerPosition(
      fieldId,
      gameSessionId,
      latitude,
      longitude,
      teamId,
    );
  }

  void sendManualPositionUpdate({
    required int fieldId,
    required int gameSessionId,
    required int userId,
    required double lat,
    required double lng,
    int? teamId,
  }) {
    _currentPlayerPositions[userId] = Coordinate(latitude: lat, longitude: lng);
    _positionStreamController.add(Map.unmodifiable(_currentPlayerPositions));

    _webSocketService.sendPlayerPosition(fieldId, gameSessionId, lat, lng, teamId);
  }

  void _handlePositionUpdate(Map<String, dynamic> data) {
    final int userId = data['userId'];
    final double latitude = data['latitude'];
    final double longitude = data['longitude'];
    final int? teamId = data['teamId'];

    if (_currentUserId != null && userId == _currentUserId) return;

    if (_currentUserTeamId != null && teamId == _currentUserTeamId) {
      _currentPlayerPositions[userId] = Coordinate(
        latitude: latitude,
        longitude: longitude,
      );
    } else {
      _currentPlayerPositions.remove(userId);
    }

    _positionStreamController.add(Map.unmodifiable(_currentPlayerPositions));
  }

  Future<GameSessionPositionHistory> getPositionHistory(int gameSessionId) async {
    try {
      final response = await _apiService.get('game-sessions/$gameSessionId/position-history');
      return GameSessionPositionHistory.fromJson(response);
    } catch (e) {
      logger.d('Erreur récupération historique de positions : $e');
      return GameSessionPositionHistory(
        gameSessionId: gameSessionId,
        playerPositions: {},
      );
    }
  }

  Future<void> loadInitialPositions(int fieldId) async {
    logger.d('🔄 Chargement des positions initiales pour fieldId=$fieldId');
    try {
      final response = await _apiService.get('field/$fieldId/positions');
      Map<int, Coordinate> loadedPositions = {};
      response.forEach((key, value) {
        final userId = int.tryParse(key);
        if (userId != null) {
          loadedPositions[userId] = Coordinate(
            latitude: value['latitude'],
            longitude: value['longitude'],
          );
        }
      });

      _currentPlayerPositions
        ..clear()
        ..addAll(loadedPositions);

      _positionStreamController.add(Map.unmodifiable(_currentPlayerPositions));
      logger.d('📡 Positions initiales chargées : ${_currentPlayerPositions.length}');
    } catch (e) {
      logger.d('❌ Erreur chargement positions initiales : $e');
    }
  }

  void updatePlayerPosition(int userId, Coordinate coordinate) {
    _currentPlayerPositions[userId] = coordinate;
    _positionStreamController.add(Map.unmodifiable(_currentPlayerPositions));
  }

  void dispose() {
    stopLocationTracking();
    _positionStreamController.close();
  }
}
