import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'package:go_router/go_router.dart';

import '../../services/game_state_service.dart';
import '../../services/player_connection_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

// 🎨 AJOUT : Import du background adaptatif
import '../../widgets/adaptive_background.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ VOTRE MÉTHODE _login() INCHANGÉE
  Future<void> _login() async {
    logger.d('🔐 Tentative de connexion en cours...');
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authService = GetIt.I<AuthService>();
      final gameStateService = GetIt.I<GameStateService>();
      final apiService = GetIt.I<ApiService>();

      logger.d('📡 Envoi des identifiants à AuthService...');
      final success = await authService.login(
        _usernameController.text,
        _passwordController.text,
      );
      try {
        if (success && mounted) {
          logger.d('✅ Connexion réussie. Début de restauration de session...');

          await gameStateService.restoreSessionIfNeeded(apiService, null);
          logger.d('🔁 Session terrain potentiellement restaurée.');

          final fieldId = gameStateService.selectedMap?.field?.id;
          final userId = authService.currentUser?.id;
          logger.d('🧾 fieldId=$fieldId, userId=$userId');

          if (fieldId != null && userId != null) {
            final isAlreadyConnected =
                gameStateService.isPlayerConnected(userId);
            logger.d('🔎 isAlreadyConnected=$isAlreadyConnected');

            if (!isAlreadyConnected) {
              logger.d(
                  '🚀 Reconnexion automatique de l utilisateur au terrain...');
              await GetIt.I<PlayerConnectionService>().joinMap(fieldId);
              logger.d(
                  '✅ Rejoint le terrain avec succès. Rechargement de la session...');
              await gameStateService.restoreSessionIfNeeded(
                  apiService, fieldId);
            } else {
              logger.d('ℹ️ Utilisateur déjà connecté au terrain.');
            }
          } else {
            logger.d('⚠️ Aucun terrain actif ou utilisateur non défini.');
          }

          final user = authService.currentUser;
          if (user != null) {
            logger.d('➡️ Redirection en fonction du rôle : ${user.roles}');
            if (user.hasRole('HOST')) {
              context.go('/host');
            } else {
              context.go('/gamer/lobby');
            }
          } else {
            logger.d('⚠️ Utilisateur null après login');
          }
        } else if (mounted) {
          logger.d('❌ Connexion échouée, affichage du SnackBar');
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.loginFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e, stack) {
        logger.e('❌ Erreur lors de la tentative de reconnexion automatique',
            error: e, stackTrace: stack);
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      logger.d('⚠️ Formulaire non valide');
    }
  }

  @override

  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 🎨 MODIFICATION : Utilisation d'AdaptiveScaffold avec background
    return AdaptiveScaffold(
      gameBackgroundType: GameBackgroundType.home,
      enableParallax: true,
      backgroundOpacity: 0.85, // Légère transparence pour la lisibilité
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  // 🎨 AJOUT : Container semi-transparent pour améliorer la lisibilité
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 🎨 MODIFICATION : Logo avec style militaire
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor.withOpacity(0.2),
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.map,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ✅ VOTRE TITRE INCHANGÉ
                        Text(
                          l10n.appTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // 🎨 Couleur adaptée au background
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ✅ VOS CHAMPS INCHANGÉS (le thème s'applique automatiquement)
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: l10n.username,
                            prefixIcon: const Icon(Icons.person),
                            border: const OutlineInputBorder(),
                            // 🎨 AJOUT : Style adapté au background sombre
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.promptUsername;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: l10n.password,
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
                            // 🎨 AJOUT : Style adapté au background sombre
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.promptPassword;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // ✅ VOS BOUTONS INCHANGÉS (le thème s'applique automatiquement)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(l10n.login),
                        ),
                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: () {
                            context.go('/register');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white, // 🎨 Couleur adaptée
                          ),
                          child: Text(l10n.register),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ✅ VOTRE OVERLAY DE CHARGEMENT INCHANGÉ
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

}
