import 'dart:math';

/// Qualité de la géolocalisation
enum LocationQuality {
  excellent,  // < 5m
  good,       // 5-10m
  fair,       // 10-20m
  poor,       // 20-50m
  unusable,   // > 50m
}

/// États de mouvement pour l'airsoft
enum MovementState {
  unknown,
  stationary,  // Immobile
  walking,     // Marche
  running,     // Course
}

/// Position enrichie avec métadonnées
class EnhancedPosition {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final double speed;
  final double heading;
  final bool isStationary;
  final double confidence;
  final LocationQuality quality;

  const EnhancedPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.speed = 0.0,
    this.heading = 0.0,
    this.isStationary = false,
    this.confidence = 1.0,
    this.quality = LocationQuality.fair,
  });

  /// Calcule la distance vers une autre position
  double distanceTo(EnhancedPosition other) {
    const double earthRadius = 6371000; // mètres
    double lat1Rad = latitude * pi / 180;
    double lat2Rad = other.latitude * pi / 180;
    double deltaLatRad = (other.latitude - latitude) * pi / 180;
    double deltaLonRad = (other.longitude - longitude) * pi / 180;

    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
            sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Âge de la position
  Duration ageFromNow() {
    return DateTime.now().difference(timestamp);
  }

  /// Copie avec modifications
  EnhancedPosition copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? timestamp,
    double? speed,
    double? heading,
    bool? isStationary,
    double? confidence,
    LocationQuality? quality,
  }) {
    return EnhancedPosition(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      isStationary: isStationary ?? this.isStationary,
      confidence: confidence ?? this.confidence,
      quality: quality ?? this.quality,
    );
  }

  @override
  String toString() {
    return 'EnhancedPosition(lat: ${latitude.toStringAsFixed(6)}, '
        'lng: ${longitude.toStringAsFixed(6)}, '
        'accuracy: ${accuracy.toStringAsFixed(1)}m, '
        'quality: $quality)';
  }
}

/// Métriques de qualité de géolocalisation
class LocationQualityMetrics {
  final int totalPositions;
  final int filteredPositions;
  final double filteringRate;
  final double averageAccuracy;
  final double totalDistance;
  final Duration sessionDuration;
  final MovementState currentMovementState;

  const LocationQualityMetrics({
    required this.totalPositions,
    required this.filteredPositions,
    required this.filteringRate,
    required this.averageAccuracy,
    required this.totalDistance,
    required this.sessionDuration,
    required this.currentMovementState,
  });

  @override
  String toString() {
    return 'LocationQualityMetrics('
        'total: $totalPositions, '
        'filtered: $filteredPositions, '
        'rate: ${(filteringRate * 100).toStringAsFixed(1)}%, '
        'avgAccuracy: ${averageAccuracy.toStringAsFixed(1)}m)';
  }
}