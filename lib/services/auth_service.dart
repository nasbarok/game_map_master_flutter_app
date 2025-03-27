import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  static const String baseUrl = 'http://192.168.3.23:8080/api/auth'; // URL pour l'émulateur Android
  
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  bool get isLoggedIn => _currentUser != null;

  AuthService() {
    _loadUserFromPrefs();
  }
  factory AuthService.placeholder() {
    return AuthService();
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');

    if (token != null && userJson != null) {
      _token = token;
      _currentUser = User.fromJson(jsonDecode(userJson));

      // Vérifier que le token est encore valide en appelant le serveur
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
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['accessToken'];
        
        // Récupérer les informations de l'utilisateur
        await _fetchUserInfo();
        
        _saveUserToPrefs();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
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
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
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
      
      _isLoading = false;
      notifyListeners();
      
      return response.statusCode == 200;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> _fetchUserInfo() async {
    if (_token == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('http://192.168.3.23:8080/api/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = User.fromJson(data);
      }
    } catch (e) {
      // Gérer l'erreur
    }
  }
  
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    
    await _saveUserToPrefs();
    notifyListeners();
  }
}
