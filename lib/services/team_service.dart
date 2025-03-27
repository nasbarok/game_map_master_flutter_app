import 'dart:async';

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
  String? _lastError;
  String? get lastError => _lastError;
  Timer? _refreshTimer;

  TeamService(this._apiService, this._gameStateService);
  
  List<Team> get teams => _teams;
  List<dynamic> get connectedPlayers => _connectedPlayers;
  List<dynamic> get previousPlayers => _previousPlayers;
  List<Team> get previousTeamConfigurations => _previousTeamConfigurations;

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  factory TeamService.placeholder() {
    return TeamService(ApiService.placeholder(), GameStateService.placeholder());
  }

  Future<void> loadTeams(int mapId) async {
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
    _lastError = null;
    if (!_gameStateService.isTerrainOpen || _gameStateService.selectedMap == null) return;

    final mapId = _gameStateService.selectedMap!.id;
    try {
      final teamData = await _apiService.post('teams/map/$mapId/create', {
        'name': name,
      });
      final newTeam = Team.fromJson(teamData);
      _teams.add(newTeam);
      notifyListeners();
    } catch (e) {
      print('❌ Erreur lors de la création de l\'équipe : $e');
      _lastError = 'Erreur lors de la création de l\'équipe : $e';
      notifyListeners();
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

  Future<void> assignPlayerToTeam(int playerId, int teamId, int mapId) async {
    final url = 'maps/$mapId/players/$playerId/team/$teamId';

    try {
      final result = await _apiService.post(url, {});
      print('✅ Joueur assigné : $result');

      // 🔄 Recharge propre de la source de vérité côté backend
      await loadTeams(mapId);
      await loadConnectedPlayers();

      notifyListeners();
    } catch (e, stacktrace) {
      print('❌ Erreur lors de l\'assignation du joueur à l\'équipe: $e');
      print('📌 Stacktrace: $stacktrace');
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
    final mapId = _gameStateService.selectedMap?.id;
    if (mapId == null) {
      print('❌ Aucune carte sélectionnée pour appliquer la configuration.');
      return;
    }

    try {
      await _apiService.post('maps/$mapId/apply-team-config', {
        'configId': configId,
      });

      print('✅ Configuration $configId appliquée à la carte $mapId');

      // 🔄 Recharger équipes et joueurs connectés
      await loadTeams(mapId);
      await loadConnectedPlayers();

      notifyListeners();
    } catch (e) {
      print('❌ Erreur lors de l\'application de la configuration d\'équipes: $e');
    }
  }

  // Dans team_service.dart
  Future<void> refreshAllTeamData() async {
    if (_gameStateService.selectedMap == null) return;

    final mapId = _gameStateService.selectedMap!.id;

    try {
      // Charger les équipes et les joueurs en parallèle
      await Future.wait([
        loadTeams(mapId!),
        loadConnectedPlayers(),
      ]);

      // Mettre à jour l'ID de l'équipe du joueur actuel
      final currentUserId = _apiService.authService.currentUser?.id;
      if (currentUserId != null) {
        updateMyTeamId(currentUserId);
      }

      notifyListeners();
    } catch (e) {
      print('Erreur lors du rafraîchissement des données d\'équipe: $e');
      // Propager l'erreur à l'UI
      _lastError = e.toString();

      notifyListeners();
    }
  }


  void deleteTeam(int id) {
    final index = _teams.indexWhere((team) => team.id == id);
    if (index < 0) return;

    _teams.removeAt(index);
    notifyListeners();
  }

  void startPeriodicRefresh() {
    // Annuler le timer existant s'il y en a un
    _refreshTimer?.cancel();

    // Créer un nouveau timer qui rafraîchit les données toutes les 10 secondes
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (_) {
      if (_gameStateService.isTerrainOpen && _gameStateService.selectedMap != null) {
        refreshAllTeamData();
      }
    });
  }

  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
}
