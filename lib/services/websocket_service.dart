import 'dart:async';
import 'dart:convert';
import 'package:airsoft_game_map/services/team_service.dart';
import 'package:airsoft_game_map/widgets/websocket_message_handler.dart';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../models/websocket/field_closed_message.dart';
import '../models/websocket/field_opened_message.dart';
import '../models/websocket/game_ended_message.dart';
import '../models/websocket/game_session_started_message.dart';
import '../models/websocket/player_connected_message.dart';
import '../models/websocket/player_disconnected_message.dart';
import '../models/websocket/player_position_message.dart';
import '../models/websocket/team_deleted_message.dart';
import '../models/websocket/team_update_message.dart';
import '../models/websocket/websocket_message.dart';
import 'auth_service.dart';
import 'game_state_service.dart';

class WebSocketService with ChangeNotifier {
  static const String wsUrl = 'ws://10.0.2.2:8080/ws';

  AuthService? _authService;
  GameStateService? _gameStateService;
  TeamService? _teamService;
  WebSocketMessageHandler? _webSocketMessageHandler;
  final GlobalKey<NavigatorState> _navigatorKey;

  final _connectionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  final _messageController = StreamController<WebSocketMessage>.broadcast();

  Stream<WebSocketMessage> get messageStream => _messageController.stream;

  StompClient? _stompClient;
  bool _isConnected = false;
  bool _connecting = false;

  bool get isConnected => _isConnected;

  final Set<String> _subscriptions = {};
  final Map<String, void Function()> _activeSubscriptions = {};

  // Liste des callbacks pour les mises à jour de position
  final List<Function(Map<String, dynamic>)> _positionCallbacks = [];

  WebSocketService(this._authService, this._gameStateService, this._teamService,
      this._navigatorKey);

  void setMessageHandler(WebSocketMessageHandler handler) {
    _webSocketMessageHandler = handler;
  }

  Future<void> connect() async {
    if (_connecting ||
        _isConnected ||
        _authService?.token == null ||
        _authService?.currentUser?.id == null) {
      print('⚠️ Connexion déjà en cours ou établie, on ne relance pas.');
      return;
    }
    _connecting = true;

    final token = _authService!.token!;
    final userId = _authService!.currentUser!.id!;
    final uri = '$wsUrl?token=$token';
    final fieldId = _gameStateService?.selectedField?.id;

    _stompClient = StompClient(
      config: StompConfig(
        url: uri,
        beforeConnect: () async => print('🔄 Connexion STOMP en cours...'),
        onConnect: (frame) => _onConnect(frame, userId, fieldId),
        onDisconnect: (frame) => _onDisconnect(),
        onWebSocketError: (error) => _onError(error),
        onStompError: (frame) => _onError(frame.body),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame, int userId, int? fieldId) {
    _isConnected = true;
    _connecting = false;
    _connectionStatusController.add(true);

    subscribe('/topic/user/$userId');

    if (fieldId != null) {
      subscribeToField(fieldId);
    } else {
      print('⚠️ Pas de terrain sélectionné pour l\'abonnement');
    }

    print('✅ STOMP connecté et abonné au canal utilisateur.');
  }

  void _onDisconnect() {
    print('🔌 Déconnecté de STOMP');
    _isConnected = false;
    _connecting = false;
    _connectionStatusController.add(false);
    _reconnect();
  }

  void _onError(dynamic error) {
    print('🛑 Erreur WebSocket : $error');
    _isConnected = false;
    _connecting = false;
    _connectionStatusController.add(false);
    _reconnect();
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected && !_connecting) {
        connect();
      }
    });
  }

  void subscribe(String destination) {
    if (!_isConnected || _stompClient == null) return;

    if (_subscriptions.contains(destination)) return;

    final unsubscribe = _stompClient!.subscribe(
      destination: destination,
      callback: _onMessageReceived,
    );

    _activeSubscriptions[destination] = unsubscribe;
    _subscriptions.add(destination);
  }

  void unsubscribe(String destination) {
    if (!_isConnected || _stompClient == null) return;

    final unsubscribe = _activeSubscriptions[destination];
    if (unsubscribe != null) {
      unsubscribe();
      _activeSubscriptions.remove(destination);
      _subscriptions.remove(destination);
    }
  }

  bool subscribeToField(int fieldId) {
    final topic = '/topic/field/$fieldId';

    if (!_isConnected || _stompClient == null) return false;

    if (_subscriptions.contains(topic)) return true;

    try {
      final unsubscribe = _stompClient!.subscribe(
        destination: topic,
        callback: _onMessageReceived,
      );
      _activeSubscriptions[topic] = unsubscribe;
      _subscriptions.add(topic);
      return true;
    } catch (e) {
      print('❌ Erreur abonnement field : $e');
      return false;
    }
  }

  void unsubscribeFromField(int fieldId) {
    unsubscribe('/topic/field/$fieldId');
  }

  void _onMessageReceived(StompFrame frame) {
    try {
      if (frame.body == null) return;
      print('📩 Message reçu : ${frame.body}');
      final Map<String, dynamic> json = jsonDecode(frame.body!);
      final message = WebSocketMessage.fromJson(json);
      _messageController.add(message);

      final context = _navigatorKey.currentContext;
      if (context != null) {
        _webSocketMessageHandler?.handleWebSocketMessage(message, context);
      } else {
        print('⚠️ Aucun contexte pour traiter le message WebSocket');
      }
    } catch (e) {
      print('❌ Erreur traitement WebSocket : $e');
    }
  }

  Future<void> sendMessage(String destination, WebSocketMessage message) async {
    if (!_isConnected || _stompClient == null) {
      await connect();
      if (!_isConnected) {
        print('❌ Impossible d\'envoyer le message, WebSocket non connecté');
        return;
      }
    }
    try {
      _stompClient!.send(
        destination: destination,
        body: jsonEncode(message.toJson()),
      );
    } catch (e) {
      print('❌ Erreur envoi STOMP : $e');
    }
  }

  /// Enregistre un callback pour les mises à jour de position
  ///
  /// @param callback Fonction à appeler lorsqu'une mise à jour de position est reçue
  void registerOnPlayerPositionUpdate(Function(Map<String, dynamic>) callback) {
    // Ajouter le callback à la liste
    _positionCallbacks.add(callback);

    // Si déjà connecté et abonné à une session de jeu, s'abonner au topic des positions
    if (isConnected && _gameStateService?.activeGameSession?.id != null) {
      _subscribeToPositionUpdates(_gameStateService!.activeGameSession!.id!);
    }
  }

  /// Envoie une position de joueur via WebSocket
  ///
  /// @param gameSessionId Identifiant de la session de jeu
  /// @param latitude Latitude de la position
  /// @param longitude Longitude de la position
  /// @param teamId Identifiant de l'équipe (optionnel)
  /// Envoie une position via WebSocket en utilisant le topic field centralisé
  void sendPlayerPosition(int fieldId, int gameSessionId, double latitude, double longitude, int? teamId) {
    if (!isConnected || _authService?.currentUser?.id == null) {
      print('❌ Impossible d\'envoyer la position, WebSocket non connecté ou utilisateur non authentifié');
      return;
    }

    final userId = _authService!.currentUser!.id!;

    final message = PlayerPositionMessage(
      senderId: userId,
      latitude: latitude,
      longitude: longitude,
      gameSessionId: gameSessionId,
      teamId: teamId,
    );

    final destination = '/app/field/$fieldId';

    try {
      const encoder = JsonEncoder.withIndent('  ');
      print('🧾 [WebSocketService] [sendPlayerPosition] Message envoyé (PlayerPositionMessage) :');
      print(encoder.convert(message.toJson()));

      sendMessage(destination, message);

      // 🔍 Ajout des logs complets sans toucher au comportement existant
      print('📡 [WebSocketService] [sendPlayerPosition] Envoi WebSocket vers $destination');
      print('🧾 [WebSocketService] [sendPlayerPosition] Message PlayerPositionMessage:\n${jsonEncode(message.toJson())}');
    } catch (e) {
      print('❌ [WebSocketService] [sendPlayerPosition] Erreur lors de l\'envoi de la position: $e');
    }
  }


  /// S'abonne aux mises à jour de position pour une session de jeu
  ///
  /// @param gameSessionId Identifiant de la session de jeu
  void _subscribeToPositionUpdates(int gameSessionId) {
    if (!isConnected) return;

    _stompClient?.subscribe(
      destination: '/topic/field/{fieldId}//$gameSessionId/positions',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!);

            // Notifier les callbacks enregistrés
            for (var callback in _positionCallbacks) {
              callback(data);
            }
          } catch (e) {
            print('Erreur lors du traitement de la mise à jour de position: $e');
          }
        }
      },
    );
  }

  /// Méthode à appeler dans onGameSessionConnected pour s'abonner aux positions
  void setupPositionUpdates(int gameSessionId) {
    _subscribeToPositionUpdates(gameSessionId);
  }

  void disconnect() {
    _activeSubscriptions
        .forEach((destination, unsubscribe) => unsubscribe?.call());
    _activeSubscriptions.clear();
    _subscriptions.clear();

    _stompClient?.deactivate();
    _isConnected = false;
    _connecting = false;
    _connectionStatusController.add(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStatusController.close();
  }
}
