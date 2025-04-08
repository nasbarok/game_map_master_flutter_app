import 'dart:async';
import 'dart:convert';
import 'package:airsoft_game_map/services/team_service.dart';
import 'package:airsoft_game_map/widgets/websocket_message_handler.dart';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:stomp_dart_client/stomp_handler.dart';
import '../models/websocket/field_closed_message.dart';
import '../models/websocket/field_opened_message.dart';
import '../models/websocket/game_ended_message.dart';
import '../models/websocket/game_started_message.dart';
import '../models/websocket/player_connected_message.dart';
import '../models/websocket/player_disconnected_message.dart';
import '../models/websocket/team_deleted_message.dart';
import '../models/websocket/team_update_message.dart';
import '../models/websocket/websocket_message.dart';
import 'auth_service.dart';
import 'game_state_service.dart';

class WebSocketService with ChangeNotifier {
  static const String wsUrl = 'ws://192.168.3.23:8080/ws';

  AuthService? _authService;
  GameStateService? _gameStateService;
  TeamService? _teamService;
  WebSocketMessageHandler? _webSocketMessageHandler;

  void setMessageHandler(WebSocketMessageHandler handler) {
    _webSocketMessageHandler = handler;
  }

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

  // Garder une trace des abonnements actifs avec leurs callbacks
  final Map<String, StompUnsubscribe> _activeSubscriptions = {};

  WebSocketService(this._authService, this._gameStateService, this._teamService,
      this._navigatorKey);

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
    final fieldId = _gameStateService?.selectedField?.id;

    _stompClient = StompClient(
      config: StompConfig(
        url: uri,
        onConnect: (StompFrame frame) {
          _isConnected = true;
          _connecting = false;

          // ✅ Abonnement au canal utilisateur
          subscribe('/topic/user/$userId');

          if (fieldId != null) {
            print('📡 Abonnement au terrain /topic/field/$fieldId');
            subscribeToField(fieldId);
          }else{
            print('⚠️ Pas de terrain sélectionné pour l\'abonnement');
          }
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

    final unsubscribe = _stompClient!.subscribe(
      destination: destination,
      callback: _onMessageReceived,
    );

    // Stocker la fonction de désabonnement
    _activeSubscriptions[destination] = unsubscribe;
    _subscriptions.add(destination);
    print('📡 Abonné à $destination');
  }

  void unsubscribe(String destination) {
    if (!_isConnected || _stompClient == null) return;

    // Utiliser la fonction de désabonnement stockée
    final unsubscribe = _activeSubscriptions[destination];
    if (unsubscribe != null) {
      unsubscribe();
      _activeSubscriptions.remove(destination);
      _subscriptions.remove(destination);
      print('📡 Désabonné de $destination');
    }
  }

  bool subscribeToField(int fieldId) {
    final topic = '/topic/field/$fieldId';

    if (!_isConnected || _stompClient == null) {
      print('❌ Impossible de s’abonner à $topic : non connecté');
      return false;
    }

    if (_subscriptions.contains(topic)) {
      print('ℹ️ Déjà abonné à $topic');
      return true;
    }

    try {
      final unsubscribe = _stompClient!.subscribe(
        destination: topic,
        callback: _onMessageReceived,
      );

      _activeSubscriptions[topic] = unsubscribe;
      _subscriptions.add(topic);

      print('✅ Abonnement réussi à $topic');
      return true;
    } catch (e) {
      print('❌ Erreur lors de l’abonnement à $topic : $e');
      return false;
    }
  }

  void unsubscribeFromField(int fieldId) {
    print('📡 Désabonné du terrain /topic/field/$fieldId');
    unsubscribe('/topic/field/$fieldId');
  }

  void _onMessageReceived(StompFrame frame) {
    try {
      if (frame.body == null) return;

      final Map<String, dynamic> json = jsonDecode(frame.body!);
      print('📨 [websocket_message] [_onMessageReceived] Message STOMP brut reçu : ${json['type']}');
      print('📨 [websocket_message] [_onMessageReceived] Contenu brut complet : $json'); // 👈 Ajoute cette ligne
      try {
        final message = WebSocketMessage.fromJson(json);
        _messageController.add(message);

        //connecter le StreamController aux handlers
        final context = _navigatorKey.currentContext;
        if (context != null) {
          _webSocketMessageHandler?.handleWebSocketMessage(message, context);
        } else {
          print('⚠️ [websocket_message] [_onMessageReceived] Aucun contexte disponible pour traiter le message WebSocket');
        }
      } catch (e) {
        print('❌ [websocket_message] [_onMessageReceived] Type de message non géré ou parsing échoué : $e');
      }
    } catch (e) {
      print('❌ [websocket_message] [_onMessageReceived] Erreur de parsing WebSocket JSON : $e');
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

// méthode disconnect pour nettoyer correctement
  void disconnect() {
    // Désabonner de tous les topics
    _activeSubscriptions.forEach((destination, unsubscribe) {
      unsubscribe();
    });
    _activeSubscriptions.clear();
    _subscriptions.clear();

    _stompClient?.deactivate();
    _isConnected = false;
    _connecting = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
