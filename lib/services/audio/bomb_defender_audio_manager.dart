import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';
import 'simple_voice_service.dart';

class BombDefenderAudioManager {
  final SimpleVoiceService _voiceService;
  Timer? _countdownTimer;
  bool _isCountdownActive = false;
  String? _currentZoneName;

  BombDefenderAudioManager() : _voiceService = GetIt.I<SimpleVoiceService>();

  /// Joue l'alerte de bombe active (quand une bombe est armée)
  Future<void> playBombActiveAlert(String zoneName) async {
    try {
      await _voiceService
          .playMessage('bombActiveAlert', parameters: {'zoneName': zoneName});
      logger.d('🔊 Audio alerte bombe active joué: $zoneName');
    } catch (e) {
      logger.e('❌ Erreur audio alerte bombe active: $e');
    }
  }

  /// Déclenche l'audio d'entrée en zone pour défenseur
  Future<void> playDefuseZoneEnteredAudio(
      String zoneName, int defuseTimeSeconds) async {
    try {
      _currentZoneName = zoneName;

      // Message d'entrée en zone
      await _voiceService
          .playMessage('defuseZoneEntered', parameters: {'zoneName': zoneName});

      // Attendre un peu puis annoncer le temps
      await Future.delayed(Duration(milliseconds: 1500));

      await _voiceService.playMessage('defuseTimeRemaining',
          parameters: {'seconds': defuseTimeSeconds.toString()});

      // Attendre un peu puis instruction
      await Future.delayed(Duration(milliseconds: 1500));

      await _voiceService.playMessage('defuseStayInZone');

      logger.d('🔊 Audio entrée zone défenseur joué: $zoneName');
    } catch (e) {
      logger.e('❌ Erreur audio entrée zone défenseur: $e');
    }
  }

  /// Démarre le compte à rebours audio pour le désamorçage
  void startDefuseCountdown(int totalSeconds) {
    stopCountdown();
    _isCountdownActive = true;
    _scheduleCountdownAnnouncements(totalSeconds);
    logger.d('🔊 Compte à rebours désamorçage démarré: ${totalSeconds}s');
  }

  /// Programme les annonces de compte à rebours (même système que terroristes)
  void _scheduleCountdownAnnouncements(int totalSeconds) {
    List<int> announceTimes = [];

    // Ajouter 30s, 20s, 10s si le temps le permet
    if (totalSeconds >= 30) announceTimes.add(totalSeconds - 30);
    if (totalSeconds >= 20) announceTimes.add(totalSeconds - 20);
    if (totalSeconds >= 10) announceTimes.add(totalSeconds - 10);

    // Ajouter les 9 dernières secondes
    for (int i = 9; i >= 1; i--) {
      if (totalSeconds >= i) announceTimes.add(totalSeconds - i);
    }

    // Programmer chaque annonce
    for (int announceTime in announceTimes) {
      Timer(Duration(seconds: announceTime), () {
        if (_isCountdownActive) {
          int remainingSeconds = totalSeconds - announceTime;
          _playCountdownNumber(remainingSeconds);
        }
      });
    }
  }

  /// Joue le numéro du compte à rebours (réutilise les mêmes clés que terroristes)
  Future<void> _playCountdownNumber(int seconds) async {
    try {
      String messageKey = 'bombCountdown$seconds';
      await _voiceService.playMessage(messageKey);
      logger.d('🔊 Compte à rebours désamorçage: $seconds');
    } catch (e) {
      logger.e('❌ Erreur audio compte à rebours désamorçage: $e');
    }
  }

  /// Joue l'audio de bombe désarmée
  Future<void> playBombDefusedAudio(String zoneName) async {
    try {
      stopCountdown();
      await _voiceService
          .playMessage('bombDefused', parameters: {'zoneName': zoneName});
      logger.d('🔊 Audio bombe désarmée joué: $zoneName');
    } catch (e) {
      logger.e('❌ Erreur audio bombe désarmée: $e');
    }
  }

  /// Joue l'audio de sortie de zone pour défenseur
  Future<void> playDefuseZoneExitedAudio(String zoneName) async {
    try {
      stopCountdown(); // Arrêter le compte à rebours
      await _voiceService
          .playMessage('defuseZoneExited', parameters: {'zoneName': zoneName});
      logger.d('🔊 Audio sortie zone défenseur joué: $zoneName');
    } catch (e) {
      logger.e('❌ Erreur audio sortie zone défenseur: $e');
    }
  }

  /// Joue l'audio d'explosion
  Future<void> playBombExplodedAudio(String zoneName) async {
    try {
      stopCountdown(); // Arrêter tout compte à rebours
      await _voiceService
          .playMessage('bombExploded', parameters: {'zoneName': zoneName});
      logger.d('🔊 Audio explosion joué: $zoneName');
    } catch (e) {
      logger.e('❌ Erreur audio explosion: $e');
    }
  }

  /// Arrête le compte à rebours
  void stopCountdown() {
    _isCountdownActive = false;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void dispose() {
    stopCountdown();
  }
}

