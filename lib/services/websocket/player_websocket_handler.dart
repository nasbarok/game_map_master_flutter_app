// lib/services/websocket/player_websocket_handler.dart
import '../../models/websocket/player_connected_message.dart';
import '../../models/websocket/player_disconnected_message.dart';
import '../game_state_service.dart';
import '../team_service.dart';

class PlayerWebSocketHandler {
  final GameStateService _gameStateService;
  final TeamService _teamService;

  PlayerWebSocketHandler(this._gameStateService, this._teamService);

  void handlePlayerConnected(PlayerConnectedMessage message) {
    final player = message.player;
    print('👤 Nouveau joueur connecté : $player');

    final list = List<Map<String, dynamic>>.from(_gameStateService.connectedPlayersList);
    final index = list.indexWhere((p) => p['id'] == player['id']);

    if (index >= 0) {
      print('🔁 Mise à jour du joueur existant avec ID=${player['id']}');
      list[index] = {
        ...list[index],
        'teamId': player['teamId'],
        'teamName': player['teamName'],
      };
    } else {
      print('➕ Ajout d\'un nouveau joueur avec ID=${player['id']}');
      list.add(player);
    }

    _gameStateService.updateConnectedPlayersList(list);
    _teamService.synchronizePlayersWithTeams();
  }

  void handlePlayerDisconnected(PlayerDisconnectedMessage message) {
    final userId = message.playerId;
    print('👋 Joueur déconnecté : ID=$userId');

    final list = List<Map<String, dynamic>>.from(_gameStateService.connectedPlayersList);
    list.removeWhere((p) => p['id'] == userId);

    _gameStateService.updateConnectedPlayersList(list);
    _teamService.synchronizePlayersWithTeams();
  }
}