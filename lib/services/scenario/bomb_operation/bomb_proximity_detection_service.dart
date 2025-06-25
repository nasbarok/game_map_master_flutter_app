import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:game_map_master_flutter_app/models/scenario/bomb_operation/bomb_site.dart';
import 'package:game_map_master_flutter_app/models/scenario/bomb_operation/bomb_operation_scenario.dart';
import 'package:game_map_master_flutter_app/services/scenario/bomb_operation/bomb_operation_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

import '../../../models/scenario/bomb_operation/bomb_operation_team.dart';

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

  /// ✨ Déplace un site vers la liste des sites explosés
  void moveSiteToExploded(int siteId) {
    // Mettre à jour l'état local
    updateSiteState(siteId, BombSiteState.exploded);

    // Notifier le service principal pour qu'il mette à jour ses listes
    // (Cette méthode sera appelée par le WebSocket handler)
    logger.d('💥 [BombProximityDetection] Site $siteId déplacé vers explosés');
  }

  /// Vérifie la proximité avec les sites de bombe
  Future<void> _checkProximity() async {
    try {
      final roleBombOperation = _bombOperationService.getPlayerRoleBombOperation(_userId);
      if (roleBombOperation == null) {
        logger.d('⚠️ [BombProximityDetection] Rôle non défini pour userId=$_userId');
        return;
      }

      BombSite? nearSite;

      if (roleBombOperation == BombOperationTeam.attack) {
        nearSite = await _bombOperationService.checkPlayerInToActiveBombSite(
          gameSessionId: _gameSessionId,
          latitude: _currentLatitude,
          longitude: _currentLongitude,
        );
      } else if (roleBombOperation == BombOperationTeam.defense) {
        nearSite = await _bombOperationService.checkPlayerInActiveBombSite(
          gameSessionId: _gameSessionId,
          latitude: _currentLatitude,
          longitude: _currentLongitude,
        );
      }

      // Vérifier si on a changé de zone
      if (nearSite?.id != _currentNearSite?.id) {
        if (_isInActiveZone && _currentNearSite != null) {
          _handleExitZone(_currentNearSite!);
        }

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
    final role = _bombOperationService.getPlayerRoleBombOperation(_userId);
    final roleStr = role != null ? role.toString().split('.').last : 'inconnu';

    logger.d('📥 [BombProximityDetection] Vérification actions possibles pour ${site.name}');
    logger.d('🔹 → rôle joueur=$_userId → $roleStr');

    bool canArm = false;
    bool canDisarm = false;

    if (role == BombOperationTeam.attack &&
        _bombOperationService.toActivateBombSites.any((s) => s.id == site.id)) {
      canArm = true;
      logger.d('✅ [BombProximityDetection] Le site ${site.name} est dans toActivateBombSites → arm=true');
    } else if (role == BombOperationTeam.defense &&
        _bombOperationService.activeBombSites.any((s) => s.id == site.id)) {
      canDisarm = true;
      logger.d('✅ [BombProximityDetection] Le site ${site.name} est dans activeBombSites → disarm=true');
    } else {
      logger.d('🚫 [BombProximityDetection] Aucune action possible sur ${site.name} pour le rôle $roleStr');
    }

    onZoneStatusChanged?.call(site, canArm, canDisarm);
    logger.d('✅ [BombProximityDetection] Actions possibles sur ${site.name} → arm=$canArm | disarm=$canDisarm');
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

