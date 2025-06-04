import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'package:go_router/go_router.dart';

import '../../services/game_state_service.dart';
import '../../services/player_connection_service.dart';
import 'package:airsoft_game_map/utils/logger.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authService = GetIt.I<AuthService>();
      final gameStateService = GetIt.I<GameStateService>();
      final apiService = GetIt.I<ApiService>();

      final success = await authService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        try {
          // 🌟 1. Restaurer la session du terrain ouvert
          await gameStateService.restoreSessionIfNeeded(apiService);

          // 🌟 2. Si un terrain est actif, vérifier si l'utilisateur est connecté
          final fieldId = gameStateService.selectedMap?.field?.id;
          final userId = authService.currentUser?.id;

          if (fieldId != null && userId != null) {
            final isAlreadyConnected =
                gameStateService.isPlayerConnected(userId);

            if (!isAlreadyConnected) {
              logger.d(
                  '🚀 Reconnexion automatique de l’utilisateur au terrain...');
              await GetIt.I<PlayerConnectionService>().joinMap(fieldId);

              // On recharge la session pour bien rafraîchir les joueurs
              await gameStateService.restoreSessionIfNeeded(apiService);
            } else {
              logger.d('ℹ️ Utilisateur déjà connecté au terrain');
            }
          } else {
            logger.d('ℹ️ Aucun terrain ouvert ou utilisateur non connecté.');
          }
        } catch (e) {
          logger.d(
              '⚠️ Erreur lors de la tentative de reconnexion automatique : $e');
        }

        // 🌟 3. Redirection après login
        final user = authService.currentUser;
        if (user != null) {
          if (user.hasRole('HOST')) {
            context.go('/host');
          } else {
            context.go('/gamer/lobby');
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de la connexion. Vérifiez vos identifiants.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = GetIt.I<AuthService>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.map,
                    size: 80,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Airsoft Game Map',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom d\'utilisateur',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre nom d\'utilisateur';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: authService.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: authService.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Se connecter'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      context.go('/register');
                    },
                    child: const Text('Pas encore inscrit ? Créer un compte'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
