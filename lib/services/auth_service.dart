import 'dart:convert';
import 'package:game_map_master_flutter_app/services/game_state_service.dart';
import 'package:game_map_master_flutter_app/services/player_connection_service.dart';
import 'package:game_map_master_flutter_app/services/websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment_config.dart';
import '../models/user.dart';
import 'package:provider/provider.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';
class AuthService extends ChangeNotifier {
  final String apiBaseUrl;
  final String authBaseUrl;

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  bool get isLoggedIn => _currentUser != null;
  String? get currentUsername => _currentUser?.username;
  AuthService({required this.apiBaseUrl, required this.authBaseUrl}) {
    _loadUserFromPrefs();
  }
  factory AuthService.placeholder() {
    return AuthService(
      apiBaseUrl: EnvironmentConfig.apiBaseUrl,
      authBaseUrl: '${EnvironmentConfig.apiBaseUrl}/auth',
    );
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');

    if (token != null && userJson != null) {
      if (_isTokenExpired(token)) {
        await logout();
        return;
      }

      _token = token;
      _currentUser = User.fromJson(jsonDecode(userJson));

      await _fetchUserInfo();
      notifyListeners();
    }
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');
    
    if (token != null && userJson != null) {
      _token = token;
      _currentUser = User.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
  }
  
  Future<void> _saveUserToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_token != null && _currentUser != null) {
      await prefs.setString('token', _token!);
      await prefs.setString('user', jsonEncode(_currentUser!.toJson()));
    } else {
      await prefs.remove('token');
      await prefs.remove('user');
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    logger.d('🔐 Démarrage du login...');

    try {
      logger.d('📡 Envoi de la requête à $authBaseUrl/login...');
      final response = await http.post(
        Uri.parse('$authBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      logger.d('📬 Reçu réponse HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.d('✅ Token reçu : ${data['accessToken']}');

        _token = data['accessToken'];

        logger.d('👤 Récupération des infos utilisateur...');
        await _fetchUserInfo();
        logger.d('📥 Infos utilisateur récupérées.');

        _saveUserToPrefs();
        logger.d('💾 Utilisateur sauvegardé dans les prefs.');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        logger.d('❌ Erreur HTTP ${response.statusCode} : ${response.body}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      logger.d('💥 Exception lors du login : $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password,
      String firstName, String lastName, String phoneNumber, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('$authBaseUrl/register');
      logger.d('🔵 Sending POST to $url');
      logger.d('🔵 Payload: ${{
        'username': username,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'role': role,
      }}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
          'role': role,
        }),
      );

      logger.d('🔵 Status code: ${response.statusCode}');
      logger.d('🔵 Body: ${response.body}');

      _isLoading = false;
      notifyListeners();

      return response.statusCode == 200;
    } catch (e, stack) {
      logger.d('🔴 Register error: $e');
      logger.d('🔴 Stacktrace: $stack');

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


  Future<void> _fetchUserInfo() async {
    if (_token == null) {
      logger.d('❌ [_fetchUserInfo] Token nul, abandon.');
      return;
    }

    final url = '$apiBaseUrl/users/me';
    logger.d('📡 [_fetchUserInfo] Requête vers $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      logger.d('📬 [_fetchUserInfo] Status: ${response.statusCode}');
      logger.d('📦 [_fetchUserInfo] Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          logger.d('🔍 [_fetchUserInfo] Données JSON : $data');

          _currentUser = User.fromJson(data);
          logger.d('✅ [_fetchUserInfo] Utilisateur désérialisé : ${_currentUser?.username}');
        } catch (e, stack) {
          logger.e('❌ [_fetchUserInfo] Erreur lors du parsing JSON → $e', stackTrace: stack);
        }
      } else if (response.statusCode == 401) {
        logger.d('🔒 [_fetchUserInfo] Token expiré ou invalide. Déconnexion...');
        await logout();
      } else {
        logger.d('⚠️ [_fetchUserInfo] Réponse inattendue : ${response.statusCode}');
      }
    } catch (e, stack) {
      logger.e('❌ [_fetchUserInfo] Erreur réseau ou autre : $e', stackTrace: stack);
    }
  }


  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload['exp'];
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return true; // En cas d'erreur, on considère le token comme expiré
    }
  }


  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    
    await _saveUserToPrefs();
    notifyListeners();
  }

  Future<void> leaveAndLogout(BuildContext context) async {
    final webSocketService = context.read<WebSocketService>();
    final playerConnectionService = context.read<PlayerConnectionService>();
    final gameStateService = context.read<GameStateService>();

    final userId = _currentUser?.id;
    final fieldId = gameStateService.selectedMap?.field?.id;

    try {
      if (userId != null && fieldId != null) {
        final isConnected = gameStateService.isPlayerConnected(userId);

        if (isConnected) {
          logger.d('🚪 Déconnexion du terrain avant logout...');
          try {
            await playerConnectionService.leaveField(fieldId);
            webSocketService.unsubscribeFromField(fieldId);
          } catch (e) {
            logger.d('⚠️ [leaveAndLogout] Erreur non bloquante pendant leaveField : $e');
          }
        }
      }
    } catch (e) {
      logger.d('⚠️ [leaveAndLogout] Erreur inattendue : $e');
    } finally {
      await logout();
    }
  }

}
