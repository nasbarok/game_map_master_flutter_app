import 'dart:async';
import 'package:game_map_master_flutter_app/models/coordinate.dart';
import 'package:game_map_master_flutter_app/models/player_position.dart';
import 'package:game_map_master_flutter_app/models/game_session_position_history.dart';
import 'package:game_map_master_flutter_app/services/api_service.dart';
import 'package:game_map_master_flutter_app/services/team_service.dart';
import 'package:game_map_master_flutter_app/services/websocket_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

/// Service pour gérer la géolocalisation des joueurs
class PlayerLocationService {
  final ApiService _apiService;
  final WebSocketService _webSocketService;
  Timer? _locationUpdateTimer;

  // Dernière position connue
  double? _lastLatitude;
  double? _lastLongitude;

  // Stream pour les mises à jour de position
  final _positionStreamController = StreamController<Map<int, Coordinate>>.broadcast();
  Stream<Map<int, Coordinate>> get positionStream => _positionStreamController.stream;

  // Cache des positions actuelles des joueurs
  final Map<int, Coordinate> _currentPlayerPositions = {};
  Map<int, Coordinate> get currentPlayerPositions => Map.unmodifiable(_currentPlayerPositions);

  // Équipe du joueur actuel
  int? _currentUserTeamId;

  // ID de l'utilisateur actuel
  int? _currentUserId;
  int? _currentFieldId;

  DateTime? _lastTimestamp;
  final List<Position> _lastPositions = [];

  PlayerLocationService(this._apiService, this._webSocketService) {
    // S'abonner aux mises à jour de position via WebSocket
    _webSocketService.registerOnPlayerPositionUpdate(_handlePositionUpdate);
  }

  /// Initialise le service avec les informations de l'utilisateur actuel
  void initialize(int userId, int? teamId, int fieldId) {
    if (fieldId <= 0) {
      logger.e('❌ [PlayerLocationService] [initialize] fieldId invalide ($fieldId), abandon');
      return;
    }
    _currentUserId = userId;
    _currentUserTeamId = teamId;
    _currentFieldId = fieldId;
  }

  /// Met à jour l'équipe de l'utilisateur actuel
  void updateCurrentUserTeam(int? teamId) {
    _currentUserTeamId = teamId;
  }

  /// Démarre le partage de position
  void startLocationSharing(int gameSessionId) async {
    logger.d('🚀 [PlayerLocationService] [startLocationSharing] Démarrage du partage de position pour gameSessionId=$gameSessionId');

    // ✅ Vérifier si le service de localisation est activé
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      logger.e('📍 Service de localisation désactivé.');
      return;
    }

    // ✅ Vérifier et demander les permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        logger.e('❌ Permission de localisation refusée');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      logger.e('❌ Permission refusée définitivement');
      return;
    }

    // ✅ Continuer si les permissions sont OK
    _locationUpdateTimer?.cancel();

    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      //logger.d('📡 [PlayerLocationService] Partage de position toutes les 30 secondes pour gameSessionId=$gameSessionId');
      _shareCurrentLocation(gameSessionId);
    });

    // Envoie initial
    _shareCurrentLocation(gameSessionId);
  }

  /// Arrête le partage de position
  void stopLocationSharing() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  /// Partage la position actuelle
  Future<void> _shareCurrentLocation(int gameSessionId) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        forceAndroidLocationManager: true,
      ).timeout(const Duration(seconds: 6));

      logger.d('[GPS] ${position.latitude}, ${position.longitude}, accuracy: ${position.accuracy}, timestamp: ${position.timestamp}, isMocked: ${position.isMocked}');

      if (position.timestamp == _lastTimestamp) {
        logger.w('[GPS] Position identique (timestamp), ignorée');
        return;
      }
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

      if (_currentFieldId == null || _currentUserId == null) return;

      _webSocketService.sendPlayerPosition(
        _currentFieldId!,
        gameSessionId,
        correctedLat,
        correctedLng,
        _currentUserTeamId,
      );

      _currentPlayerPositions[_currentUserId!] = Coordinate(
        latitude: correctedLat,
        longitude: correctedLng,
      );
      _positionStreamController.add(Map.unmodifiable(_currentPlayerPositions));

    } catch (e) {
      logger.e('Erreur lors du partage de la position: $e');
    }
  }


  /// Gère les mises à jour de position reçues via WebSocket
  void _handlePositionUpdate(Map<String, dynamic> data) {
    final int userId = data['userId'];
    final double latitude = data['latitude'];
    final double longitude = data['longitude'];
    final int? teamId = data['teamId'];

    // Ne pas traiter notre propre position (déjà gérée dans _shareCurrentLocation)
    if (_currentUserId != null && userId == _currentUserId) {
      return;
    }

    // En mode jeu, filtrer les positions selon l'équipe
    // Seuls les joueurs de la même équipe sont visibles
    bool shouldShowPlayer = false;

    // Si c'est un membre de notre équipe, l'afficher
    if (_currentUserTeamId != null && teamId == _currentUserTeamId) {
      shouldShowPlayer = true;
    }

    if (shouldShowPlayer) {
      // Mettre à jour le cache des positions
      _currentPlayerPositions[userId] = Coordinate(
        latitude: latitude,
        longitude: longitude
      );
    } else {
      // Supprimer la position si le joueur ne doit plus être visible
      _currentPlayerPositions.remove(userId);
    }

    // Notifier les écouteurs
    _positionStreamController.add(Map.unmodifiable(_currentPlayerPositions));
  }

  /// Récupère l'historique des positions pour une session de jeu
  Future<GameSessionPositionHistory> getPositionHistory(int gameSessionId) async {
    try {
      final response = await _apiService.get('game-sessions/$gameSessionId/position-history');
      return GameSessionPositionHistory.fromJson(response);
    } catch (e) {
      logger.d('Erreur lors de la récupération de l\'historique des positions: $e');
      // Retourner un historique vide en cas d'erreur
      return GameSessionPositionHistory(
        gameSessionId: gameSessionId,
        playerPositions: {},
      );
    }
  }

  Future<void> loadInitialPositions(int fieldId) async {
    logger.d('🔄 [PlayerLocationService] Chargement des positions initiales pour fieldId=$fieldId');
    try {
      final response = await _apiService.get('field/$fieldId/positions');

      // Extrait les positions et les met à jour
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
      logger.d('📡 [PlayerLocationService] Positions initiales chargées : ${_currentPlayerPositions.length} joueurs');

    } catch (e) {
      logger.d('❌ [PlayerLocationService] Erreur lors du chargement des positions initiales : $e');
    }
  }

  void dispose() {
    stopLocationSharing();
    _positionStreamController.close();
  }

  void updatePlayerPosition(int userId, Coordinate coordinate) {
    _currentPlayerPositions[userId] = coordinate;
    _positionStreamController.add(Map.unmodifiable(_currentPlayerPositions));
  }
}
