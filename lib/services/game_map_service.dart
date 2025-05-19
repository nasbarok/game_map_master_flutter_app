import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../models/game_map.dart';
import '../../services/api_service.dart';

class GameMapService extends ChangeNotifier {
  final ApiService _apiService;

  List<GameMap> _gameMaps = [];

  List<GameMap> get gameMaps => _gameMaps;

  GameMapService(this._apiService) ;

  // Charger les cartes depuis l'API
  Future<void> loadGameMaps() async {
    try {
      final response = await _apiService.get('maps/owner/self');
      _gameMaps = (response as List).map((e) => GameMap.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Erreur de chargement des cartes: $e');
    }
  }

  /// Récupère une carte par son ID
  Future<GameMap> getGameMapById(int mapId) async {
    try {
      // Vérifie d'abord si la carte est déjà en mémoire
      final cachedMap = _gameMaps.firstWhere(
        (map) => map.id == mapId,
        orElse: () => GameMap(name: 'Carte non trouvée'),
      );

      if (cachedMap.id != null) {
        return cachedMap;
      }

      // Sinon, charge depuis l'API
      final response = await _apiService.get('maps/$mapId');
      return GameMap.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la carte: $e');
    }
  }

  /// Ajoute une nouvelle carte
  Future<void> addGameMap(GameMap gameMap) async {
    try {
      await _apiService.post('maps', gameMap.toJson());
      _gameMaps.add(gameMap);  // Ajoute la carte à la liste locale
      notifyListeners();  // Notifie les widgets abonnés
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la carte: $e');
    }
  }

  // Méthode pour mettre à jour une carte existante
  Future<void> updateGameMap(GameMap gameMap) async {
    try {
      await _apiService.put('maps/${gameMap.id}', gameMap.toJson());

      // Met à jour la carte dans la liste locale
      final index = _gameMaps.indexWhere((map) => map.id == gameMap.id);
      if (index != -1) {
        _gameMaps[index] = gameMap;
        notifyListeners();  // Notifie les widgets abonnés
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la carte: $e');
    }
  }

  // Supprimer une carte existante
  Future<void> deleteGameMap(int mapId) async {
    try {
      await _apiService.delete('maps/$mapId');  // Appelle l'API pour supprimer
      _gameMaps.removeWhere((map) => map.id == mapId);  // Enlève de la liste locale
      notifyListeners();  // Met à jour l'UI
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la carte: $e');
    }
  }

}
