import 'dart:async';
import 'package:airsoft_game_map/models/coordinate.dart';
import 'package:airsoft_game_map/models/player_position.dart';
import 'package:airsoft_game_map/models/game_session_position_history.dart';
import 'package:airsoft_game_map/services/api_service.dart';
import 'package:airsoft_game_map/services/websocket_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';

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

  PlayerLocationService(this._apiService, this._webSocketService) {
    // S'abonner aux mises à jour de position via WebSocket
    _webSocketService.registerOnPlayerPositionUpdate(_handlePositionUpdate);
  }

  /// Initialise le service avec les informations de l'utilisateur actuel
  void initialize(int userId, int? teamId) {
    _currentUserId = userId;
    _currentUserTeamId = teamId;
  }
  
  /// Met à jour l'équipe de l'utilisateur actuel
  void updateCurrentUserTeam(int? teamId) {
    _currentUserTeamId = teamId;
  }

  /// Démarre le partage de position
  void startLocationSharing(int gameSessionId) async {
    print('🚀 [PlayerLocationService] [startLocationSharing] Démarrage du partage de position pour gameSessionId=$gameSessionId');

    // ✅ Vérifier si le service de localisation est activé
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('📍 Service de localisation désactivé.');
      return;
    }

    // ✅ Vérifier et demander les permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ Permission de localisation refusée');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Permission refusée définitivement');
      return;
    }

    // ✅ Continuer si les permissions sont OK
    _locationUpdateTimer?.cancel();

    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
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
      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      // Vérifier si la position a changé significativement
      if (_lastLatitude == null || _lastLongitude == null ||
          (_lastLatitude != position.latitude || _lastLongitude != position.longitude)) {
        
        _lastLatitude = position.latitude;
        _lastLongitude = position.longitude;
        
        // Envoyer la position au serveur via WebSocket
        _webSocketService.sendPlayerPosition(
          gameSessionId, 
          position.latitude, 
          position.longitude,
          _currentUserTeamId
        );
        
        // Mettre à jour notre propre position dans le cache
        if (_currentUserId != null) {
          _currentPlayerPositions[_currentUserId!] = Coordinate(
            latitude: position.latitude,
            longitude: position.longitude
          );
          
          // Notifier les écouteurs
          _positionStreamController.add(Map.unmodifiable(_currentPlayerPositions));
        }
      }
    } catch (e) {
      print('Erreur lors du partage de la position: $e');
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
      print('Erreur lors de la récupération de l\'historique des positions: $e');
      // Retourner un historique vide en cas d'erreur
      return GameSessionPositionHistory(
        gameSessionId: gameSessionId,
        playerPositions: {},
      );
    }
  }
  
  void dispose() {
    stopLocationSharing();
    _positionStreamController.close();
  }
}
