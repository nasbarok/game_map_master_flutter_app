// lib/services/websocket/team_websocket_handler.dart
import 'package:airsoft_game_map/models/websocket/team_update_message.dart';
import 'package:airsoft_game_map/services/auth_service.dart';

import '../../models/websocket/team_deleted_message.dart';
import '../team_service.dart';
import 'package:airsoft_game_map/utils/logger.dart';
class TeamWebSocketHandler {
  final TeamService _teamService;
  final AuthService authService;

  TeamWebSocketHandler(this._teamService,this.authService);

  void handleTeamUpdate(TeamUpdateMessage message) {
    final currentUsername = authService.currentUsername;
    final teamId = message.teamId;
    final newName = message.teamName;

    logger.d('✏️ Mise à jour du nom de l\'équipe ID=$teamId -> $newName');
    _teamService.updateTeamName(teamId, newName);
  }

  void handleTeamDeleted(TeamDeletedMessage message) {
    final teamId = message.teamId;
    logger.d('🗑️ Suppression de l\'équipe ID=$teamId');
    _teamService.deleteTeam(teamId);
  }
}