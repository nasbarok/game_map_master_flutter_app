import '../../models/connected_player.dart';
import 'api_service.dart';
import 'game_state_service.dart';

class PlayerConnectionService {
  final ApiService _apiService;
  final GameStateService _gameStateService;

  PlayerConnectionService(this._apiService,this._gameStateService);

  // Rejoindre une carte
  Future<ConnectedPlayer> joinMap(int fieldId, {int? teamId}) async {
    final query = teamId != null ? '?teamId=$teamId' : '';
    final endpoint = 'fields/$fieldId/join$query';

    final response = await _apiService.post(endpoint, {});
    return ConnectedPlayer.fromJson(response);
  }

  // Quitter une carte
  Future<void> leaveField(int fieldId) async {
    await _apiService.post('fields/$fieldId/leave', {});
    _gameStateService.reset();
  }
  Future<void> leaveFieldForHost(int fieldId) async {
    await _apiService.post('fields/$fieldId/leave', {});
  }
  // Obtenir la liste des joueurs connectés
  Future<List<ConnectedPlayer>> getConnectedPlayers(int fieldId) async {
    final response = await _apiService.get('fields/$fieldId/players');

    return List<ConnectedPlayer>.from(
      response.map((json) => ConnectedPlayer.fromJson(json)),
    );
  }
}
