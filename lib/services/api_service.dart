import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'package:airsoft_game_map/utils/logger.dart';
class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/api'; // URL pour l'émulateur Android
  // static const String baseUrl = 'http://localhost:8080/api'; // URL pour iOS simulator


  final AuthService _authService;
  final http.Client client;
  AuthService get authService => _authService;
  bool get isAuthenticated => _authService.token != null;


  ApiService(this._authService, this.client);

  factory ApiService.placeholder() {
    return ApiService(AuthService.placeholder(), http.Client());
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = _authService.token; // accès direct en mémoire
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }


  Future<dynamic> get(String endpoint) async {
    if (!isAuthenticated) {
      logger.d('⚠️ [API] Token nul. Annulation requête GET sur $endpoint');
      return null;
    }

    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );

    return _processResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    if (!isAuthenticated) {
      logger.d('⚠️ [API] Token nul. Annulation requête GET sur $endpoint');
      return null;
    }
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(data),
    );

    return _processResponse(response);
  }

  Future<dynamic> postList(String endpoint, List<dynamic> data) async {
    if (!isAuthenticated) {
      logger.d('⚠️ [API] Token nul. Annulation requête POST sur $endpoint');
      return null;
    }

    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(data),
    );

    return _processResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    if (!isAuthenticated) {
      logger.d('⚠️ [API] Token nul. Annulation requête POST sur $endpoint');
      return null;
    }

    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(data),
    );

    return _processResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    if (!isAuthenticated) {
      logger.d('⚠️ [API] Token nul. Annulation requête POST sur $endpoint');
      return null;
    }

    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );

    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode == 401) {
      logger.d('❌ [API] Non autorisé - utilisateur non connecté');
      throw Exception('Non autorisé - utilisateur non connecté');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      try {
        // Gestion spéciale du message brut "no_map_found"
        if (response.statusCode == 404 && response.body == "no_map_found") {
          throw Exception('NO_MAP_FOUND');
        }

        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Une erreur est survenue');
      } catch (e) {
        // JSON illisible ou message brut
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    }
  }

}
