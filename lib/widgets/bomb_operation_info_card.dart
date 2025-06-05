import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/scenario/bomb_operation/bomb_operation_team.dart';
import '../services/scenario/bomb_operation/bomb_operation_service.dart';
import '../utils/logger.dart';

/// Widget affichant les informations du scénario Opération Bombe
class BombOperationInfoCard extends StatelessWidget {
  final int? teamId;
  final int userId;
  final int gameSessionId;

  const BombOperationInfoCard({
    Key? key,
    required this.teamId,
    required this.userId,
    required this.gameSessionId,
  }) : super(key: key);

  static final Color neutralCardColor = Colors.grey.shade200;
  static final Color attackCardColor = Colors.red.shade100;
  static final Color defenseCardColor = Colors.blue.shade100;

  @override
  Widget build(BuildContext context) {
    if (teamId == null) {
      logger.d('⚠️ [BombOperationInfoCard] teamId est null, impossible d\'afficher le rôle');
      return const SizedBox.shrink();
    }

    final bombOperationService = GetIt.I<BombOperationService>();
    final teamRoles = bombOperationService.teamRoles;
    
    if (teamRoles.isEmpty) {
      logger.d('⚠️ [BombOperationInfoCard] Aucun rôle d\'équipe défini');
      return Card(
        color: neutralCardColor,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Scénario Opération Bombe actif - En attente d\'assignation des rôles',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final role = teamRoles[teamId];
    if (role == null) {
      logger.d('⚠️ [BombOperationInfoCard] Aucun rôle trouvé pour l\'équipe $teamId');
      return Card(
        color: neutralCardColor,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Votre équipe n\'a pas de rôle assigné dans ce scénario',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Déterminer le message et le style en fonction du rôle
    String roleText;
    String objectiveText;
    Color cardColor;
    IconData roleIcon;

    switch (role) {
      case BombOperationTeam.attack:
        roleText = 'Terroriste';
        objectiveText = 'Rendez-vous dans une zone de bombe pour activer la détonation';
        cardColor = attackCardColor;
        roleIcon = Icons.dangerous;
        break;
      case BombOperationTeam.defense:
        roleText = 'Anti-terroriste';
        objectiveText = 'Rendez-vous dans la zone de bombe active pour la désactiver';
        cardColor = defenseCardColor;
        roleIcon = Icons.shield;
        break;
      default:
        roleText = 'Rôle inconnu';
        objectiveText = 'Objectif non défini';
        cardColor = neutralCardColor;
        roleIcon = Icons.question_mark;
    }

    return Card(
      color: cardColor,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(roleIcon, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Vous êtes : $roleText',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Objectif : $objectiveText',
              style: const TextStyle(fontSize: 16),
            ),
            // Espace pour des informations supplémentaires futures
            // comme le temps de désactivation, l'état des bombes, etc.
          ],
        ),
      ),
    );
  }
}
