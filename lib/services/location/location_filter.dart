import 'dart:math';
import 'location_models.dart';
import 'circular_buffer.dart';

/// Filtre de géolocalisation avancé
class LocationFilter {
  static const double MAX_ACCURACY_THRESHOLD =
      22.0; // Plus strict : 15m au lieu de 20m
  static const int SMOOTHING_WINDOW_SIZE = 5; // Plus de positions pour lisser
  static const double STATIONARY_THRESHOLD =
      2.0; // Plus strict : 2m au lieu de 3m
  static const double MIN_MOVEMENT_SPEED =
      0.5; // Vitesse minimum pour considérer un mouvement (m/s)

  final CircularBuffer<EnhancedPosition> _positionBuffer;
  final List<EnhancedPosition> _recentPositions = [];
  bool _isStationary = false;
  EnhancedPosition? _stationaryCenter;
  int _stationaryCount = 0;

  LocationFilter()
      : _positionBuffer =
            CircularBuffer<EnhancedPosition>(SMOOTHING_WINDOW_SIZE);

  /// Filtre une position brute
  EnhancedPosition? filterPosition(EnhancedPosition rawPosition) {
    // 1. Filtrage par précision
    if (rawPosition.accuracy > MAX_ACCURACY_THRESHOLD) {
      return null; // Position trop imprécise
    }
    // 2. Détection d'outliers - PLUS STRICT
    if (_recentPositions.length >= 2) {
      double avgDistance = _recentPositions
              .map((pos) => rawPosition.distanceTo(pos))
              .reduce((a, b) => a + b) /
          _recentPositions.length;

      // Si la position est très éloignée des récentes, la rejeter
      if (avgDistance > rawPosition.accuracy * 2) {
        // Plus strict : x2 au lieu de x3
        return null;
      }
    }
    // 3. Gestion de l'immobilité
    _updateStationaryState(rawPosition);

    // 4. Ajout au buffer
    _recentPositions.add(rawPosition);
    if (_recentPositions.length > SMOOTHING_WINDOW_SIZE) {
      _recentPositions.removeAt(0);
    }

    // 5. Lissage adaptatif
    return _applyAdaptiveSmoothing();
  }

  /// Lissage adaptatif selon l'état
  EnhancedPosition _applyAdaptiveSmoothing() {
    if (_recentPositions.length == 1) {
      return _enhancePosition(_recentPositions.first);
    }

    if (_isStationary) {
      // Mode stationnaire : position fixe au centre
      return _createStationaryPosition();
    } else {
      // Mode mouvement : lissage normal
      return _applyMovementSmoothing();
    }
  }

  /// Lissage pour le mouvement
  EnhancedPosition _applyMovementSmoothing() {
    // Moyenne pondérée par accuracy (meilleure accuracy = plus de poids)
    double totalWeight = 0;
    double weightedLat = 0;
    double weightedLng = 0;
    double weightedAccuracy = 0;

    for (var pos in _recentPositions) {
      double weight = 1.0 / (pos.accuracy + 1.0);
      totalWeight += weight;
      weightedLat += pos.latitude * weight;
      weightedLng += pos.longitude * weight;
      weightedAccuracy += pos.accuracy * weight;
    }

    EnhancedPosition latest = _recentPositions.last;
    double smoothedSpeed = _calculateSmoothedSpeed();

    return EnhancedPosition(
      latitude: weightedLat / totalWeight,
      longitude: weightedLng / totalWeight,
      accuracy: weightedAccuracy / totalWeight,
      timestamp: latest.timestamp,
      speed: smoothedSpeed,
      isStationary: smoothedSpeed < MIN_MOVEMENT_SPEED,
      quality: _calculateQuality(weightedAccuracy / totalWeight),
    );
  }

  /// Calcule la vitesse lissée
  double _calculateSmoothedSpeed() {
    if (_recentPositions.length < 2) return 0.0;

    List<double> speeds = [];
    for (int i = 1; i < _recentPositions.length; i++) {
      double distance = _recentPositions[i].distanceTo(_recentPositions[i - 1]);
      double timeDiff = _recentPositions[i]
              .timestamp
              .difference(_recentPositions[i - 1].timestamp)
              .inMilliseconds /
          1000.0;

      if (timeDiff > 0) {
        double speed = distance / timeDiff;
        speeds.add(speed);
      }
    }

    if (speeds.isEmpty) return 0.0;

    // Moyenne des vitesses, mais si toutes sont faibles, retourner 0
    double avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
    return avgSpeed < MIN_MOVEMENT_SPEED ? 0.0 : avgSpeed;
  }

  /// Gestion intelligente de l'état stationnaire
  void _updateStationaryState(EnhancedPosition position) {
    if (_stationaryCenter == null) {
      _stationaryCenter = position;
      _stationaryCount = 1;
      _isStationary = false;
      return;
    }

    double distanceFromCenter = position.distanceTo(_stationaryCenter!);

    if (distanceFromCenter <= STATIONARY_THRESHOLD) {
      _stationaryCount++;

      // Après 3 positions dans le rayon, considérer comme stationnaire
      if (_stationaryCount >= 3) {
        _isStationary = true;
      }
    } else {
      // Réinitialiser si on sort du rayon
      _stationaryCenter = position;
      _stationaryCount = 1;
      _isStationary = false;
    }
  }

  /// Crée une position fixe pour l'état stationnaire
  EnhancedPosition _createStationaryPosition() {
    EnhancedPosition latest = _recentPositions.last;

    return EnhancedPosition(
      latitude: _stationaryCenter!.latitude,
      longitude: _stationaryCenter!.longitude,
      accuracy: _stationaryCenter!.accuracy,
      timestamp: latest.timestamp,
      speed: 0.0,
      // FORCE la vitesse à 0
      isStationary: true,
      quality: _calculateQuality(_stationaryCenter!.accuracy),
    );
  }

  /// Enrichit une position avec des métadonnées
  EnhancedPosition _enhancePosition(EnhancedPosition position) {
    return EnhancedPosition(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
      speed: 0.0,
      // Première position = immobile
      isStationary: true,
      quality: _calculateQuality(position.accuracy),
    );
  }

  /// Calcule la qualité basée sur l'accuracy
  LocationQuality _calculateQuality(double accuracy) {
    if (accuracy < 5.0) return LocationQuality.excellent;
    if (accuracy < 8.0) return LocationQuality.good;
    if (accuracy < 15.0) return LocationQuality.fair;
    if (accuracy < 25.0) return LocationQuality.poor;
    return LocationQuality.unusable;
  }

  /// Calcule la confiance dans la position
  double _calculateConfidence(EnhancedPosition position) {
    double accuracyScore = max(0.0, 1.0 - (position.accuracy / 50.0));
    double ageScore = max(0.0, 1.0 - (position.ageFromNow().inSeconds / 30.0));
    return (accuracyScore + ageScore) / 2.0;
  }

  /// Réinitialise le filtre
  void reset() {
    _recentPositions.clear();
    _isStationary = false;
    _stationaryCenter = null;
    _stationaryCount = 0;
  }

  /// Statistiques du filtre
  Map<String, dynamic> getStatistics() {
    return {
      'buffer_size': _positionBuffer.length,
      'buffer_capacity': _positionBuffer.capacity,
      'is_full': _positionBuffer.isFull,
    };
  }
}
