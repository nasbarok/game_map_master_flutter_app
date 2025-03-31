import 'dart:async';
import 'dart:convert';
import 'package:airsoft_game_map/services/team_service.dart';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../models/websocket/websocket_message.dart';
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

  // Utiliser un StreamController typé
  final StreamController<WebSocketMessage> _messageController =
      StreamController<WebSocketMessage>.broadcast();

  // Exposer le stream pour que d'autres services puissent s'y abonner
  Stream<WebSocketMessage> get messageStream => _messageController.stream;
  final GlobalKey<NavigatorState> _navigatorKey;

  // Garder une trace des abonnements
  final Set<String> _subscriptions = {};

  WebSocketService(this._authService, this._gameStateService, this._teamService, this._navigatorKey);

  bool get isConnected => _isConnected;

  void updateAuthService(AuthService authService) {
    _authService = authService;
  }

  Future<void> connect() async {
    if (_connecting ||
        _isConnected ||
        _authService?.token == null ||
        _authService?.currentUser?.id == null) {
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
          _connecting = false;

          // ✅ Abonnement au canal utilisateur
          subscribe('/topic/user/$userId');

          print('✅ STOMP connecté à $uri et abonné à /topic/user/$userId');
        },
        beforeConnect: () async {
          print('🔄 Connexion STOMP en cours...');
        },
        onDisconnect: (_) {
          print('🔌 Déconnecté de STOMP');
          _isConnected = false;
          _connecting = false;
          _reconnect();
        },
        onWebSocketError: (error) {
          print('🛑 Erreur WebSocket : $error');
          _isConnected = false;
          _connecting = false;
          _reconnect();
        },
        onStompError: (frame) {
          print('💥 Erreur STOMP : ${frame.body}');
          _isConnected = false;
          _connecting = false;
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
      if (!_isConnected && !_connecting) {
        connect();
      }
    });
  }

  void subscribe(String destination) {
    if (!_isConnected || _stompClient == null) {
      print('⚠️ Impossible de s\'abonner : non connecté');
      return;
    }

    if (_subscriptions.contains(destination)) {
      print('ℹ️ Déjà abonné à $destination');
      return;
    }

    _stompClient!.subscribe(
      destination: destination,
      callback: _onMessageReceived,
    );

    _subscriptions.add(destination);
    print('📡 Abonné à $destination');
  }

  void unsubscribe(String destination) {
    if (!_isConnected || _stompClient == null) return;

    // StompDart ne fournit pas de méthode pour se désabonner d'un topic spécifique
    // On garde juste la trace pour ne pas s'abonner à nouveau
    _subscriptions.remove(destination);
    print('📡 Désabonné de $destination');
  }

  void subscribeToField(int fieldId) {
    print('📡 Abonné au terrain /topic/field/$fieldId');
    subscribe('/topic/field/$fieldId');
  }

  void unsubscribeFromField(int fieldId) {
    print('📡 Désabonné du terrain /topic/field/$fieldId');
    unsubscribe('/topic/field/$fieldId');
  }

  void _onMessageReceived(StompFrame frame) {
    try {
      if (frame.body == null) return;

      final Map<String, dynamic> json = jsonDecode(frame.body!);
      print('📨 Message STOMP brut reçu : ${json['type']}');

      try {
        final message = WebSocketMessage.fromJson(json);
        _messageController.add(message);
      } catch (e) {
        print('⚠️ Type de message non géré ou parsing échoué : $e');
      }
    } catch (e) {
      print('❌ Erreur de parsing WebSocket JSON : $e');
    }
  }

  Future<void> sendMessage(String destination, WebSocketMessage message) async {
    if (!_isConnected || _stompClient == null) {
      print('❌ Impossible d\'envoyer le message : non connecté');
      await connect();
      if (!_isConnected) {
        print('❌ La reconnexion a échoué, message non envoyé');
        return;
      }
    }
    try {
      _stompClient!.send(
        destination: destination,
        body: jsonEncode(message.toJson()),
      );
      print('📤 Message envoyé à $destination : ${message.type}');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi STOMP : $e');
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

    final list = List<Map<String, dynamic>>.from(
        _gameStateService!.connectedPlayersList);
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

    final list = List<Map<String, dynamic>>.from(
        _gameStateService!.connectedPlayersList);
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
    _connecting = false;
    _subscriptions.clear();
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
