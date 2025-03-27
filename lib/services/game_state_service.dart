import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../models/game_map.dart';
import 'api_service.dart';

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

  get gameStateService => null;

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

  void incrementConnectedPlayers(payload) {
    print('📈 Ajout du joueur depuis payload : ${payload['fromUsername']} (ID: ${payload['fromUserId']})');

    addConnectedPlayer({
      'id': payload['fromUserId'],
      'username': payload['fromUsername'] ?? 'Joueur',
      'teamId': payload['teamId'],
      'teamName': payload['teamName'],
    });
  }

  // Nouvelles méthodes pour gérer la liste des joueurs connectés
  void addConnectedPlayer(Map<String, dynamic> player) {
    final existingIndex = _connectedPlayersList.indexWhere((p) => p['id'] == player['id']);
    print('🔍 Vérification si ${player['username']} (ID: ${player['id']}) est déjà dans la liste → index: $existingIndex');

    if (existingIndex == -1) {
      _connectedPlayersList.add(player);
      _connectedPlayers = _connectedPlayersList.length;
      print('✅ Joueur ajouté. Total connectés : $_connectedPlayers');
      notifyListeners();
    } else {
      print('⚠️ Joueur déjà présent, non ajouté.');
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

  Future<void> restoreSessionIfNeeded(ApiService apiService) async {
    try {
      // Étape 1 : Terrain actif
      print('🔎 [RESTORE] Appel GET /fields/active/current');
      final activeFieldResponse = await apiService.get('fields/active/current');
      print('📦 [RESTORE] Réponse terrain actif : $activeFieldResponse');

      // Vérifier si la réponse est valide
      if (activeFieldResponse == null) {
        print('ℹ️ [RESTORE] Aucun terrain actif trouvé.');
        return;
      }

      // Vérifier si la réponse est au format attendu
      // Vérifier si c'est un objet avec active=false
      if (activeFieldResponse is Map && activeFieldResponse['active'] == false) {
        print('ℹ️ [RESTORE] Aucun terrain actif trouvé.');
        return;
      }

      final fieldId = activeFieldResponse['id'];
      print('✅ [RESTORE] Terrain actif : ${activeFieldResponse['name']} (ID: $fieldId)');

      // Étape 2 : Carte liée
      print('🔎 [RESTORE] Appel GET /maps?fieldId=$fieldId');
      final maps = await apiService.get('maps?fieldId=$fieldId');
      print('📦 [RESTORE] Réponse cartes : $maps');

      if (maps == null || maps is! List || maps.isEmpty) {
        print('⚠️ [RESTORE] Aucune carte trouvée pour ce terrain.');
        return;
      }

      final selected = GameMap.fromJson(maps[0]);
      print('✅ [RESTORE] Carte sélectionnée : ${selected.name} (ID: ${selected.id})');
      selectMap(selected);
      _isTerrainOpen = true;

      // Étape 3 : Joueurs connectés
      print('🔎 [RESTORE] Appel GET /maps/${selected.id}/players');
      final players = await apiService.get('maps/${selected.id}/players');
      print('📦 [RESTORE] Réponse joueurs connectés : $players');

      if (players == null || players is! List) {
        print('⚠️ [RESTORE] Format inattendu pour les joueurs connectés.');
        return;
      }

      _connectedPlayersList = players.map<Map<String, dynamic>>((p) {
        final user = p['user'];
        final team = p['team'];
        return {
          'id': user['id'],
          'username': user['username'],
          'teamId': team?['id'],
          'teamName': team?['name'],
        };
      }).toList();

      _connectedPlayers = _connectedPlayersList.length;

      print('✅ [RESTORE] Joueurs restaurés : $_connectedPlayers');
      notifyListeners();
    } catch (e, stack) {
      print('❌ [RESTORE] Erreur : $e');
      print('📌 Stacktrace : $stack');
    }
  }

  void setTerrainOpen(bool isOpen) {
    _isTerrainOpen = isOpen;

    if (!isOpen) {
      // Réinitialiser les valeurs si on ferme le terrain
      _selectedScenarios = [];
      _gameDuration = null;
      _connectedPlayers = 0;
      _isGameRunning = false;
      _gameTimer?.cancel();
      _gameEndTime = null;
      _timeLeftDisplay = "00:00:00";
      _connectedPlayersList.clear();
    }

    notifyListeners();
  }

  void updateConnectedPlayersList(List<Map<String, dynamic>> newList) {
    _connectedPlayersList = newList;
    _connectedPlayers = _connectedPlayersList.length;
    notifyListeners();
  }
}
