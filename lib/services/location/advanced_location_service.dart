import 'dart:async';
import 'dart:io';
import 'package:game_map_master_flutter_app/utils/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'location_models.dart';
import 'location_filter.dart';
import 'movement_detector.dart';
import 'circular_buffer.dart';

/// Service de géolocalisation avancée
class AdvancedLocationService {
  final LocationFilter _filter;
  final MovementDetector _movementDetector;
  final CircularBuffer<EnhancedPosition> _positionHistory;

  // Streams
  final StreamController<EnhancedPosition> _positionController;
  final StreamController<LocationQualityMetrics> _metricsController;

  // Configuration
  static const Duration UPDATE_INTERVAL = Duration(seconds: 2);
  static const double MIN_DISTANCE_FILTER = 1.0; // mètres

  // État
  bool _isInitialized = false;
  bool _isActive = false;
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _sessionStartTime;
  int _totalPositionsReceived = 0;
  int _totalPositionsFiltered = 0;
  double _totalDistanceTraveled = 0.0;

  AdvancedLocationService({
    LocationFilter? filter,
    MovementDetector? movementDetector,
  }) : _filter = filter ?? LocationFilter(),
        _movementDetector = movementDetector ?? MovementDetector(),
        _positionHistory = CircularBuffer<EnhancedPosition>(20),
        _positionController = StreamController<EnhancedPosition>.broadcast(),
        _metricsController = StreamController<LocationQualityMetrics>.broadcast();

  // Getters publics
  bool get isInitialized => _isInitialized;
  bool get isActive => _isActive;
  Stream<EnhancedPosition> get positionStream => _positionController.stream;
  Stream<LocationQualityMetrics> get metricsStream => _metricsController.stream;

  /// Initialise le service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Vérification des permissions
      await _requestPermissions();

      // Vérification du service de localisation
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Service de géolocalisation désactivé');
      }

      _isInitialized = true;
      logger.d('[AdvancedLocationService] initialisé avec succès');
    } catch (e) {
      logger.e('[AdvancedLocationService] Erreur initialisation AdvancedLocationService: $e');
      rethrow;
    }
  }

  /// Démarre le service
  Future<void> start() async {
    if (!_isInitialized) {
      throw StateError('[AdvancedLocationService] [start] Service non initialisé');
    }

    if (_isActive) return;
    logger.d('[AdvancedLocationService] [start] ✅  start');
    try {
      _sessionStartTime = DateTime.now();
      _totalPositionsReceived = 0;
      _totalPositionsFiltered = 0;
      _totalDistanceTraveled = 0.0;

      LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: MIN_DISTANCE_FILTER.toInt(),
      );

      if (Platform.isAndroid) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: MIN_DISTANCE_FILTER.toInt(),
          intervalDuration: UPDATE_INTERVAL,
        );
      } else if (Platform.isIOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: MIN_DISTANCE_FILTER.toInt(),
        );
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onPositionUpdate,
        onError: _onPositionError,
      );

      _isActive = true;
      print('AdvancedLocationService démarré');
    } catch (e) {
      print('Erreur démarrage AdvancedLocationService: $e');
      rethrow;
    }
  }

  /// Arrête le service
  Future<void> stop() async {
    if (!_isActive) return;

    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isActive = false;

    logger.d('[AdvancedLocationService] [stop] arrêté');
  }

  /// Obtient la position actuelle
  Future<EnhancedPosition?> getCurrentPosition() async {
    if (!_isInitialized) return null;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      EnhancedPosition rawPosition = _convertToEnhancedPosition(position);
      return _filter.filterPosition(rawPosition);
    } catch (e) {
      print('Erreur getCurrentPosition: $e');
      return null;
    }
  }

  /// Force la publication de la position actuelle
  void forcePublish() {
    if (!_positionHistory.isEmpty) {
      EnhancedPosition? lastPosition = _positionHistory.last;
      if (lastPosition != null) {
        _positionController.add(lastPosition);
      }
    }
  }

  /// Réinitialise le service
  void reset() {
    _filter.reset();
    _positionHistory.clear();
    _totalPositionsReceived = 0;
    _totalPositionsFiltered = 0;
    _totalDistanceTraveled = 0.0;
    _sessionStartTime = DateTime.now();
  }

  /// Traite une mise à jour de position
  void _onPositionUpdate(Position position) {
 logger.d('[AdvancedLocationService] Position updated : $position.latitude, $position.longitude (accuracy: ${position.accuracy})');
    try {
      _totalPositionsReceived++;

      EnhancedPosition rawPosition = _convertToEnhancedPosition(position);
      EnhancedPosition? filteredPosition = _filter.filterPosition(rawPosition);

      if (filteredPosition != null) {
        // Calcul de la distance parcourue
        if (!_positionHistory.isEmpty) {
          EnhancedPosition? lastPosition = _positionHistory.last;
          if (lastPosition != null) {
            _totalDistanceTraveled += filteredPosition.distanceTo(lastPosition);
          }
        }

        // Détection de mouvement
        List<EnhancedPosition> recentPositions = _positionHistory.getAll();
        recentPositions.add(filteredPosition);

        MovementState movementState = _movementDetector.detectMovement(recentPositions);
        bool isStationary = _movementDetector.isStationary(recentPositions);
        bool isTactical = _movementDetector.isTacticalMovement(recentPositions);

        // Position enrichie finale
        EnhancedPosition enhancedPosition = filteredPosition.copyWith(
          isStationary: isStationary,
        );

        // Ajout à l'historique
        _positionHistory.add(enhancedPosition);

        // Publication
        _positionController.add(enhancedPosition);

        // Métriques
        _publishMetrics(movementState);
      } else {
        _totalPositionsFiltered++;
      }
    } catch (e) {
      print('Erreur traitement position: $e');
    }
  }

  /// Gère les erreurs de position
  void _onPositionError(dynamic error) {
    print('Erreur position stream: $error');
  }

  /// Convertit Position en EnhancedPosition
  EnhancedPosition _convertToEnhancedPosition(Position position) {
    return EnhancedPosition(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp ?? DateTime.now(),
      speed: position.speed,
      heading: position.heading,
    );
  }

  /// Publie les métriques
  void _publishMetrics(MovementState movementState) {
    if (_sessionStartTime == null) return;

    Duration sessionDuration = DateTime.now().difference(_sessionStartTime!);
    double filteringRate = _totalPositionsReceived > 0
        ? _totalPositionsFiltered / _totalPositionsReceived
        : 0.0;

    // Calcul de l'accuracy moyenne
    List<EnhancedPosition> positions = _positionHistory.getAll();
    double averageAccuracy = positions.isNotEmpty
        ? positions.map((p) => p.accuracy).reduce((a, b) => a + b) / positions.length
        : 0.0;

    LocationQualityMetrics metrics = LocationQualityMetrics(
      totalPositions: _totalPositionsReceived,
      filteredPositions: _totalPositionsFiltered,
      filteringRate: filteringRate,
      averageAccuracy: averageAccuracy,
      totalDistance: _totalDistanceTraveled,
      sessionDuration: sessionDuration,
      currentMovementState: movementState,
    );

    _metricsController.add(metrics);
  }

  /// Demande les permissions
  Future<void> _requestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissions de géolocalisation refusées définitivement');
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Permissions de géolocalisation refusées');
    }
  }

  /// Obtient les statistiques
  Map<String, dynamic> getStatistics() {
    return {
      'is_initialized': _isInitialized,
      'is_active': _isActive,
      'total_positions_published': _totalPositionsReceived - _totalPositionsFiltered,
      'session_duration': _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!).inSeconds
          : 0,
      'filter_stats': _filter.getStatistics(),
    };
  }

  /// Dispose le service
  Future<void> dispose() async {
    await stop();
    await _positionController.close();
    await _metricsController.close();
  }
}