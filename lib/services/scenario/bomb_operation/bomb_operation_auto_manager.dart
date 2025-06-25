import 'dart:async';
import 'package:flutter/material.dart';
import 'package:game_map_master_flutter_app/models/scenario/bomb_operation/bomb_site.dart';
import 'package:game_map_master_flutter_app/models/scenario/bomb_operation/bomb_operation_scenario.dart';
import 'package:game_map_master_flutter_app/services/scenario/bomb_operation/bomb_operation_service.dart';
import 'package:game_map_master_flutter_app/services/scenario/bomb_operation/bomb_proximity_detection_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

import '../../../models/websocket/bomb_defused_message.dart';
import '../../../models/websocket/bomb_exploded_message.dart';
import '../../../models/websocket/bomb_planted_message.dart';
import '../../../screens/scenario/bomb_operation/bomb_action_dialog.dart';

/// Gestionnaire automatique pour les actions de bombe
/// Gère la détection, les dialogs automatiques et les notifications
class BombOperationAutoManager {
  final BombOperationScenario _bombOperationScenario;
  final BombOperationService _bombOperationService;
  final int _gameSessionId;
  final int _fieldId;
  final int _userId;
  final BuildContext _context;

  late BombProximityDetectionService _proximityService;

  // État actuel
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;
  bool _isDialogOpen = false;

  // Sites de bombe actifs
  List<BombSite> _activeBombSites = [];

  // Callbacks pour l'interface utilisateur
  Function(String message, {bool isSuccess})? onStatusUpdate;
  Function(BombSite site, String action, String playerName)? onBombEvent;

  BombOperationAutoManager({
    required BombOperationScenario bombOperationScenario,
    required BombOperationService bombOperationService,
    required int gameSessionId,
    required int fieldId,
    required int userId,
    required BuildContext context,
  })  : _bombOperationScenario = bombOperationScenario,
        _bombOperationService = bombOperationService,
        _gameSessionId = gameSessionId,
        _fieldId = fieldId,
        _userId = userId,
        _context = context {
    _initializeServices();
  }

  /// Initialise les services
  void _initializeServices() {
    // Service de détection de proximité
    _proximityService = BombProximityDetectionService(
      bombOperationService: _bombOperationService,
      bombOperationScenario: _bombOperationScenario,
      gameSessionId: _gameSessionId,
      userId: _userId,
    );

    // Configuration des callbacks de proximité
    _proximityService.onEnterBombZone = _handleEnterBombZone;
    _proximityService.onExitBombZone = _handleExitBombZone;
    _proximityService.onZoneStatusChanged = _handleZoneStatusChanged;

    logger.d('🎮 [BombOperationAutoManager] Services initialisés');
  }

  /// Démarre la gestion automatique
  Future<void> start({
    required List<BombSite> activeBombSites,
  }) async {
    _activeBombSites = activeBombSites;

    // Démarrer la détection de proximité
    _proximityService.startDetection();

    logger.d('🎮 [BombOperationAutoManager] Gestion automatique démarrée');
  }

  /// Arrête la gestion automatique
  Future<void> stop() async {
    _proximityService.stopDetection();

    logger.d('🎮 [BombOperationAutoManager] Gestion automatique arrêtée');
  }

  /// Met à jour la position du joueur
  void updatePlayerPosition(double latitude, double longitude) {
    _currentLatitude = latitude;
    _currentLongitude = longitude;
    _proximityService.updatePosition(latitude, longitude);
  }

  /// Gère l'entrée dans une zone de bombe
  void _handleEnterBombZone(BombSite site) {
    onStatusUpdate?.call('Zone détectée: ${site.name}', isSuccess: true);
    logger.d('🎯 [BombOperationAutoManager] Entrée zone: ${site.name}');
  }

  /// Gère la sortie d'une zone de bombe
  void _handleExitBombZone(BombSite site) {
    // Si un dialog est ouvert, le fermer
    if (_isDialogOpen) {
      Navigator.of(_context).pop(false);
      _isDialogOpen = false;
      onStatusUpdate?.call('Action annulée - sortie de zone', isSuccess: false);
    }

    onStatusUpdate?.call('Sortie de zone: ${site.name}', isSuccess: false);
    logger.d('🚶 [BombOperationAutoManager] Sortie zone: ${site.name}');
  }

  /// Gère les changements de statut de zone
  void _handleZoneStatusChanged(BombSite site, bool canArm, bool canDisarm) {
    if (_isDialogOpen) return; // Éviter les dialogs multiples

    // Déterminer l'action automatique à effectuer
    BombActionType? actionType;
    int duration = 15; // Durée par défaut

    if (canArm) {
      actionType = BombActionType.arm;
      duration = _bombOperationScenario.armingTime;
      onStatusUpdate?.call('Armement possible sur ${site.name}',
          isSuccess: true);
    } else if (canDisarm) {
      actionType = BombActionType.disarm;
      duration = _bombOperationScenario.defuseTime;
      onStatusUpdate?.call('Désarmement possible sur ${site.name}',
          isSuccess: true);
    }

    // Lancer automatiquement le dialog d'action
    if (actionType != null) {
      _showAutomaticActionDialog(site, actionType, duration);
    }

    logger.d(
        '⚙️ [BombOperationAutoManager] Zone ${site.name}: arm=$canArm, disarm=$canDisarm');
  }

  /// Affiche automatiquement le dialog d'action
  Future<void> _showAutomaticActionDialog(
    BombSite site,
    BombActionType actionType,
    int duration,
  ) async {
    if (_isDialogOpen) return;

    _isDialogOpen = true;

    try {
      final result = await showBombActionDialog(
        context: _context,
        bombSite: site,
        actionType: actionType,
        duration: duration,
        bombOperationService: _bombOperationService,
        proximityService: _proximityService,
        gameSessionId: _gameSessionId,
        fieldId: _fieldId,
        userId: _userId,
        latitude: _currentLatitude,
        longitude: _currentLongitude,
      );

      _isDialogOpen = false;

      if (result == true) {
        final actionName =
            actionType == BombActionType.arm ? 'armée' : 'désarmée';
        onStatusUpdate?.call('Bombe $actionName avec succès!', isSuccess: true);
      } else {
        onStatusUpdate?.call('Action annulée ou échouée', isSuccess: false);
      }
    } catch (e) {
      _isDialogOpen = false;
      onStatusUpdate?.call('Erreur lors de l\'action: $e', isSuccess: false);
      logger.d('❌ [BombOperationAutoManager] Erreur dialog: $e');
    }
  }

  /// Gère les notifications de bombe plantée
  void _handleBombPlantedNotification(BombPlantedMessage message) {
    onBombEvent?.call(
      _findSiteById(message.siteId),
      'plantée',
      message.playerName!,
    );

    onStatusUpdate?.call(
      '💣 ${message.playerName} a planté une bombe sur ${message.siteName}',
      isSuccess: false,
    );

    logger.d(
        '💣 [BombOperationAutoManager] Notification: bombe plantée par ${message.playerName}');
  }

  /// Gère les notifications de bombe désarmée
  void _handleBombDefusedNotification(BombDefusedMessage message) {
    onBombEvent?.call(
      _findSiteById(message.siteId),
      'désarmée',
      message.playerName!,
    );

    onStatusUpdate?.call(
      '✅ ${message.playerName} a désarmé la bombe sur ${message.siteName}',
      isSuccess: true,
    );

    logger.d(
        '✅ [BombOperationAutoManager] Notification: bombe désarmée par ${message.playerName}');
  }

  /// Gère les notifications de bombe explosée
  void _handleBombExplodedNotification(BombExplodedMessage message) {
    onBombEvent?.call(
      _findSiteById(message.siteId),
      'explosée',
      'Timer',
    );

    onStatusUpdate?.call(
      '💥 La bombe sur ${message.siteName} a explosé!',
      isSuccess: false,
    );

    logger.d('💥 [BombOperationAutoManager] Notification: bombe explosée');
  }

  /// Trouve un site par son ID
  BombSite _findSiteById(int siteId) {
    try {
      return _activeBombSites.firstWhere((site) => site.id == siteId);
    } catch (e) {
      // Retourner un site par défaut si non trouvé
      return BombSite(
        id: siteId,
        name: 'Site #$siteId',
        latitude: 0.0,
        longitude: 0.0,
        radius: 10.0,
        scenarioId: 0,
        bombOperationScenarioId: 0,
      );
    }
  }


  /// Vérifie si dans une zone active
  bool get isInActiveZone => _proximityService.isInActiveZone;

  /// Obtient le site actuel
  BombSite? get currentSite => _proximityService.currentSite;

  /// Nettoie les ressources
  void dispose() {
    stop();
    _proximityService.dispose();
    logger.d('🧹 [BombOperationAutoManager] Gestionnaire nettoyé');
  }
}
