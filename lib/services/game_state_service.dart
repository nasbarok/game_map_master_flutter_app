import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../models/game_map.dart';

// Service pour gérer l'état du jeu et la communication entre les composants
class GameStateService extends ChangeNotifier {
  bool _isTerrainOpen = false;
  GameMap? _selectedMap;
  List<dynamic>? _selectedScenarios = [];
  int? _gameDuration; // en minutes, null si pas de limite de temps
  int _connectedPlayers = 0;
  bool _isGameRunning = false;
  
  // Nouvelles propriétés pour le décompte
  DateTime? _gameEndTime;
  String _timeLeftDisplay = "00:00:00";
  Timer? _gameTimer;

  // Nouvelle liste pour gérer les joueurs connectés
  List<Map<String, dynamic>> _connectedPlayersList = [];

  // Getters
  bool get isTerrainOpen => _isTerrainOpen;
  GameMap? get selectedMap => _selectedMap;
  List<dynamic>? get selectedScenarios => _selectedScenarios;
  int? get gameDuration => _gameDuration;
  int get connectedPlayers => _connectedPlayers;
  bool get isGameRunning => _isGameRunning;
  String get timeLeftDisplay => _timeLeftDisplay;
  DateTime? get gameEndTime => _gameEndTime;
  List<Map<String, dynamic>> get connectedPlayersList => _connectedPlayersList;

  GameStateService();

  factory GameStateService.placeholder() {
    return GameStateService();
  }

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
      _gameTimer?.cancel();
      _gameEndTime = null;
      _timeLeftDisplay = "00:00:00";
      _connectedPlayersList.clear(); // Vider la liste des joueurs connectés
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
    
    // Calculer l'heure de fin si une durée est définie
    if (_gameDuration != null) {
      _gameEndTime = DateTime.now().add(Duration(minutes: _gameDuration!));
      _startGameTimer();
    } else {
      _timeLeftDisplay = "∞"; // Durée illimitée
    }
    
    notifyListeners();
  }

  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameEndTime == null) {
        _timeLeftDisplay = "∞"; // Durée illimitée
        notifyListeners();
        return;
      }
      
      final now = DateTime.now();
      final difference = _gameEndTime!.difference(now);
      
      if (difference.isNegative) {
        // La partie est terminée
        _timeLeftDisplay = "00:00:00";
        stopGame();
        return;
      }
      
      // Formater au format HH:MM:SS
      final hours = difference.inHours.toString().padLeft(2, '0');
      final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
      
      _timeLeftDisplay = "$hours:$minutes:$seconds";
      notifyListeners();
    });
  }

  void stopGame() {
    _isGameRunning = false;
    _gameTimer?.cancel();
    _gameEndTime = null;
    _timeLeftDisplay = "00:00:00";
    notifyListeners();
  }

  // Méthode pour synchroniser le temps via WebSocket
  void syncGameTime(DateTime endTime) {
    _gameEndTime = endTime;
    if (_isGameRunning && _gameEndTime != null) {
      _startGameTimer();
    }
  }

  void incrementConnectedPlayers() {
    _connectedPlayers++;
    notifyListeners();
  }

  // Nouvelles méthodes pour gérer la liste des joueurs connectés
  void addConnectedPlayer(Map<String, dynamic> player) {
    // Vérifier si le joueur est déjà connecté
    final existingIndex = _connectedPlayersList.indexWhere((p) => p['id'] == player['id']);

    if (existingIndex == -1) {
      _connectedPlayersList.add(player);
      _connectedPlayers = _connectedPlayersList.length;
      notifyListeners();
    }
  }

  // Méthode pour vérifier si un joueur est déjà connecté
  bool isPlayerConnected(int playerId) {
    return _connectedPlayersList.any((p) => p['id'] == playerId);
  }

  // Méthode pour supprimer un joueur connecté
  void removeConnectedPlayer(int playerId) {
    _connectedPlayersList.removeWhere((p) => p['id'] == playerId);
    _connectedPlayers = _connectedPlayersList.length;
    notifyListeners();
  }

  // Méthode pour vider la liste des joueurs connectés (quand le terrain est fermé)
  void clearConnectedPlayers() {
    _connectedPlayersList.clear();
    _connectedPlayers = 0;
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
    _gameTimer?.cancel();
    _gameEndTime = null;
    _timeLeftDisplay = "00:00:00";
    _connectedPlayersList.clear();
    notifyListeners();
  }
}
