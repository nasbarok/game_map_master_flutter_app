// lib/services/websocket/team_websocket_handler.dart
import '../../models/websocket/team_deleted_message.dart';
import '../../models/websocket/team_updated_message.dart';
import '../team_service.dart';

class TeamWebSocketHandler {
  final TeamService _teamService;

  TeamWebSocketHandler(this._teamService);

  void handleTeamUpdated(TeamUpdatedMessage message) {
    final teamId = message.teamId;
    final newName = message.teamName;

    print('✏️ Mise à jour du nom de l\'équipe ID=$teamId -> $newName');
    _teamService.updateTeamName(teamId, newName);
  }

  void handleTeamDeleted(TeamDeletedMessage message) {
    final teamId = message.teamId;
    print('🗑️ Suppression de l\'équipe ID=$teamId');
    _teamService.deleteTeam(teamId);
  }
}