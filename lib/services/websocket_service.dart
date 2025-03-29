import 'dart:async';
import 'dart:convert';
import 'package:airsoft_game_map/services/team_service.dart';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'auth_service.dart';
import 'game_state_service.dart';

class WebSocketService with ChangeNotifier {
  static const String wsUrl = 'ws://192.168.3.23:8080/ws';

  AuthService? _authService;
  GameStateService? _gameStateService;
  TeamService? _teamService;

  StompClient? _stompClient;
  bool _isConnected = false;
  bool _connecting = false;

  final StreamController<Map<String, dynamic>> _messageStreamController =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;
  bool get isConnected => _isConnected;

  WebSocketService(this._authService, this._gameStateService, this._teamService);

  void updateAuthService(AuthService authService) {
    _authService = authService;
  }

  Future<void> connect() async {
    if (_connecting || _isConnected || _authService?.token == null || _authService?.currentUser?.id == null) {
      print('⚠️ Connexion déjà en cours ou établie, on ne relance pas.');
      return;
    }
    _connecting = true; // ← ✅ empêcher un double appel

    final token = _authService!.token!;
    final userId = _authService!.currentUser!.id;
    final uri = '$wsUrl?token=$token';

    _stompClient = StompClient(
      config: StompConfig(
        url: uri,
        onConnect: (StompFrame frame) {
          _isConnected = true;
          notifyListeners();
          // ✅ Abonnement au canal utilisateur
          _stompClient!.subscribe(
            destination: '/topic/user/$userId',
            callback: (frame) {
              try {
                final decoded = jsonDecode(frame.body!) as Map<String, dynamic>;
                print('✅ Message STOMP reçu: $decoded'); // Log pour débogage
                _messageStreamController.add(decoded);
              } catch (e) {
                print('Erreur de décodage STOMP : $e');
              }
            },
          );

          print('✅ STOMP connecté à $uri et abonné à /topic/user/$userId');
        },
        beforeConnect: () async {
          print('🔄 Connexion STOMP en cours...');
        },
        onDisconnect: (_) {
          print('🔌 Déconnecté de STOMP');
          _isConnected = false;
          notifyListeners();
          _reconnect();
        },
        onWebSocketError: (error) {
          print('🛑 Erreur WebSocket : $error');
          _isConnected = false;
          notifyListeners();
          _reconnect();
        },
        onStompError: (frame) {
          print('💥 Erreur STOMP : ${frame.body}');
          _isConnected = false;
          notifyListeners();
        },
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _stompClient!.activate();
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected) {
        connect();
      }
    });
  }


  Future<void> sendMessage(String destination, Map<String, dynamic> message) async {
    if (_isConnected && _stompClient != null) {
      try {
        _stompClient!.send(
          destination: destination,
          body: jsonEncode(message),
        );
      } catch (e) {
        print('Erreur lors de l\'envoi STOMP : $e');
      }
    } else {
      print('❌ Impossible d\'envoyer le message : non connecté');
      await connect();
      if (_isConnected) {
        _stompClient!.send(destination: destination, body: jsonEncode(message));
      } else {
        print('❌ La reconnexion a échoué, message non envoyé');
      }
    }
  }


  void subscribeToField(int fieldId) {
    if (!_isConnected || _stompClient == null) return;

    _stompClient!.subscribe(
      destination: '/topic/field/$fieldId',
      callback: _onMessageReceived,
    );
    print('📡 Abonné au terrain /topic/field/$fieldId');
  }

  void _onMessageReceived(StompFrame frame) {
    try {
      if (frame.body == null) return;
      final decoded = jsonDecode(frame.body!) as Map<String, dynamic>;
      print('📨 Message STOMP reçu : ${decoded['type']}');
      _handleWebSocketMessage(decoded);
    } catch (e) {
      print('❌ Erreur de parsing WebSocket : $e');
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    final type = message['type'];
    final payload = message['payload'];

    print('📨 Message WebSocket reçu : type=$type, payload=$payload');

    switch (type) {
      case 'PLAYER_CONNECTED':
        print('🟢 Traitement de PLAYER_CONNECTED');
        _handlePlayerConnected(payload);
        break;
      case 'PLAYER_DISCONNECTED':
        print('🔴 Traitement de PLAYER_DISCONNECTED');
        _handlePlayerDisconnected(payload);
        break;
      case 'TEAM_UPDATED':
        print('🟡 Traitement de TEAM_UPDATED');
        _handleTeamUpdated(payload);
        break;
      case 'TEAM_DELETED':
        print('⚫️ Traitement de TEAM_DELETED');
        _handleTeamDeleted(payload);
        break;
      default:
        print('⚠️ Type de message WebSocket non géré : $type');
        break;
    }
  }

  void _handlePlayerConnected(Map<String, dynamic> content) {
    final player = content['player'];
    print('👤 Nouveau joueur connecté : $player');

    final list = List<Map<String, dynamic>>.from(_gameStateService!.connectedPlayersList);
    final index = list.indexWhere((p) => p['id'] == player['id']);

    if (index >= 0) {
      print('🔁 Mise à jour du joueur existant avec ID=${player['id']}');
      list[index] = {
        ...list[index],
        'teamId': player['teamId'],
        'teamName': player['teamName'],
      };
    } else {
      print('➕ Ajout d\'un nouveau joueur avec ID=${player['id']}');
      list.add(player);
    }

    _gameStateService!.updateConnectedPlayersList(list);
    _teamService!.synchronizePlayersWithTeams();
  }

  void _handlePlayerDisconnected(Map<String, dynamic> content) {
    final userId = content['userId'];
    print('👋 Joueur déconnecté : ID=$userId');

    final list = List<Map<String, dynamic>>.from(_gameStateService!.connectedPlayersList);
    list.removeWhere((p) => p['id'] == userId);

    _gameStateService!.updateConnectedPlayersList(list);
    _teamService!.synchronizePlayersWithTeams();
  }

  void _handleTeamUpdated(Map<String, dynamic> content) {
    //@todo faire passer l'objet team pour toutes les modifs
    final teamId = content['teamId'];
    final newName = content['teamName'];
    
    print('✏️ Mise à jour du nom de l\'équipe ID=$teamId -> $newName');

    _teamService!.updateTeamName(teamId, newName);
  }

  void _handleTeamDeleted(Map<String, dynamic> content) {
    final teamId = content['teamId'];
    _teamService!.deleteTeam(teamId);
  }

  void disconnect() {
    _stompClient?.deactivate();
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _messageStreamController.close();
    super.dispose();
  }
}