import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'auth_service.dart';

class WebSocketService with ChangeNotifier {
  static const String wsUrl = 'ws://192.168.3.23:8080/ws';

  AuthService? _authService;

  WebSocketChannel? _channel;
  bool _isConnected = false;

  final StreamController<Map<String, dynamic>> _messageStreamController =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;
  bool get isConnected => _isConnected;

  WebSocketService(this._authService);

  /// Permet de mettre à jour `authService` depuis ChangeNotifierProxyProvider
  void updateAuthService(AuthService authService) {
    _authService = authService;
  }

  Future<void> connect() async {
    if (_isConnected || _authService?.token == null) return;

    try {
      final token = _authService!.token!;
      final uri = Uri.parse('$wsUrl?token=$token');

      _channel = IOWebSocketChannel.connect(uri);
      _isConnected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      _channel!.stream.listen(
            (dynamic message) {
          final decoded = json.decode(message as String) as Map<String, dynamic>;
          _messageStreamController.add(decoded);
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _isConnected = false;
          notifyListeners();
          _reconnect();
        },
        onDone: () {
          print('WebSocket Connection Closed');
          _isConnected = false;
          notifyListeners();
          _reconnect();
        },
      );

      print('WebSocket Connected to $uri');
    } catch (e) {
      print('WebSocket Connection Error: $e');
      _isConnected = false;
      notifyListeners();
      _reconnect();
    }
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    notifyListeners();
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(json.encode(message));
    } else {
      print('Cannot send message: WebSocket not connected');
      connect();
    }
  }

  @override
  void dispose() {
    disconnect();
    _messageStreamController.close();
    super.dispose();
  }
}