import 'dart:async';

/// Service optimisé pour calculer dynamiquement les comptes à rebours des bombes
/// en utilisant les timestamps WebSocket et le bombTimer du scénario
class BombTimerCalculatorService {
  
  /// Calcule le temps restant avant explosion d'une bombe
  /// 
  /// [plantedTimestamp] : Timestamp de quand la bombe a été armée (depuis WebSocket)
  /// [bombTimerSeconds] : Durée du timer en secondes (depuis BombOperationScenario)
  /// 
  /// Retourne le nombre de secondes restantes, ou 0 si la bombe a explosé
  static int calculateRemainingSeconds(DateTime plantedTimestamp, int bombTimerSeconds) {
    final now = DateTime.now();
    final explosionTime = plantedTimestamp.add(Duration(seconds: bombTimerSeconds));
    final remainingDuration = explosionTime.difference(now);
    
    // Si le temps est écoulé, retourner 0
    if (remainingDuration.isNegative) {
      return 0;
    }
    
    return remainingDuration.inSeconds;
  }
  
  /// Formate le temps restant en format MM:SS
  static String formatRemainingTime(int remainingSeconds) {
    if (remainingSeconds <= 0) {
      return "00:00";
    }
    
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
  
  /// Détermine la couleur du timer selon le temps restant
  static TimerColor getTimerColor(int remainingSeconds) {
    if (remainingSeconds <= 10) {
      return TimerColor.critical; // Rouge
    } else if (remainingSeconds <= 30) {
      return TimerColor.warning; // Orange
    } else {
      return TimerColor.normal; // Couleur normale
    }
  }
  
  /// Vérifie si une bombe devrait avoir explosé
  static bool shouldHaveExploded(DateTime plantedTimestamp, int bombTimerSeconds) {
    return calculateRemainingSeconds(plantedTimestamp, bombTimerSeconds) <= 0;
  }
  
  /// Calcule le temps d'explosion prévu
  static DateTime calculateExplosionTime(DateTime plantedTimestamp, int bombTimerSeconds) {
    return plantedTimestamp.add(Duration(seconds: bombTimerSeconds));
  }
}

/// Énumération pour les couleurs du timer
enum TimerColor {
  normal,   // Couleur normale (vert/bleu)
  warning,  // Orange (< 30s)
  critical, // Rouge (< 10s)
}

/// Modèle pour représenter une bombe armée avec son timer
class ArmedBombInfo {
  final int siteId;
  final String siteName;
  final DateTime plantedTimestamp;
  final int bombTimerSeconds;
  final String? playerName;
  
  ArmedBombInfo({
    required this.siteId,
    required this.siteName,
    required this.plantedTimestamp,
    required this.bombTimerSeconds,
    this.playerName,
  });
  
  /// Calcule le temps restant pour cette bombe
  int get remainingSeconds => BombTimerCalculatorService.calculateRemainingSeconds(
    plantedTimestamp, 
    bombTimerSeconds
  );
  
  /// Formate le temps restant
  String get formattedRemainingTime => BombTimerCalculatorService.formatRemainingTime(remainingSeconds);
  
  /// Couleur du timer
  TimerColor get timerColor => BombTimerCalculatorService.getTimerColor(remainingSeconds);
  
  /// Vérifie si la bombe devrait avoir explosé
  bool get shouldHaveExploded => BombTimerCalculatorService.shouldHaveExploded(
    plantedTimestamp, 
    bombTimerSeconds
  );
  
  /// Temps d'explosion prévu
  DateTime get explosionTime => BombTimerCalculatorService.calculateExplosionTime(
    plantedTimestamp, 
    bombTimerSeconds
  );
}

