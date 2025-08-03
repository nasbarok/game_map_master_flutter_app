import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';
import 'simple_voice_service.dart';

class BombTerroristAudioManager {
  final SimpleVoiceService _voiceService;
  Timer? _countdownTimer;
  bool _isCountdownActive = false;
  String? _currentZoneName;

  BombTerroristAudioManager() : _voiceService = GetIt.I<SimpleVoiceService>();

  /// Déclenche l'audio d'entrée en zone pour terroriste
  Future<void> playZoneEnteredAudio(
      String zoneName, int armingTimeSeconds) async {
    try {
      _currentZoneName = zoneName;

      // Message d'entrée en zone
      await _voiceService
          .playMessage('bombZoneEntered', parameters: {'zoneName': zoneName});

      // Attendre un peu puis annoncer le temps
      await Future.delayed(Duration(milliseconds: 1500));

      await _voiceService.playMessage('bombArmingTimeRemaining',
          parameters: {'seconds': armingTimeSeconds.toString()});

      // Attendre un peu puis instruction
      await Future.delayed(Duration(milliseconds: 1500));

      await _voiceService.playMessage('bombStayInZone');

      logger.d('🔊 Audio entrée zone terroriste joué: $zoneName');
    } catch (e) {
      logger.e('❌ Erreur audio entrée zone terroriste: $e');
    }
  }

  /// Démarre le compte à rebours audio
  void startCountdown(int totalSeconds) {
    stopCountdown();
    _isCountdownActive = true;
    _scheduleCountdownAnnouncements(totalSeconds);
    logger.d('🔊 Compte à rebours audio démarré: ${totalSeconds}s');
  }

  /// Programme les annonces de compte à rebours
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

  /// Joue le numéro du compte à rebours
  Future<void> _playCountdownNumber(int seconds) async {
    try {
      String messageKey = 'bombCountdown$seconds';
      await _voiceService.playMessage(messageKey);
      logger.d('🔊 Compte à rebours: $seconds');
    } catch (e) {
      logger.e('❌ Erreur audio compte à rebours: $e');
    }
  }

  /// Joue l'audio de bombe armée
  Future<void> playBombArmedAudio(String zoneName) async {
    try {
      stopCountdown();
      await _voiceService
          .playMessage('bombArmed', parameters: {'zoneName': zoneName});
      logger.d('🔊 Audio bombe armée joué: $zoneName');
    } catch (e) {
      logger.e('❌ Erreur audio bombe armée: $e');
    }
  }

  /// Joue l'audio de sortie de zone
  Future<void> playZoneExitedAudio(String zoneName) async {
    try {
      stopCountdown(); // Arrêter le compte à rebours
      await _voiceService
          .playMessage('bombZoneExited', parameters: {'zoneName': zoneName});
      logger.d('🔊 Audio sortie de zone joué: $zoneName');
    } catch (e) {
      logger.e('❌ Erreur audio sortie de zone: $e');
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
