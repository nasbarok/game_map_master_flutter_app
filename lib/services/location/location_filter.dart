import 'dart:math';
import 'location_models.dart';
import 'circular_buffer.dart';

/// Filtre de géolocalisation avancé
class LocationFilter {
  static const double MAX_ACCURACY_THRESHOLD = 20.0; // mètres
  static const double OUTLIER_SIGMA_THRESHOLD = 2.0;
  static const int SMOOTHING_WINDOW_SIZE = 5;

  final CircularBuffer<EnhancedPosition> _positionBuffer;

  LocationFilter() : _positionBuffer = CircularBuffer<EnhancedPosition>(SMOOTHING_WINDOW_SIZE);

  /// Filtre une position brute
  EnhancedPosition? filterPosition(EnhancedPosition rawPosition) {
    // 1. Filtrage par précision
    if (rawPosition.accuracy > MAX_ACCURACY_THRESHOLD) {
      return null; // Position trop imprécise
    }

    // 2. Détection d'outliers
    if (_positionBuffer.length >= 3) {
      if (_isOutlier(rawPosition)) {
        return null; // Position aberrante
      }
    }

    // 3. Ajout au buffer
    _positionBuffer.add(rawPosition);

    // 4. Lissage pondéré
    return _applySmoothingFilter();
  }

  /// Détecte si une position est aberrante
  bool _isOutlier(EnhancedPosition position) {
    List<EnhancedPosition> recentPositions = _positionBuffer.getAll();
    if (recentPositions.length < 2) return false;

    // Calcul des distances aux positions récentes
    List<double> distances = recentPositions
        .map((pos) => position.distanceTo(pos))
        .toList();

    // Calcul de la moyenne et écart-type
    double mean = distances.reduce((a, b) => a + b) / distances.length;
    double variance = distances
        .map((d) => (d - mean) * (d - mean))
        .reduce((a, b) => a + b) / distances.length;
    double stdDev = sqrt(variance);

    // Test sigma : si la distance moyenne dépasse 2 écarts-types
    return mean > (stdDev * OUTLIER_SIGMA_THRESHOLD + position.accuracy);
  }

  /// Applique un lissage pondéré
  EnhancedPosition _applySmoothingFilter() {
    List<EnhancedPosition> positions = _positionBuffer.getAll();
    if (positions.isEmpty) {
      throw StateError('Buffer vide');
    }

    if (positions.length == 1) {
      return _enhancePosition(positions.first);
    }

    // Calcul des poids basés sur l'accuracy et l'âge
    List<double> weights = positions.map((pos) {
      double accuracyWeight = 1.0 / (pos.accuracy + 1.0);
      double ageWeight = 1.0 / (pos.ageFromNow().inSeconds + 1.0);
      return accuracyWeight * ageWeight;
    }).toList();

    double totalWeight = weights.reduce((a, b) => a + b);

    // Moyenne pondérée des coordonnées
    double weightedLat = 0.0;
    double weightedLng = 0.0;
    double weightedAccuracy = 0.0;

    for (int i = 0; i < positions.length; i++) {
      double normalizedWeight = weights[i] / totalWeight;
      weightedLat += positions[i].latitude * normalizedWeight;
      weightedLng += positions[i].longitude * normalizedWeight;
      weightedAccuracy += positions[i].accuracy * normalizedWeight;
    }

    // Position lissée basée sur la plus récente
    EnhancedPosition latestPosition = positions.last;
    return latestPosition.copyWith(
      latitude: weightedLat,
      longitude: weightedLng,
      accuracy: weightedAccuracy,
    );
  }

  /// Enrichit une position avec des métadonnées
  EnhancedPosition _enhancePosition(EnhancedPosition position) {
    LocationQuality quality = _calculateQuality(position.accuracy);
    double confidence = _calculateConfidence(position);

    return position.copyWith(
      quality: quality,
      confidence: confidence,
    );
  }

  /// Calcule la qualité basée sur l'accuracy
  LocationQuality _calculateQuality(double accuracy) {
    if (accuracy < 5.0) return LocationQuality.excellent;
    if (accuracy < 10.0) return LocationQuality.good;
    if (accuracy < 20.0) return LocationQuality.fair;
    if (accuracy < 50.0) return LocationQuality.poor;
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
    _positionBuffer.clear();
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