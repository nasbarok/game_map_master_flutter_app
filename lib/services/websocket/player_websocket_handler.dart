// lib/services/websocket/player_websocket_handler.dart
import '../../models/websocket/player_connected_message.dart';
import '../../models/websocket/player_disconnected_message.dart';
import '../game_state_service.dart';
import '../team_service.dart';

class PlayerWebSocketHandler {
  final GameStateService _gameStateService;
  final TeamService _teamService;

  PlayerWebSocketHandler(this._gameStateService, this._teamService);
}