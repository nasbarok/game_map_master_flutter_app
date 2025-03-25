import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'auth_service.dart';

class WebSocketService with ChangeNotifier {
  static const String wsUrl = 'ws://192.168.3.23:8080/ws';

  AuthService? _authService;
  StompClient? _stompClient;
  bool _isConnected = false;

  final StreamController<Map<String, dynamic>> _messageStreamController =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;
  bool get isConnected => _isConnected;

  WebSocketService(this._authService);

  void updateAuthService(AuthService authService) {
    _authService = authService;
  }

  Future<void> connect() async {
    if (_isConnected || _authService?.token == null || _authService?.currentUser?.id == null) return;

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