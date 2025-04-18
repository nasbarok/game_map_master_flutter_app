import 'package:airsoft_game_map/models/field.dart';
import 'package:airsoft_game_map/services/auth_service.dart';
import 'package:airsoft_game_map/services/scenario/treasure_hunt/treasure_hunt_service.dart';
import 'package:airsoft_game_map/services/team_service.dart';
import 'package:airsoft_game_map/services/websocket_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import '../../models/game_map.dart';
import '../models/game_session.dart';
import '../models/scenario/scenario_dto.dart';
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
  DateTime? _gameStartTime;

  DateTime? get gameStartTime => _gameStartTime;
  late final ApiService _apiService;

  WebSocketService? _webSocketService;
  final TreasureHuntService _treasureHuntService;

  TeamService? _teamService;

  List<dynamic> pastFields = [];

  bool get isReady => _webSocketService != null;

  Field? get selectedField => _selectedMap?.field;

  GameSession? _currentGameSession;
  final _gameSessionController = StreamController<GameSession?>.broadcast();

  Stream<GameSession?> get gameSessionStream => _gameSessionController.stream;

  GameStateService(this._apiService, this._treasureHuntService);

  void dispose() {
    _gameTimer?.cancel();
    _gameSessionController.close(); // ✅ fermer aussi ce stream
    super.dispose();
  }

  void setTeamService(TeamService service) {
    _teamService = service;
  }

  void setWebSocketService(WebSocketService service) {
    _webSocketService = service;
  }

  void updateApiService(ApiService service) {
    _apiService = service;
  }

  void setGameRunning(bool bool) {
    _isGameRunning = bool;
    notifyListeners();
  }

  factory GameStateService.placeholder() {
    return GameStateService(
        ApiService.placeholder(), TreasureHuntService(ApiService.placeholder()))
      .._isTerrainOpen = false
      .._selectedMap = null
      .._selectedScenarios = []
      .._gameDuration = null
      .._connectedPlayers = 0
      .._isGameRunning = false
      .._gameEndTime = null
      .._timeLeftDisplay = "00:00:00"
      .._connectedPlayersList = [];
  }

  get gameStateService => null;

  // Méthodes pour mettre à jour l'état
  void selectMap(GameMap? map) {
    _selectedMap = map;
    notifyListeners();
  }

  Future<void> handleTerrainOpen(Field field, ApiService apiService) async {
    try {
      if (field.active == false) {
        print('ℹ️ [toggleTerrainOpen] Terrain fermé : ${field.name}');
        return;
      }
      _isTerrainOpen = true;

      if (_isTerrainOpen) {
        print('📡 [OPEN] Terrain en cours d’ouverture : ${field.name}');
        // Associer à la carte si besoin
        if (_selectedMap != null && _selectedMap!.field == null) {
          _selectedMap = _selectedMap!.copyWith(field: field);
        }

        // Charger joueurs connectés
        print('👥 [OPEN] Appel GET /fields/${field.id}/players');
        final players = await apiService.get('fields/${field.id}/players');
        if (players is List) {
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
          print('✅ [OPEN] Joueurs connectés restaurés ($_connectedPlayers)');
        }

        // Charger statut de jeu
        print('🎮 [OPEN] Appel GET /games/${field.id}/status');
        final gameStatus = await apiService.get('games/${field.id}/status');

        _isGameRunning = false;
        _gameStartTime = null;
        _gameEndTime = null;

        if (gameStatus['status'] == 'RUNNING' && gameStatus['active'] == true) {
          _isGameRunning = true;

          if (gameStatus['startTime'] != null) {
            _gameStartTime = DateTime.parse(gameStatus['startTime']);
          }

          if (gameStatus['endTime'] != null) {
            _gameEndTime = DateTime.parse(gameStatus['endTime']);
          } else if (_gameStartTime != null && _gameDuration != null) {
            _gameEndTime =
                _gameStartTime!.add(Duration(minutes: _gameDuration!));
          }

          _startGameTimer();
          print('✅ [OPEN] Partie en cours restaurée');
        }
      } else {
        // RESET si fermeture du terrain
        print('🔒 [CLOSE] Fermeture du terrain');
        _selectedScenarios = [];
        _gameDuration = null;
        _connectedPlayers = 0;
        _isGameRunning = false;
        _gameTimer?.cancel();
        _gameEndTime = null;
        _gameStartTime = null;
        _timeLeftDisplay = "00:00:00";
        _connectedPlayersList.clear();
      }

      notifyListeners();
    } catch (e, stack) {
      print('❌ [toggleTerrainOpen] Erreur : $e');
      print('📌 Stacktrace : $stack');
    }
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

  void _startGameTimer() {
    _gameTimer?.cancel();

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();

      // Cas sans fin de partie connue
      if (_gameStartTime == null) {
        _timeLeftDisplay = "∞";
        notifyListeners();
        return;
      }

      // Calculer _gameEndTime si possible
      if (_gameEndTime == null && _gameDuration != null) {
        _gameEndTime = _gameStartTime!.add(Duration(minutes: _gameDuration!));
      }

      // Si on a maintenant une _gameEndTime, on calcule le temps restant
      if (_gameEndTime != null) {
        final difference = _gameEndTime!.difference(now);

        if (difference.isNegative) {
          _timeLeftDisplay = "00:00:00";
          stopGame();
          return;
        }

        final hours = difference.inHours.toString().padLeft(2, '0');
        final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');

        _timeLeftDisplay = "$hours:$minutes:$seconds";
      } else {
        _timeLeftDisplay = "∞";
      }

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
    print(
        '📈 Ajout du joueur depuis payload : ${payload['fromUsername']} (ID: ${payload['fromUserId']})');

    addConnectedPlayer({
      'id': payload['fromUserId'],
      'username': payload['fromUsername'] ?? 'Joueur',
      'teamId': payload['teamId'],
      'teamName': payload['teamName'],
    });
  }

  // Nouvelles méthodes pour gérer la liste des joueurs connectés
  void addConnectedPlayer(Map<String, dynamic> player) {
    final existingIndex =
        _connectedPlayersList.indexWhere((p) => p['id'] == player['id']);
    print(
        '🔍 Vérification si ${player['username']} (ID: ${player['id']}) est déjà dans la liste → index: $existingIndex');

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
    print(
        '🗑️ [GameStateService] [removeConnectedPlayer] Tentative de suppression du joueur avec ID: $playerId');

    // Tentative de suppression
    final initialLength = _connectedPlayersList.length;
    _connectedPlayersList =
        _connectedPlayersList.where((p) => p['id'] != playerId).toList();
    final finalLength = _connectedPlayersList.length;

    if (finalLength < initialLength) {
      print(
          '✅ [GameStateService] [removeConnectedPlayer] Joueur ID $playerId supprimé avec succès.');
    } else {
      print(
          '⚠️ [GameStateService] [removeConnectedPlayer] Aucun joueur trouvé avec ID $playerId. Pas de suppression.');
    }

    _connectedPlayers = _connectedPlayersList.length;

    // Notifier les listeners (UI)
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
    print('🔄 Réinitialisation de l\'état du systeme du jeu');
    _isTerrainOpen = false;
    _selectedMap = null;
    _selectedScenarios = [];
    _gameDuration = null;
    _connectedPlayers = 0;
    _isGameRunning = false;
    _gameEndTime = null;
    _timeLeftDisplay = "00:00:00";
    _connectedPlayersList.clear();

    if (_gameTimer != null) {
      _gameTimer!.cancel();
      _gameTimer = null;
    }

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
      if (activeFieldResponse is Map &&
          activeFieldResponse['active'] == false) {
        print('ℹ️ [RESTORE] Aucun terrain actif trouvé.');
        return;
      }

      final field = Field.fromJson(activeFieldResponse['field']);

      if (field.active == false) {
        print('ℹ️ [RESTORE]  terrain fermé.');
        return;
      }

      print('✅ [RESTORE] Terrain actif : ${field.name} (ID: ${field.id}');

      // Étape 2 : Carte liée
      print('🔎 [RESTORE] Appel GET /maps?fieldId=${field.id}');
      final map = await apiService.get('maps?fieldId=${field.id}');
      if (map == null) {
        print('⚠️ [RESTORE] Carte non trouvée (null)');
        return;
      }
      print('📦 [RESTORE] Réponse cartes : $map');

      final selectedMap = GameMap.fromJson(map);
      print(
          '✅ [RESTORE] Carte sélectionnée : ${selectedMap.name} (ID: ${selectedMap.id})');
      selectMap(selectedMap);

      // Vérifier si l'utilisateur est un host ou un gamer
      final isHost =
          apiService.authService.currentUser?.hasRole('HOST') ?? false;
      final userId = apiService.authService.currentUser?.id;

      _isTerrainOpen = true;

      if (_webSocketService == null) {
        print('❌ [RESTORE] WebSocketService est null !');
      } else {
        if (!_webSocketService!.isConnected) {
          print('⏳ [RESTORE] En attente de connexion WebSocket...');
          await _webSocketService!.connect();

          // Petite boucle d’attente si le connect() est asynchrone mais non bloquant
          int attempts = 0;
          while (!_webSocketService!.isConnected && attempts < 10) {
            await Future.delayed(const Duration(milliseconds: 300));
            attempts++;
          }
        }

        if (_webSocketService!.isConnected) {
          final success = _webSocketService!.subscribeToField(field.id!);
          print(success
              ? '🔗 Abonnement WebSocket au terrain ${field.id} réussi.'
              : '⚠️ Échec de l’abonnement WebSocket au terrain ${field.id}.');
        } else {
          print(
              '❌ [RESTORE] Connexion WebSocket toujours impossible après tentative.');
        }
      }

      try {
        print(
            '🔎 [RESTORE] Vérification du statut de la partie via le terrain');
        final gameStatus = await apiService.get('games/${field.id}/status');

        // S'assurer que isGameRunning est false par défaut
        _isGameRunning = false;

        if (gameStatus['status'] == 'RUNNING' && gameStatus['active'] == true) {
          _isGameRunning = true;

          if (gameStatus['startTime'] != null) {
            final startTimeStr = gameStatus['startTime'];
            _gameStartTime = DateTime.parse(startTimeStr);
          }

          if (gameStatus['endTime'] != null) {
            final endTimeStr = gameStatus['endTime'];
            _gameEndTime = DateTime.parse(endTimeStr);
          } else if (_gameStartTime != null && _gameDuration != null) {
            _gameEndTime =
                _gameStartTime!.add(Duration(minutes: _gameDuration!));
          }

          _startGameTimer();
        }

        print(
            '✅ [RESTORE] Statut de jeu : ${_isGameRunning ? "EN COURS" : "ARRÊTÉ"}');
      } catch (e) {
        print(
            '⚠️ [RESTORE] Erreur lors de la vérification du statut de jeu: $e');
        _isGameRunning = false;
      }

      // Étape 3 : Récupération des scénarios sélectionnés
      try {
        print('🔎 [RESTORE] Appel GET /fields/${field.id}/scenarios');
        final scenariosResponse =
            await apiService.get('fields/${field.id}/scenarios');
        print('📦 [RESTORE] Réponse scénarios : $scenariosResponse');

        if (scenariosResponse == null || scenariosResponse is! List) {
          print('⚠️ [RESTORE] Format inattendu pour les scénarios.');
        } else {
          _selectedScenarios =
              scenariosResponse.map<ScenarioDTO>((scenarioJson) {
            return ScenarioDTO.fromJson(
                Map<String, dynamic>.from(scenarioJson));
          }).toList();

          print(
              '✅ [RESTORE] Scénarios restaurés : ${_selectedScenarios?.length}');
        }
      } catch (e) {
        print('⚠️ [RESTORE] Erreur lors de la récupération des scénarios : $e');
      }

      // Étape 4 : Joueurs connectés
      print('🔎 [RESTORE] Appel GET /fields/${selectedMap.field?.id}/players');
      final players =
          await apiService.get('fields/${selectedMap.field?.id}/players');
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

      _teamService?.loadTeams(selectedMap.id!);
      if (_teamService!.teams.isNotEmpty) {
        print('✅ [RESTORE] Équipes restaurées : ${_teamService?.teams.length}');
      } else {
        print('⚠️ [RESTORE] Aucune équipe trouvée.');
      }

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

  Future<void> connectHostToField() async {
    if (!_isTerrainOpen || _selectedMap == null || _selectedMap!.field == null)
      return;

    final authService = _apiService.authService;
    if (authService.currentUser == null ||
        !authService.currentUser!.hasRole('HOST')) return;

    try {
      final fieldId = _selectedMap!.field!.id;
      final userId = authService.currentUser!.id;

      print('🔄 Connexion automatique du host au terrain');
      await _apiService.post('fields/$fieldId/join', {});

      // Recharger les joueurs connectés
      await loadConnectedPlayers();

      print('✅ Host connecté au terrain');
    } catch (e) {
      print('❌ Erreur lors de la connexion automatique du host: $e');
    }
  }

  Future<void> loadConnectedPlayers() async {
    if (_selectedMap == null || _selectedMap!.field == null) return;

    try {
      final fieldId = _selectedMap!.field!.id;
      final players = await _apiService.get('fields/$fieldId/players');

      if (players == null || players is! List) {
        print('⚠️ Format inattendu pour les joueurs connectés.');
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
      print('✅ Joueurs connectés chargés : $_connectedPlayers');
      notifyListeners();
    } catch (e) {
      print('❌ Erreur lors du chargement des joueurs connectés: $e');
    }
  }

  Future<GameSession?> getCurrentGameSession() async {
    try {
      final response =
          await _apiService.get('game/current-session/${selectedField?.id}');
      if (response != null) {
        _currentGameSession = GameSession.fromJson(response);
        _gameSessionController.add(_currentGameSession);
        return _currentGameSession;
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la session de jeu: $e');
      return null;
    }
  }

  Future<bool> isGameActive(int scenarioId) async {
    try {
      final session = await getCurrentGameSession();
      if (session == null || !session.active) {
        return false;
      }

      // Vérifier si le scénario est actif
      final scenario =
          await _treasureHuntService.getTreasureHuntScenario(scenarioId);
      return scenario.active;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'état du jeu: $e');
      return false;
    }
  }

  Future<bool> startGame(int gameId) async {
    if (!_isTerrainOpen ||
        _selectedScenarios == null ||
        _selectedScenarios!.isEmpty) {
      return false; // Ne rien faire si les conditions ne sont pas remplies
    }

    _isGameRunning = true;
    if (_gameDuration != null) {
      _gameEndTime = DateTime.now().add(Duration(minutes: _gameDuration!));
      _startGameTimer();
    } else {
      _timeLeftDisplay = "∞"; // Durée illimitée
    }

    if (gameId == 0) {
      print('lancement de la partie côté serveur');
      try {
        final gameState = GetIt.I<GameStateService>();
        final apiService = GetIt.I<ApiService>();

        final fieldId = gameState.selectedMap?.field?.id;
        final scenarioId = gameState.selectedScenarios?.first.scenario.id;

        if (fieldId == null || scenarioId == null) {
          debugPrint('Impossible de démarrer : fieldId ou scenarioId null');
          return false;
        }

        final response = await apiService.post('game/$fieldId/start', {});
        if (response != null) {
          debugPrint('✅ Partie démarrée côté serveur.');
          return true;
        }
        return false;
      } catch (e) {
        debugPrint('Erreur lors du démarrage du jeu: $e');
        return false;
      }
    } else {
      try {
        final response = await _apiService.post('game/session/$gameId', {});
        if (response != null) {
          return true;
        }
        return false;
      } catch (e) {
        debugPrint('Erreur lors du démarrage du jeu: $e');
        return false;
      }
    }
  }

  Future<bool> endGame(int gameId) async {
    try {
      final response = await _apiService.post('games/$gameId/end', {});
      if (response != null) {
        _currentGameSession = null;
        _gameSessionController.add(null);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la fin du jeu: $e');
      return false;
    }
  }
}
