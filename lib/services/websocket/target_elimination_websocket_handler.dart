import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/websocket/websocket_message.dart';

class TargetEliminationWebSocketHandler {
  static void handleMessage(WebSocketMessage message, BuildContext context) {
    switch (message.type) {
      case 'PLAYER_ELIMINATED':
        _handlePlayerEliminated(message, context);
        break;
      case 'TARGET_ASSIGNED':
        _handleTargetAssigned(message, context);
        break;
      case 'SCORES_UPDATED':
        _handleScoresUpdated(message, context);
        break;
    }
  }

  static void _handlePlayerEliminated(WebSocketMessage message, BuildContext context) {
    final data = message.data as Map<String, dynamic>;
    final elimination = Elimination.fromJson(data['elimination']);

    // Mettre à jour les scores locaux
    final scoreService = context.read<TargetEliminationScoreService>();
    scoreService.updateScoresAfterElimination(elimination);

    // Afficher notification
    final announcementTemplate = data['announcementTemplate'] as String;
    final announcement = announcementTemplate
        .replaceAll('{killer}', elimination.killer.username)
        .replaceAll('{victim}', elimination.victim.username);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(announcement),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  static void _handleTargetAssigned(WebSocketMessage message, BuildContext context) {
    final data = message.data as Map<String, dynamic>;
    final playerTarget = PlayerTarget.fromJson(data['playerTarget']);

    // Mettre à jour l'état local
    final service = context.read<TargetEliminationService>();
    service.updatePlayerTarget(playerTarget);
  }

  static void _handleScoresUpdated(WebSocketMessage message, BuildContext context) {
    final data = message.data as Map<String, dynamic>;

    // Mettre à jour le tableau des scores
    final scoreService = context.read<TargetEliminationScoreService>();
    scoreService.refreshScoreboard();
  }
}