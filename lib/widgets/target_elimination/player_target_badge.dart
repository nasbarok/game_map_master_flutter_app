import 'package:flutter/material.dart';

class PlayerTargetBadge extends StatelessWidget {
  final int targetNumber;
  final bool isActive;
  final bool isInCooldown;
  final Color? backgroundColor;
  final Color? textColor;
  final double size;

  const PlayerTargetBadge({
    Key? key,
    required this.targetNumber,
    this.isActive = true,
    this.isInCooldown = false,
    this.backgroundColor,
    this.textColor,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color badgeColor;
    Color badgeTextColor;
    IconData? statusIcon;

    if (!isActive) {
      badgeColor = theme.colorScheme.outline.withOpacity(0.3);
      badgeTextColor = theme.colorScheme.onSurface.withOpacity(0.5);
      statusIcon = Icons.block;
    } else if (isInCooldown) {
      badgeColor = theme.colorScheme.secondary.withOpacity(0.8);
      badgeTextColor = theme.colorScheme.onSecondary;
      statusIcon = Icons.shield;
    } else {
      badgeColor = backgroundColor ?? theme.colorScheme.error;
      badgeTextColor = textColor ?? theme.colorScheme.onError;
      statusIcon = Icons.gps_fixed;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Numéro principal
          Center(
            child: Text(
              targetNumber.toString(),
              style: TextStyle(
                color: badgeTextColor,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Icône de statut en overlay
          if (statusIcon != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: size * 0.4,
                height: size * 0.4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(size * 0.2),
                  border: Border.all(
                    color: badgeColor,
                    width: 1,
                  ),
                ),
                child: Icon(
                  statusIcon,
                  size: size * 0.25,
                  color: badgeColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PlayerTargetBadgeWithTooltip extends StatelessWidget {
  final int targetNumber;
  final bool isActive;
  final bool isInCooldown;
  final String? cooldownTime;
  final String? playerName;
  final Color? backgroundColor;
  final Color? textColor;
  final double size;

  const PlayerTargetBadgeWithTooltip({
    Key? key,
    required this.targetNumber,
    this.isActive = true,
    this.isInCooldown = false,
    this.cooldownTime,
    this.playerName,
    this.backgroundColor,
    this.textColor,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String tooltipMessage = 'Cible #$targetNumber';
    
    if (playerName != null) {
      tooltipMessage += '\n$playerName';
    }
    
    if (!isActive) {
      tooltipMessage += '\nInactif';
    } else if (isInCooldown && cooldownTime != null) {
      tooltipMessage += '\nImmunisé ($cooldownTime)';
    } else {
      tooltipMessage += '\nDisponible';
    }

    return Tooltip(
      message: tooltipMessage,
      child: PlayerTargetBadge(
        targetNumber: targetNumber,
        isActive: isActive,
        isInCooldown: isInCooldown,
        backgroundColor: backgroundColor,
        textColor: textColor,
        size: size,
      ),
    );
  }
}

class PlayerTargetMiniCard extends StatelessWidget {
  final int targetNumber;
  final String? playerName;
  final String? teamName;
  final bool isActive;
  final bool isInCooldown;
  final String? cooldownTime;
  final VoidCallback? onTap;

  const PlayerTargetMiniCard({
    Key? key,
    required this.targetNumber,
    this.playerName,
    this.teamName,
    this.isActive = true,
    this.isInCooldown = false,
    this.cooldownTime,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerTargetBadge(
                targetNumber: targetNumber,
                isActive: isActive,
                isInCooldown: isInCooldown,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      playerName ?? 'Joueur $targetNumber',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (teamName != null) ...[
                      Text(
                        teamName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 9,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (isInCooldown && cooldownTime != null) ...[
                      Text(
                        'Immunisé $cooldownTime',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

