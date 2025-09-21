import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TargetEliminationNotification {
  final String type;
  final int scenarioId;
  final int killerId;
  final int victimId;
  final String killerName;
  final String victimName;
  final String? killerTeamName;
  final String? victimTeamName;
  final String message;
  final int points;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;

  TargetEliminationNotification({
    required this.type,
    required this.scenarioId,
    required this.killerId,
    required this.victimId,
    required this.killerName,
    required this.victimName,
    this.killerTeamName,
    this.victimTeamName,
    required this.message,
    required this.points,
    required this.timestamp,
    this.additionalData,
  });

  factory TargetEliminationNotification.fromJson(Map<String, dynamic> json) {
    return TargetEliminationNotification(
      type: json['type'] as String,
      scenarioId: json['scenarioId'] as int,
      killerId: json['killerId'] as int,
      victimId: json['victimId'] as int,
      killerName: json['killerName'] as String,
      victimName: json['victimName'] as String,
      killerTeamName: json['killerTeamName'] as String?,
      victimTeamName: json['victimTeamName'] as String?,
      message: json['message'] as String,
      points: json['points'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'scenarioId': scenarioId,
      'killerId': killerId,
      'victimId': victimId,
      'killerName': killerName,
      'victimName': victimName,
      'killerTeamName': killerTeamName,
      'victimTeamName': victimTeamName,
      'message': message,
      'points': points,
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
    };
  }

  TargetEliminationNotification copyWith({
    String? type,
    int? scenarioId,
    int? killerId,
    int? victimId,
    String? killerName,
    String? victimName,
    String? killerTeamName,
    String? victimTeamName,
    String? message,
    int? points,
    DateTime? timestamp,
    Map<String, dynamic>? additionalData,
  }) {
    return TargetEliminationNotification(
      type: type ?? this.type,
      scenarioId: scenarioId ?? this.scenarioId,
      killerId: killerId ?? this.killerId,
      victimId: victimId ?? this.victimId,
      killerName: killerName ?? this.killerName,
      victimName: victimName ?? this.victimName,
      killerTeamName: killerTeamName ?? this.killerTeamName,
      victimTeamName: victimTeamName ?? this.victimTeamName,
      message: message ?? this.message,
      points: points ?? this.points,
      timestamp: timestamp ?? this.timestamp,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  /// Vérifie si cette notification concerne un joueur spécifique
  bool concernsPlayer(int playerId) {
    return killerId == playerId || victimId == playerId;
  }

  /// Vérifie si cette notification concerne une équipe spécifique
  bool concernsTeam(int teamId) {
    return (killerTeamName != null && additionalData?['killerTeamId'] == teamId) ||
           (victimTeamName != null && additionalData?['victimTeamId'] == teamId);
  }

  /// Retourne le rôle du joueur dans cette élimination
  PlayerRole? getPlayerRole(int playerId) {
    if (killerId == playerId) return PlayerRole.killer;
    if (victimId == playerId) return PlayerRole.victim;
    return null;
  }

  /// Retourne un message formaté pour l'affichage
  String getFormattedMessage({bool includePoints = true}) {
    String formattedMessage = message;
    
    if (includePoints && points > 0) {
      formattedMessage += ' (+$points pts)';
    }
    
    return formattedMessage;
  }

  /// Retourne la couleur appropriée pour cette notification
  NotificationColor getNotificationColor(int? currentPlayerId) {
    if (currentPlayerId == null) return NotificationColor.neutral;
    
    if (killerId == currentPlayerId) return NotificationColor.success;
    if (victimId == currentPlayerId) return NotificationColor.danger;
    
    return NotificationColor.info;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TargetEliminationNotification &&
           other.scenarioId == scenarioId &&
           other.killerId == killerId &&
           other.victimId == victimId &&
           other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(scenarioId, killerId, victimId, timestamp);
  }

  @override
  String toString() {
    return 'TargetEliminationNotification{type: $type, killerId: $killerId, victimId: $victimId, message: $message}';
  }
}

enum PlayerRole {
  killer,
  victim,
}

enum NotificationColor {
  success,  // Vert - pour les kills du joueur
  danger,   // Rouge - pour les morts du joueur
  info,     // Bleu - pour les autres éliminations
  neutral,  // Gris - par défaut
}

/// Extension pour obtenir les couleurs Flutter
extension NotificationColorExtension on NotificationColor {
  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (this) {
      case NotificationColor.success:
        return theme.colorScheme.primary;
      case NotificationColor.danger:
        return theme.colorScheme.error;
      case NotificationColor.info:
        return theme.colorScheme.secondary;
      case NotificationColor.neutral:
        return theme.colorScheme.onSurface.withOpacity(0.6);
    }
  }
}

/// Widget pour afficher une notification d'élimination
class TargetEliminationNotificationWidget extends StatelessWidget {
  final TargetEliminationNotification notification;
  final int? currentPlayerId;
  final VoidCallback? onTap;

  const TargetEliminationNotificationWidget({
    Key? key,
    required this.notification,
    this.currentPlayerId,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = notification.getNotificationColor(currentPlayerId);
    final role = currentPlayerId != null 
        ? notification.getPlayerRole(currentPlayerId!) 
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icône
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.getColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getIconForRole(role),
                  size: 16,
                  color: color.getColor(context),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.getFormattedMessage(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: role != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimeAgo(notification.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForRole(PlayerRole? role) {
    switch (role) {
      case PlayerRole.killer:
        return Icons.gps_fixed;
      case PlayerRole.victim:
        return Icons.close;
      default:
        return Icons.info_outline;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }
}

