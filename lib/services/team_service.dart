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
  List<Team> _previousTeamConfigurations =
      []; // Configurations d'équipes précédentes
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

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    // S'assurer que le timer est annulé avant de disposer le service
    stopPeriodicRefresh();
    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void clearError() {
    _lastError = null;
    safeNotifyListeners();
  }

  factory TeamService.placeholder() {
    return TeamService(
        ApiService.placeholder(), GameStateService.placeholder());
  }

  Future<void> loadTeams(int mapId) async {
    if (!_gameStateService.isTerrainOpen) return;

    try {
      final teamsData = await _apiService
          .get('teams/map/${_gameStateService.selectedMap!.id}');
      _teams = (teamsData as List).map((team) => Team.fromJson(team)).toList();

      // Synchroniser les joueurs connectés avec les équipes
      _synchronizePlayersWithTeams();

      final currentUserId = _apiService.authService.currentUser?.id;
      if (currentUserId != null) {
        updateMyTeamId(currentUserId);
      }

      safeNotifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des équipes: $e');
    }
  }

  //synchroniser les joueurs avec les équipes
  void _synchronizePlayersWithTeams() {
    // Récupérer la liste des joueurs connectés depuis GameStateService
    final connectedPlayers = _gameStateService.connectedPlayersList;

    // Pour chaque équipe, vider sa liste de joueurs
    for (var team in _teams) {
      team.players = [];
    }

    // Pour chaque joueur connecté qui a un teamId, l'ajouter à l'équipe correspondante
    for (var player in connectedPlayers) {
      if (player['teamId'] != null) {
        // Trouver l'équipe correspondante
        final teamIndex =
            _teams.indexWhere((team) => team.id == player['teamId']);
        if (teamIndex >= 0) {
          // Créer une copie du joueur pour éviter les références partagées
          final playerCopy = Map<String, dynamic>.from(player);

          // Ajouter le joueur à cette équipe
          _teams[teamIndex].players.add(playerCopy);

          //print('✅ Joueur ${player['username']} (ID: ${player['id']}) ajouté à l\'équipe ${_teams[teamIndex].name} (ID: ${_teams[teamIndex].id})');
        } else {
          print(
              '⚠️ Équipe avec ID ${player['teamId']} non trouvée pour le joueur ${player['username']}');

          // Si l'équipe n'existe pas, mettre à jour le joueur pour enlever le teamId
          final playerIndex = _gameStateService.connectedPlayersList
              .indexWhere((p) => p['id'] == player['id']);
          if (playerIndex >= 0) {
            final updatedPlayer = Map<String, dynamic>.from(player);
            updatedPlayer.remove('teamId');
            updatedPlayer.remove('teamName');

            final newList = List<Map<String, dynamic>>.from(
                _gameStateService.connectedPlayersList);
            newList[playerIndex] = updatedPlayer;
            _gameStateService.updateConnectedPlayersList(newList);

            print(
                '🔄 TeamId supprimé pour le joueur ${player['username']} car l\'équipe n\'existe pas');
          }
        }
      }
    }
  }

  Future<void> createTeam(String name) async {
    _lastError = null;
    if (!_gameStateService.isTerrainOpen ||
        _gameStateService.selectedMap == null) return;

    final mapId = _gameStateService.selectedMap!.id;
    try {
      final teamData = await _apiService.post('teams/map/$mapId/create', {
        'name': name,
      });
      final newTeam = Team.fromJson(teamData);
      _teams.add(newTeam);
      safeNotifyListeners();
    } catch (e) {
      print('❌ Erreur lors de la création de l\'équipe : $e');
      _lastError = 'Erreur lors de la création de l\'équipe : $e';
      safeNotifyListeners();
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
      safeNotifyListeners();
    } catch (e) {
      print('Erreur lors du renommage de l\'équipe: $e');
    }
  }

  Future<void> assignPlayerToTeam(int playerId, int teamId, int mapId) async {
    final url = 'maps/$mapId/players/$playerId/team/$teamId';

    try {
      print(
          '🔄 Tentative d\'assignation du joueur $playerId à l\'équipe $teamId');
      final result = await _apiService.post(url, {});
      print('✅ Réponse du serveur pour l\'assignation : $result');

      // Mettre à jour directement les données locales avant de recharger depuis le serveur

      // 1. Mettre à jour le joueur dans connectedPlayersList
      final gameStateService = _gameStateService;
      final playerIndex = gameStateService.connectedPlayersList
          .indexWhere((p) => p['id'] == playerId);

      if (playerIndex >= 0) {
        // Trouver le nom de l'équipe
        String? teamName;
        for (var team in _teams) {
          if (team.id == teamId) {
            teamName = team.name;
            break;
          }
        }

        print(
            '🔄 Mise à jour locale du joueur : teamId=$teamId, teamName=$teamName');

        // Créer une copie de la liste pour éviter les modifications directes
        final newList = List<Map<String, dynamic>>.from(
            gameStateService.connectedPlayersList);

        // Mettre à jour les informations du joueur
        newList[playerIndex] = {
          ...newList[playerIndex],
          'teamId': teamId,
          'teamName': teamName
        };

        // Mettre à jour la liste dans GameStateService
        gameStateService.updateConnectedPlayersList(newList);

        // 2. Mettre à jour les équipes localement
        _synchronizePlayersWithTeams();

        print('🔄 Synchronisation des joueurs avec les équipes terminée');
        print('📋 Teams après synchronisation: ${_teams.map((t) => {
              'id': t.id,
              'name': t.name,
              'players': t.players.map((p) => p['id']).toList()
            })}');
      }

      // 3. Recharger depuis le serveur pour s'assurer de la cohérence
      await Future.wait([loadTeams(mapId), loadConnectedPlayers()]);

      print('🔄 Rechargement depuis le serveur terminé');
      print('📋 Teams après rechargement: ${_teams.map((t) => {
            'id': t.id,
            'name': t.name,
            'players': t.players.map((p) => p['id']).toList()
          })}');

      safeNotifyListeners();
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

    safeNotifyListeners();
  }

  Future<void> loadConnectedPlayers() async {
    if (!_gameStateService.isTerrainOpen) return;

    try {
      final playersData = await _apiService
          .get('maps/${_gameStateService.selectedMap!.id}/players');
      _connectedPlayers = playersData as List;
      safeNotifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des joueurs connectés: $e');
    }
  }

  Future<void> loadPreviousPlayers() async {
    try {
      final previousPlayersData =
          await _apiService.get('host/previous-players');
      _previousPlayers = previousPlayersData as List;
      safeNotifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des joueurs précédents: $e');
    }
  }

  Future<void> loadPreviousTeamConfigurations() async {
    try {
      final configurationsData =
          await _apiService.get('host/team-configurations');
      _previousTeamConfigurations = (configurationsData as List)
          .map((config) => Team.fromJson(config))
          .toList();
      safeNotifyListeners();
    } catch (e) {
      print(
          'Erreur lors du chargement des configurations d\'équipes précédentes: $e');
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

      safeNotifyListeners();
    } catch (e) {
      print(
          '❌ Erreur lors de l\'application de la configuration d\'équipes: $e');
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

      safeNotifyListeners();
    } catch (e) {
      print('Erreur lors du rafraîchissement des données d\'équipe: $e');
      // Propager l'erreur à l'UI
      _lastError = e.toString();

      safeNotifyListeners();
    }
  }

  Future<void> deleteTeam(int teamId) async {
    try {
      // Appel au serveur pour supprimer l'équipe
      await _apiService.delete('teams/$teamId');

      // Mise à jour locale après confirmation du serveur
      final index = _teams.indexWhere((team) => team.id == teamId);
      if (index >= 0) {
        _teams.removeAt(index);
        safeNotifyListeners();
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression de l\'équipe: $e');
    }
  }

  void startPeriodicRefresh() {
    // Annuler le timer existant s'il y en a un
    _refreshTimer?.cancel();

    // Créer un nouveau timer qui rafraîchit les données toutes les 10 secondes
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (_) {
      if (_gameStateService.isTerrainOpen &&
          _gameStateService.selectedMap != null) {
        refreshAllTeamData();
      }
    });
  }

  void stopPeriodicRefresh() {
    if (_refreshTimer != null) {
      _refreshTimer!.cancel();
      _refreshTimer = null;
      print('🛑 Rafraîchissement périodique arrêté');
    }
  }

  Future<void> removePlayerFromTeam(int playerId, int mapId) async {
    try {
      // Appel à un endpoint spécifique pour retirer un joueur d'une équipe
      final url = 'teams/$mapId/players/$playerId/remove-from-team';
      final result = await _apiService.post(url, {});
      print('✅ Joueur retiré de l\'équipe : $result');

      // Mettre à jour les données locales
      await loadTeams(mapId);
      await loadConnectedPlayers();

      safeNotifyListeners();
    } catch (e, stacktrace) {
      print('❌ Erreur lors du retrait du joueur de l\'équipe: $e');
      print('📌 Stacktrace: $stacktrace');
    }
  }
}
