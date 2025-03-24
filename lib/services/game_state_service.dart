import 'package:flutter/foundation.dart';
import '../../models/game_map.dart';

// Service pour gérer l'état du jeu et la communication entre les composants
class GameStateService extends ChangeNotifier {
  bool _isTerrainOpen = false;
  GameMap? _selectedMap;
  List<dynamic>? _selectedScenarios = [];
  int? _gameDuration; // en minutes, null si pas de limite de temps
  int _connectedPlayers = 0;
  bool _isGameRunning = false;

  // Getters
  bool get isTerrainOpen => _isTerrainOpen;
  GameMap? get selectedMap => _selectedMap;
  List<dynamic>? get selectedScenarios => _selectedScenarios;
  int? get gameDuration => _gameDuration;
  int get connectedPlayers => _connectedPlayers;
  bool get isGameRunning => _isGameRunning;

  // Méthodes pour mettre à jour l'état
  void selectMap(GameMap map) {
    _selectedMap = map;
    notifyListeners();
  }

  void toggleTerrainOpen() {
    if (_selectedMap == null) {
      return; // Ne rien faire si aucune carte n'est sélectionnée
    }
    
    _isTerrainOpen = !_isTerrainOpen;
    
    if (!_isTerrainOpen) {
      // Réinitialiser les valeurs si on ferme le terrain
      _selectedScenarios = [];
      _gameDuration = null;
      _connectedPlayers = 0;
      _isGameRunning = false;
    }
    
    notifyListeners();
  }

  void setSelectedScenarios(List<dynamic> scenarios) {
    _selectedScenarios = scenarios;
    notifyListeners();
  }

  void setGameDuration(int? duration) {
    _gameDuration = duration;
    notifyListeners();
  }

  void updateConnectedPlayers(int count) {
    _connectedPlayers = count;
    notifyListeners();
  }

  void startGame() {
    if (!_isTerrainOpen || _selectedScenarios == null || _selectedScenarios!.isEmpty) {
      return; // Ne rien faire si les conditions ne sont pas remplies
    }
    
    _isGameRunning = true;
    notifyListeners();
  }

  void stopGame() {
    _isGameRunning = false;
    notifyListeners();
  }

  // Réinitialiser tout l'état
  void reset() {
    _isTerrainOpen = false;
    _selectedMap = null;
    _selectedScenarios = [];
    _gameDuration = null;
    _connectedPlayers = 0;
    _isGameRunning = false;
    notifyListeners();
  }
}
