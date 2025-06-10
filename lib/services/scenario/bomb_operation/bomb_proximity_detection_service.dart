import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_site.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_scenario.dart';
import 'package:airsoft_game_map/services/scenario/bomb_operation/bomb_operation_service.dart';
import 'package:airsoft_game_map/utils/logger.dart';

/// Service de détection automatique de proximité avec feedback sonore
class BombProximityDetectionService {
  final BombOperationService _bombOperationService;
  final BombOperationScenario _bombOperationScenario;
  final int _gameSessionId;
  final int _userId;
  
  // État de détection
  Timer? _detectionTimer;
  BombSite? _currentNearSite;
  bool _isInActiveZone = false;
  
  // Callbacks pour les événements
  Function(BombSite site)? onEnterBombZone;
  Function(BombSite site)? onExitBombZone;
  Function(BombSite site, bool canArm, bool canDisarm)? onZoneStatusChanged;
  
  // Position actuelle
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;
  
  // États des sites (pour savoir si armé ou non)
  final Map<int, BombSiteState> _siteStates = {};

  BombProximityDetectionService({
    required BombOperationService bombOperationService,
    required BombOperationScenario bombOperationScenario,
    required int gameSessionId,
    required int userId,
  }) : _bombOperationService = bombOperationService,
       _bombOperationScenario = bombOperationScenario,
       _gameSessionId = gameSessionId,
       _userId = userId;

  /// Démarre la détection automatique de proximité
  void startDetection() {
    stopDetection(); // Arrêter toute détection existante
    
    _detectionTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkProximity();
    });
    
    logger.d('🔍 [BombProximityDetection] Détection démarrée');
  }

  /// Arrête la détection de proximité
  void stopDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = null;
    
    // Si on était dans une zone, déclencher la sortie
    if (_isInActiveZone && _currentNearSite != null) {
      _handleExitZone(_currentNearSite!);
    }
    
    logger.d('🔍 [BombProximityDetection] Détection arrêtée');
  }

  /// Met à jour la position actuelle
  void updatePosition(double latitude, double longitude) {
    _currentLatitude = latitude;
    _currentLongitude = longitude;
  }

  /// Met à jour l'état d'un site de bombe
  void updateSiteState(int siteId, BombSiteState state) {
    _siteStates[siteId] = state;
    
    // Si c'est le site actuel, vérifier les actions possibles
    if (_currentNearSite?.id == siteId && _isInActiveZone) {
      _checkAvailableActions(_currentNearSite!);
    }
  }

  /// Vérifie la proximité avec les sites de bombe
  Future<void> _checkProximity() async {
    try {
      final nearSite = await _bombOperationService.checkPlayerInActiveBombSite(gameSessionId: _gameSessionId, latitude: _currentLatitude, longitude: _currentLongitude);

      // Vérifier si on a changé de zone
      if (nearSite?.id != _currentNearSite?.id) {
        // Sortie de l'ancienne zone
        if (_isInActiveZone && _currentNearSite != null) {
          _handleExitZone(_currentNearSite!);
        }
        
        // Entrée dans une nouvelle zone
        if (nearSite != null) {
          _handleEnterZone(nearSite);
        }
      }
      
    } catch (e) {
      logger.d('❌ [BombProximityDetection] Erreur lors de la vérification: $e');
    }
  }

  /// Gère l'entrée dans une zone de bombe
  void _handleEnterZone(BombSite site) {
    _currentNearSite = site;
    _isInActiveZone = true;
    
    // Bip d'entrée dans la zone
    _playEnterZoneSound();
    
    // Vérifier les actions possibles
    _checkAvailableActions(site);
    
    // Notifier l'entrée dans la zone
    onEnterBombZone?.call(site);
    
    logger.d('🎯 [BombProximityDetection] Entrée dans la zone: ${site.name}');
  }

  /// Gère la sortie d'une zone de bombe
  void _handleExitZone(BombSite site) {
    _isInActiveZone = false;
    
    // Bip de sortie de zone
    _playExitZoneSound();
    
    // Notifier la sortie de zone
    onExitBombZone?.call(site);
    
    logger.d('🚶 [BombProximityDetection] Sortie de la zone: ${site.name}');
    
    _currentNearSite = null;
  }

  /// Vérifie les actions possibles sur le site actuel
  void _checkAvailableActions(BombSite site) {
    if (site.id == null) return;
    
    final siteState = _siteStates[site.id!] ?? BombSiteState.idle;
    
    // Déterminer les actions possibles
    final canArm = siteState == BombSiteState.idle;
    final canDisarm = siteState == BombSiteState.armed;
    
    // Notifier les actions disponibles
    onZoneStatusChanged?.call(site, canArm, canDisarm);
    
    logger.d('⚙️ [BombProximityDetection] Actions sur ${site.name}: arm=$canArm, disarm=$canDisarm');
  }

  /// Joue le son d'entrée dans une zone
  void _playEnterZoneSound() {
    try {
      // Bip court et aigu pour l'entrée
      HapticFeedback.lightImpact();
      // TODO: Ajouter un vrai son avec audioplayers
      logger.d('🔊 [BombProximityDetection] Bip d\'entrée de zone');
    } catch (e) {
      logger.d('❌ [BombProximityDetection] Erreur son entrée: $e');
    }
  }

  /// Joue le son de sortie d'une zone
  void _playExitZoneSound() {
    try {
      // Bip plus grave pour la sortie
      HapticFeedback.mediumImpact();
      // TODO: Ajouter un vrai son avec audioplayers
      logger.d('🔊 [BombProximityDetection] Bip de sortie de zone');
    } catch (e) {
      logger.d('❌ [BombProximityDetection] Erreur son sortie: $e');
    }
  }

  /// Joue un bip de progression pendant l'armement/désarmement
  void playProgressSound() {
    try {
      HapticFeedback.selectionClick();
      // TODO: Ajouter un son de progression
      logger.d('🔊 [BombProximityDetection] Bip de progression');
    } catch (e) {
      logger.d('❌ [BombProximityDetection] Erreur son progression: $e');
    }
  }

  /// Joue le bip final de confirmation
  void playCompletionSound(bool isSuccess) {
    try {
      if (isSuccess) {
        // Bip de succès (plus long et satisfaisant)
        HapticFeedback.heavyImpact();
      } else {
        // Bip d'échec (vibration d'erreur)
        HapticFeedback.vibrate();
      }
      // TODO: Ajouter des sons différents pour succès/échec
      logger.d('🔊 [BombProximityDetection] Bip de ${isSuccess ? 'succès' : 'échec'}');
    } catch (e) {
      logger.d('❌ [BombProximityDetection] Erreur son completion: $e');
    }
  }

  /// Vérifie si le joueur est actuellement dans une zone active
  bool get isInActiveZone => _isInActiveZone;

  /// Obtient le site actuel (si dans une zone)
  BombSite? get currentSite => _currentNearSite;

  /// Vérifie si une action spécifique est possible
  bool canPerformAction(BombActionType action) {
    if (!_isInActiveZone || _currentNearSite?.id == null) return false;
    
    final siteState = _siteStates[_currentNearSite!.id!] ?? BombSiteState.idle;
    
    switch (action) {
      case BombActionType.arm:
        return siteState == BombSiteState.idle;
      case BombActionType.disarm:
        return siteState == BombSiteState.armed;
    }
  }

  /// Nettoie les ressources
  void dispose() {
    stopDetection();
    logger.d('🧹 [BombProximityDetection] Service nettoyé');
  }
}

/// États possibles d'un site de bombe
enum BombSiteState {
  idle,      // Inactif, peut être armé
  armed,     // Armé, peut être désarmé ou va exploser
  disarmed,  // Désarmé, inactif
  exploded   // Explosé, inactif
}

/// Types d'actions possibles sur une bombe
enum BombActionType {
  arm,    // Armer la bombe
  disarm  // Désarmer la bombe
}

