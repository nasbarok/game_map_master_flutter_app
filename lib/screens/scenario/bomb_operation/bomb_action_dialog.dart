import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_map_master_flutter_app/models/scenario/bomb_operation/bomb_site.dart';
import 'package:game_map_master_flutter_app/models/scenario/bomb_operation/bomb_operation_scenario.dart';
import 'package:game_map_master_flutter_app/services/scenario/bomb_operation/bomb_operation_service.dart';
import 'package:game_map_master_flutter_app/services/scenario/bomb_operation/bomb_proximity_detection_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

import '../../../generated/l10n/app_localizations.dart';

/// Dialog automatique pour l'armement/désarmement de bombe avec compte à rebours
class BombActionDialog extends StatefulWidget {
  final BombSite bombSite;
  final BombActionType actionType;
  final int duration; // Durée en secondes
  final BombOperationService bombOperationService;
  final BombProximityDetectionService proximityService;
  final int gameSessionId;
  final int fieldId;
  final int userId;
  final double latitude;
  final double longitude;

  const BombActionDialog({
    Key? key,
    required this.bombSite,
    required this.actionType,
    required this.duration,
    required this.bombOperationService,
    required this.proximityService,
    required this.gameSessionId,
    required this.fieldId,
    required this.userId,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<BombActionDialog> createState() => _BombActionDialogState();
}

class _BombActionDialogState extends State<BombActionDialog>
    with TickerProviderStateMixin {
  late Timer _countdownTimer;
  late AnimationController _progressController;
  late AnimationController _pulseController;

  int _timeRemaining = 0;
  bool _isCompleted = false;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.duration;

    // Contrôleur pour la barre de progression
    _progressController = AnimationController(
      duration: Duration(seconds: widget.duration),
      vsync: this,
    );

    // Contrôleur pour l'effet de pulsation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _startCountdown();
    _startProgressAnimation();
    _startPulseAnimation();
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Démarre le compte à rebours
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });

        // Bip de progression
        widget.proximityService.playProgressSound();

        // Vibration plus forte quand il reste peu de temps
        if (_timeRemaining <= 3) {
          HapticFeedback.heavyImpact();
        }
      } else {
        _completeAction();
      }
    });
  }

  /// Démarre l'animation de progression
  void _startProgressAnimation() {
    _progressController.forward();
  }

  /// Démarre l'animation de pulsation
  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  /// Finalise l'action (armement ou désarmement)
  Future<void> _completeAction() async {
    if (_isCompleted || _isCancelled) return;

    _countdownTimer.cancel();
    _isCompleted = true;

    try {
      // Bip final de succès
      widget.proximityService.playCompletionSound(true, widget.bombSite.name);

      // Envoyer la notification au serveur
      if (widget.actionType == BombActionType.arm) {
        await widget.bombOperationService.plantBomb(
            widget.fieldId, widget.gameSessionId, widget.bombSite.id!);
      } else {
        await widget.bombOperationService.defuseBomb(
            widget.fieldId, widget.gameSessionId, widget.bombSite.id!);
      }

      // Fermer le dialog avec succès
      if (mounted) {
        Navigator.of(context).pop(true);
      }

      logger.d(
          '✅ [BombActionDialog] Action ${widget.actionType.name} terminée avec succès');
    } catch (e) {
      logger.d('❌ [BombActionDialog] Erreur lors de l\'action: $e');

      // Bip d'échec
      widget.proximityService.playCompletionSound(false, widget.bombSite.name);

      // Fermer le dialog avec échec
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    }
  }

  /// Annule l'action
  void _cancelAction() {
    if (_isCompleted || _isCancelled) return;

    _countdownTimer.cancel();
    _isCancelled = true;

    // Bip d'annulation
    HapticFeedback.vibrate();

    // Fermer le dialog
    if (mounted) {
      Navigator.of(context).pop(false);
    }

    logger.d('❌ [BombActionDialog] Action ${widget.actionType.name} annulée');
  }

  /// Obtient la couleur selon le type d'action
  Color _getActionColor() {
    switch (widget.actionType) {
      case BombActionType.arm:
        return Colors.red;
      case BombActionType.disarm:
        return Colors.blue;
    }
  }

  /// Obtient l'icône selon le type d'action
  IconData _getActionIcon() {
    switch (widget.actionType) {
      case BombActionType.arm:
        return Icons.whatshot;
      case BombActionType.disarm:
        return Icons.build;
    }
  }

  /// Obtient le titre selon le type d'action
  String _getActionTitle() {
    switch (widget.actionType) {
      case BombActionType.arm:
        return 'Armement en cours';
      case BombActionType.disarm:
        return 'Désarmement en cours';
    }
  }

  /// Formate le temps en MM:SS
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final actionColor = _getActionColor();
    final l10n = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: () async {
        _cancelAction();
        return false;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: actionColor, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône avec animation de pulsation
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.1),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: actionColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getActionIcon(),
                        size: 48,
                        color: actionColor,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Titre
              Text(
                _getActionTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Nom du site
              Text(
                widget.bombSite.name,
                style: TextStyle(
                  color: actionColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Temps restant (grand affichage)
              Text(
                _formatTime(_timeRemaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),

              const SizedBox(height: 24),

              // Barre de progression
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(actionColor),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_progressController.value * 100).toInt()}%',
                        style: TextStyle(
                          color: actionColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(l10n.stayInZoneToContinue,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.leavingZoneWillCancel,
                      style: TextStyle(
                        color: Colors.orange.shade300,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bouton d'annulation (optionnel)
              TextButton(
                onPressed: _cancelAction,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fonction utilitaire pour afficher le dialog automatiquement
Future<bool?> showBombActionDialog({
  required BuildContext context,
  required BombSite bombSite,
  required BombActionType actionType,
  required int duration,
  required BombOperationService bombOperationService,
  required BombProximityDetectionService proximityService,
  required int gameSessionId,
  required int fieldId,
  required int userId,
  required double latitude,
  required double longitude,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // Empêche la fermeture en tapant à côté
    builder: (context) => BombActionDialog(
      bombSite: bombSite,
      actionType: actionType,
      duration: duration,
      bombOperationService: bombOperationService,
      proximityService: proximityService,
      gameSessionId: gameSessionId,
      fieldId: fieldId,
      userId: userId,
      latitude: latitude,
      longitude: longitude,
    ),
  );
}
