import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import 'package:airsoft_game_map/utils/logger.dart';

class TeamService extends ChangeNotifier {
  final ApiService _apiService;
  final GameStateService _gameStateService;

  List<Team> _teams = [];
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

  List<dynamic> get previousPlayers => _previousPlayers;

  List<Team> get previousTeamConfigurations => _previousTeamConfigurations;

  bool _disposed = false;
  bool _isUpdating = false;

  @override
  void dispose() {
    _disposed = true;
    // S'assurer que le timer est annulé avant de disposer le service
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

      logger.d('🔄 [team_service] [loadTeams] Chargement des équipes pour la carte $mapId: ${_teams.length} équipes');
      // Synchroniser les joueurs connectés avec les équipes
      synchronizePlayersWithTeams();

      final currentUserId = _apiService.authService.currentUser?.id;
      if (currentUserId != null) {
        updateMyTeamId(currentUserId);
      }

      safeNotifyListeners();
    } catch (e) {
      logger.d('[team_service] Erreur lors du chargement des équipes: $e');
    }
  }

  //synchroniser les joueurs avec les équipes
  void synchronizePlayersWithTeams() {
    // Récupérer la liste des joueurs connectés depuis GameStateService
    final connectedPlayers = _gameStateService.connectedPlayersList;

    //logger.d('📋 Début de synchronisation - Joueurs connectés: ${connectedPlayers.length}, Équipes: ${_teams.length}');

    // Pour chaque équipe, vider sa liste de joueurs
    for (var team in _teams) {
      team.players = [];
    }

    // Pour chaque joueur connecté qui a un teamId, l'ajouter à l'équipe correspondante
    for (var player in connectedPlayers) {
      final playerId = player['id'];
      final teamId = player['teamId'];

      //logger.d('🔄 Traitement du joueur ${player['username']} (ID: $playerId) - TeamId: $teamId');

      if (teamId != null) {
        // Trouver l'équipe correspondante
        final teamIndex = _teams.indexWhere((team) => team.id == teamId);

        if (teamIndex >= 0) {
          // Créer une copie du joueur pour éviter les références partagées
          final playerCopy = Map<String, dynamic>.from(player);

          // Ajouter le joueur à cette équipe
          _teams[teamIndex].players.add(playerCopy);

          //logger.d('✅ Joueur ${player['username']} (ID: $playerId) ajouté à l\'équipe ${_teams[teamIndex].name} (ID: ${_teams[teamIndex].id})');
        } else {
          //   logger.d(
          //      '⚠️ Équipe avec ID ${player['teamId']} non trouvée pour le joueur ${player['username']}');

          // Si l'équipe n'existe pas, mettre à jour le joueur pour enlever le teamId
          _updatePlayerTeamReference(player, null, null);
        }
      }
    }
    // Mettre à jour l'ID de l'équipe du joueur actuel
    final currentUserId = _apiService.authService.currentUser?.id;
    if (currentUserId != null) {
      updateMyTeamId(currentUserId);
      // logger.d('🔄 MyTeamId mis à jour: $_myTeamId');
    }

    //  logger.d('📋 Fin de synchronisation - Équipes avec leurs joueurs:');
    //for (var team in _teams) {
    //logger.d('   - ${team.name} (ID: ${team.id}): ${team.players.length} joueurs');
    //}
    notifyListeners();
  }

  // méthode pour mettre à jour les références d'équipe d'un joueur
  void _updatePlayerTeamReference(Map<String, dynamic> player, int? teamId,
      String? teamName) {
    final playerIndex = _gameStateService.connectedPlayersList
        .indexWhere((p) => p['id'] == player['id']);

    if (playerIndex >= 0) {
      final updatedPlayer = Map<String, dynamic>.from(player);

      if (teamId == null) {
        updatedPlayer.remove('teamId');
        updatedPlayer.remove('teamName');
        logger.d('🔄 TeamId supprimé pour le joueur ${player['username']}');
      } else {
        updatedPlayer['teamId'] = teamId;
        updatedPlayer['teamName'] = teamName;
        logger.d(
            '🔄 TeamId mis à jour pour le joueur ${player['username']}: $teamId ($teamName)');
      }

      final newList = List<Map<String, dynamic>>.from(
          _gameStateService.connectedPlayersList);
      newList[playerIndex] = updatedPlayer;
      _gameStateService.updateConnectedPlayersList(newList);
      notifyListeners();
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
      logger.d('❌ Erreur lors de la création de l\'équipe : $e');
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
      logger.d('Erreur lors du renommage de l\'équipe: $e');
    }
  }

  Future<void> assignPlayerToTeam(int playerId, int teamId, int mapId) async {
    final url = 'fields/$mapId/players/$playerId/team/$teamId';

    try {
      logger.d(
          '🔄 Tentative d\'assignation du joueur $playerId à l\'équipe $teamId');
      final result = await _apiService.post(url, {});
      logger.d('✅ Réponse du serveur pour l\'assignation : $result');

      await loadTeams(mapId);
      await _gameStateService.loadConnectedPlayers();

      synchronizePlayersWithTeams();
      safeNotifyListeners();
    } catch (e, stacktrace) {
      logger.d('❌ Erreur lors de l\'assignation du joueur à l\'équipe: $e');
      logger.d('📌 Stacktrace: $stacktrace');
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

  Future<void> loadPreviousPlayers() async {
    try {
      final previousPlayersData =
      await _apiService.get('host/previous-players');
      _previousPlayers = previousPlayersData as List;
      safeNotifyListeners();
    } catch (e) {
      logger.d('Erreur lors du chargement des joueurs précédents: $e');
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
      logger.d(
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
      logger.d('Erreur lors de la sauvegarde de la configuration d\'équipes: $e');
    }
  }

  Future<void> applyTeamConfiguration(int configId) async {
    final mapId = _gameStateService.selectedMap?.id;
    if (mapId == null) {
      logger.d('❌ Aucune carte sélectionnée pour appliquer la configuration.');
      return;
    }

    try {
      await _apiService.post('maps/$mapId/apply-team-config', {
        'configId': configId,
      });

      logger.d('✅ Configuration $configId appliquée à la carte $mapId');

      // 🔄 Recharger équipes et joueurs connectés
      await loadTeams(mapId);
      await _gameStateService.loadConnectedPlayers();

      safeNotifyListeners();
    } catch (e) {
      logger.d(
          '❌ Erreur lors de l\'application de la configuration d\'équipes: $e');
    }
  }

  // Dans team_service.dart
  Future<void> refreshAllTeamData() async {
    if (_gameStateService.selectedMap == null) return;

    if (_isUpdating) {
      logger.d('⚠️ Mise à jour déjà en cours, ignorée');
      return;
    }
    _isUpdating = true;
    final mapId = _gameStateService.selectedMap!.id;

    try {
      // Charger les équipes et les joueurs en parallèle
      await Future.wait([
      loadTeams(mapId!),
    _gameStateService.loadConnectedPlayers(),
    ]);

    // Mettre à jour l'ID de l'équipe du joueur actuel
    final currentUserId = _apiService.authService.currentUser?.id;
    if (currentUserId != null) {
    updateMyTeamId(currentUserId);
    }

    safeNotifyListeners();
    } catch (e) {

    logger.d('Erreur lors du rafraîchissement des données d\'équipe: $e');
    // Propager l'erreur à l'UI
    _lastError = e.toString();
    safeNotifyListeners();

    }finally {
    _isUpdating = false;
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
      logger.d('❌ Erreur lors de la suppression de l\'équipe: $e');
    }
  }

  Future<void> removePlayerFromTeam(int playerId, int mapId) async {
    try {
      // Appel à un endpoint spécifique pour retirer un joueur d'une équipe
      final url = 'teams/$mapId/players/$playerId/remove-from-team';
      final result = await _apiService.post(url, {});
      logger.d('✅ Joueur retiré de l\'équipe : $result');

      // Mettre à jour les données locales
      await loadTeams(mapId);
      await _gameStateService.loadConnectedPlayers();
      synchronizePlayersWithTeams();
      safeNotifyListeners();
    } catch (e, stacktrace) {
      logger.d('❌ Erreur lors du retrait du joueur de l\'équipe: $e');
      logger.d('📌 Stacktrace: $stacktrace');
    }
  }

  void updateTeamName(teamId, newName) {
    final index = _teams.indexWhere((team) => team.id == teamId);
    if (index >= 0) {
      _teams[index].name = newName;
      safeNotifyListeners();
    }
  }

  int? getTeamIdForPlayer(int userId) {
    for (final team in _teams) {
      if (team.players.any((p) => p['id'] == userId)) {
        return team.id;
      }
    }
    return null;
  }

  void removePlayerLocally(int playerId, int mapId) {
    for (final team in _teams) {
      final initialCount = team.players.length;
      team.players.removeWhere((p) => p['id'] == playerId);
      final newCount = team.players.length;

      if (initialCount != newCount) {
        logger.d('🗑️ Joueur $playerId retiré localement de l\'équipe ${team.id}');
        break;
      }
    }

    // 🔧 Mise à jour directe du joueur dans connectedPlayersList
    try {
      final connectedPlayer = _gameStateService.connectedPlayersList
          .firstWhere((p) => p['id'] == playerId);
      connectedPlayer['teamId'] = null;
      logger.d('🔄 teamId du joueur $playerId mis à jour à null');
    } catch (e) {
      logger.d('⚠️ Joueur $playerId non trouvé dans connectedPlayersList');
    }

    synchronizePlayersWithTeams();
    safeNotifyListeners();
  }

  void addTeam(Map<String, dynamic> teamData, int mapId) {
    final teamId = teamData['id'];
    final teamName = teamData['name'];
    if (teamId == null || teamName == null) return;

    // Vérifie que l'équipe n'existe pas déjà
    if (_teams.any((t) => t.id == teamId)) {
      logger.d('ℹ️ Équipe déjà existante : $teamId');
      return;
    }

    _teams.add(
      Team(id: teamId, name: teamName, players: []),
    );
    logger.d('✅ Équipe ajoutée localement : $teamName (ID: $teamId)');
    safeNotifyListeners();
  }

  void deleteTeamLocally(int teamId, int mapId) {
    logger.d('🗑️ Suppression locale de l\'équipe ID=$teamId');

    final index = _teams.indexWhere((team) => team.id == teamId);
    if (index == -1) {
      logger.d('⚠️ Équipe $teamId non trouvée');
      return;
    }

    _teams.removeAt(index);

    // Nettoyage des joueurs connectés
    for (var player in _gameStateService.connectedPlayersList) {
      if (player['teamId'] == teamId) {
        player['teamId'] = null;
        player['teamName'] = null;
      }
    }

    synchronizePlayersWithTeams();
    safeNotifyListeners();
  }


}
