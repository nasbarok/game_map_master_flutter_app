import 'dart:math';
import 'location_models.dart';

/// Détecteur de mouvement pour l'airsoft
class MovementDetector {
  // Seuils adaptés pour l'airsoft
  static const double STATIONARY_DISTANCE_THRESHOLD = 1.5; // mètres
  static const Duration STATIONARY_TIME_THRESHOLD = Duration(seconds: 10);
  static const double TACTICAL_WALKING_SPEED_THRESHOLD = 0.3; // m/s (~1 km/h)
  static const double WALKING_SPEED_THRESHOLD = 0.8; // m/s (~3 km/h)
  static const double RUNNING_SPEED_THRESHOLD = 2.5; // m/s (~9 km/h)
  static const double MAX_REALISTIC_SPEED = 6.0; // m/s (~22 km/h)

  /// Détecte l'état de mouvement
  MovementState detectMovement(List<EnhancedPosition> positions) {
    if (positions.length < 2) return MovementState.unknown;

    double totalDistance = 0;
    for (int i = 1; i < positions.length; i++) {
      totalDistance += positions[i].distanceTo(positions[i-1]);
    }

    Duration timeSpan = positions.last.timestamp.difference(positions.first.timestamp);
    if (timeSpan.inSeconds == 0) return MovementState.unknown;

    // Détection d'immobilité
    if (totalDistance < STATIONARY_DISTANCE_THRESHOLD &&
        timeSpan > STATIONARY_TIME_THRESHOLD) {
      return MovementState.stationary;
    }

    // Calcul vitesse moyenne
    double averageSpeed = totalDistance / timeSpan.inSeconds;

    // Filtrage vitesses irréalistes
    if (averageSpeed > MAX_REALISTIC_SPEED) {
      return MovementState.stationary; // Probablement une erreur GPS
    }

    // Classification par vitesse
    if (averageSpeed < TACTICAL_WALKING_SPEED_THRESHOLD) {
      return MovementState.stationary;
    } else if (averageSpeed < RUNNING_SPEED_THRESHOLD) {
      return MovementState.walking;
    } else {
      return MovementState.running;
    }
  }

  /// Détermine si l'utilisateur est stationnaire
  bool isStationary(List<EnhancedPosition> positions) {
    return detectMovement(positions) == MovementState.stationary;
  }

  /// Détermine si le mouvement est tactique
  bool isTacticalMovement(List<EnhancedPosition> positions) {
    if (positions.length < 3) return false;

    double totalDistance = 0;
    for (int i = 1; i < positions.length; i++) {
      totalDistance += positions[i].distanceTo(positions[i-1]);
    }

    Duration timeSpan = positions.last.timestamp.difference(positions.first.timestamp);
    if (timeSpan.inSeconds == 0) return false;

    double averageSpeed = totalDistance / timeSpan.inSeconds;

    return averageSpeed >= TACTICAL_WALKING_SPEED_THRESHOLD &&
        averageSpeed <= WALKING_SPEED_THRESHOLD;
  }

  /// Obtient l'icône de mouvement
  String getMovementIcon(MovementState state, {bool isTactical = false}) {
    switch (state) {
      case MovementState.stationary:
        return '🛑';
      case MovementState.walking:
        return isTactical ? '🥷' : '🚶';
      case MovementState.running:
        return '🏃';
      case MovementState.unknown:
        return '❓';
    }
  }

  /// Obtient la description du mouvement
  String getMovementDescription(MovementState state, {bool isTactical = false}) {
    switch (state) {
      case MovementState.stationary:
        return 'Immobile';
      case MovementState.walking:
        return isTactical ? 'Marche tactique' : 'Marche';
      case MovementState.running:
        return 'Course';
      case MovementState.unknown:
        return 'Indéterminé';
    }
  }
}