import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';

class TeamService extends ChangeNotifier {
  final ApiService _apiService;
  final GameStateService _gameStateService;
  
  List<Team> _teams = [];
  List<dynamic> _connectedPlayers = [];
  List<dynamic> _previousPlayers = []; // Joueurs précédemment connectés
  List<Team> _previousTeamConfigurations = []; // Configurations d'équipes précédentes
  int? _myTeamId;
  int? get myTeamId => _myTeamId;

  TeamService(this._apiService, this._gameStateService);
  
  List<Team> get teams => _teams;
  List<dynamic> get connectedPlayers => _connectedPlayers;
  List<dynamic> get previousPlayers => _previousPlayers;
  List<Team> get previousTeamConfigurations => _previousTeamConfigurations;

  factory TeamService.placeholder() {
    return TeamService(ApiService.placeholder(), GameStateService.placeholder());
  }

  Future<void> loadTeams() async {
    if (!_gameStateService.isTerrainOpen) return;
    
    try {
      final teamsData = await _apiService.get('teams/map/${_gameStateService.selectedMap!.id}');
      _teams = (teamsData as List).map((team) => Team.fromJson(team)).toList();

      final currentUserId = _apiService.authService.currentUser?.id;
      if (currentUserId != null) {
        updateMyTeamId(currentUserId);
      }

      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des équipes: $e');
    }
  }
  
  Future<void> createTeam(String name) async {
    if (!_gameStateService.isTerrainOpen) return;
    
    try {
      final teamData = await _apiService.post('teams', {
        'name': name,
        'mapId': _gameStateService.selectedMap!.id,
      });
      
      final newTeam = Team.fromJson(teamData);
      _teams.add(newTeam);
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la création de l\'équipe: $e');
    }
  }
  
  Future<void> renameTeam(int teamId, String newName) async {
    final index = _teams.indexWhere((team) => team.id == teamId);
    if (index < 0) return;
    
    try {
      await _apiService.put('teams/$teamId', {
        'name': newName,
      });
      
      _teams[index].name = newName;
      notifyListeners();
    } catch (e) {
      print('Erreur lors du renommage de l\'équipe: $e');
    }
  }
  
  Future<void> assignPlayerToTeam(int playerId, int teamId) async {
    try {
      await _apiService.post('teams/$teamId/players', {
        'playerId': playerId,
      });
      
      // Mettre à jour localement
      final teamIndex = _teams.indexWhere((team) => team.id == teamId);
      if (teamIndex >= 0) {
        // Retirer le joueur de son équipe actuelle
        for (var team in _teams) {
          team.players.removeWhere((player) => player['id'] == playerId);
        }
        
        // Ajouter à la nouvelle équipe
        final playerData = _connectedPlayers.firstWhere((player) => player['id'] == playerId, orElse: () => null);
        if (playerData != null) {
          _teams[teamIndex].players.add(playerData);
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de l\'assignation du joueur à l\'équipe: $e');
    }
  }

  void updateMyTeamId(int myPlayerId) {
    _myTeamId = null;

    for (var team in _teams) {
      if (team.players.any((player) => player['id'] == myPlayerId)) {
        _myTeamId = team.id;
        break;
      }
    }

    notifyListeners();
  }

  Future<void> loadConnectedPlayers() async {
    if (!_gameStateService.isTerrainOpen) return;
    
    try {
      final playersData = await _apiService.get('maps/${_gameStateService.selectedMap!.id}/players');
      _connectedPlayers = playersData as List;
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des joueurs connectés: $e');
    }
  }
  
  Future<void> loadPreviousPlayers() async {
    try {
      final previousPlayersData = await _apiService.get('host/previous-players');
      _previousPlayers = previousPlayersData as List;
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des joueurs précédents: $e');
    }
  }
  
  Future<void> loadPreviousTeamConfigurations() async {
    try {
      final configurationsData = await _apiService.get('host/team-configurations');
      _previousTeamConfigurations = (configurationsData as List)
          .map((config) => Team.fromJson(config))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des configurations d\'équipes précédentes: $e');
    }
  }
  
  Future<void> saveCurrentTeamConfiguration(String configName) async {
    try {
      await _apiService.post('host/team-configurations', {
        'name': configName,
        'teams': _teams.map((team) => team.toJson()).toList(),
      });
    } catch (e) {
      print('Erreur lors de la sauvegarde de la configuration d\'équipes: $e');
    }
  }
  
  Future<void> applyTeamConfiguration(int configId) async {
    try {
      await _apiService.post('maps/${_gameStateService.selectedMap!.id}/apply-team-config', {
        'configId': configId,
      });
      
      // Recharger les équipes
      await loadTeams();
    } catch (e) {
      print('Erreur lors de l\'application de la configuration d\'équipes: $e');
    }
  }
}
