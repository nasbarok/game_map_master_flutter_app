import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../../services/team_service.dart';
import '../../services/websocket_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

// 🎨 VERSION THÈME MILITAIRE SOMBRE - Cohérence parfaite

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // 🎨 COULEURS DU THÈME MILITAIRE (même que global_theme.dart)
  static const Color darkMetal = Color(0xFF2D3748); // Gris-bleu foncé
  static const Color textDark = Color(0xFF1A202C); // Très sombre
  static const Color primaryMetal = Color(0xFF4A5568); // Gris-bleu moyen
  static const Color lightMetal = Color(0xFF718096); // Gris-bleu clair
  static const Color accentGreen = Color(0xFF48BB78); // Vert militaire
  static const Color textLight = Color(0xFFF7FAFC); // Blanc cassé

  @override
  void initState() {
    super.initState();
    logger.d('🚀 SplashScreen initState - Début');
    _navigateAndRestore();
  }

  // ✅ VOTRE LOGIQUE DE NAVIGATION INCHANGÉE
  Future<void> _navigateAndRestore() async {
    logger.d('🔄 _navigateAndRestore - Début');

    final apiService = GetIt.I<ApiService>();
    final authService = GetIt.I<AuthService>();
    final gameState = GetIt.I<GameStateService>();
    final wsService = GetIt.I<WebSocketService>();
    gameState.setWebSocketService(wsService);

    await Future.delayed(const Duration(milliseconds: 2000));
    logger.d('⏰ Délai splash terminé');

    await authService.loadSession();
    logger.d('📱 Session chargée - isLoggedIn: ${authService.isLoggedIn}');

    if (!mounted) {
      logger.d('❌ Widget non monté, arrêt');
      return;
    }

    if (!authService.isLoggedIn) {
      logger.d('➡️ Redirection vers /login');
      context.go('/login');
      return;
    }

    try {
      if (gameState.isReady) {
        await gameState.restoreSessionIfNeeded(apiService, null);
      } else {
        logger.d('⏳ WebSocketService pas encore prêt, attente...');
        await Future.delayed(const Duration(milliseconds: 100));
        gameState.setWebSocketService(GetIt.I<WebSocketService>());
        await gameState.restoreSessionIfNeeded(apiService, null);
      }
    } catch (e) {
      logger.d('❌ Erreur pendant restoreSessionIfNeeded: $e');
    }

    if (!mounted) {
      logger.d(
          '❌ [splash_screen] Le widget n est plus monté, arrêt de la navigation');
      return;
    }
    final currentUser = authService.currentUser;
    final ownerId = gameState.selectedMap?.owner?.id;
    final isHost = currentUser?.hasRole('HOST') ?? false;

    // Décomposition du test
    bool isHostAndNotOwner = isHost &&
        gameState.selectedMap != null &&
        ownerId != null &&
        currentUser?.id != ownerId;

    final goTo = (isHost && !isHostAndNotOwner) ? '/host' : '/gamer/lobby';
    logger.d(
        '➡️ Redirection finale: isHost=$isHost, isHostInOwnTerrain=${gameState.isHostInOwnTerrain}, goTo=$goTo');
    context.go(goTo);
  }

  @override
  Widget build(BuildContext context) {
    logger.d('🎨 SplashScreen build() appelé');

    final l10n = AppLocalizations.of(context)!;

    // 🎨 FOND AVEC COULEURS DU THÈME MILITAIRE
    return Scaffold(
      body: Container(
        // 🎨 Gradient subtil avec les couleurs du thème
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              textDark, // 0xFF1A202C - Très sombre (haut)
              darkMetal, // 0xFF2D3748 - Gris-bleu foncé (bas)
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🎨 LOGO MILITAIRE avec bordure thématique
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // 🎨 Bordure avec couleur du thème
                    border: Border.all(
                      color: lightMetal.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: textDark.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: primaryMetal.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/theme/logo_military.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        logger.e('❌ Erreur chargement logo: $error');
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryMetal, darkMetal],
                            ),
                          ),
                          child: const Icon(
                            Icons.military_tech,
                            size: 70,
                            color: textLight,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 🎨 TITRE avec couleur du thème
                Text(
                  l10n.appTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textLight, // Blanc cassé du thème
                    shadows: [
                      Shadow(
                        color: textDark,
                        blurRadius: 4,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 🎨 SOUS-TITRE avec couleur du thème
                Text(
                  l10n.splashScreenSubtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: lightMetal, // Gris clair du thème
                    shadows: [
                      Shadow(
                        color: textDark,
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),

                // 🎨 INDICATEUR DE PROGRESSION avec couleur du thème
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: lightMetal.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: textDark.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        accentGreen, // Vert militaire du thème
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 🎨 Texte de chargement
                Text(
                  l10n.initializing,
                  style: TextStyle(
                    fontSize: 14,
                    color: lightMetal.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                // 🎨 Version en bas
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Text(
                    '${l10n.appTitle} v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: lightMetal.withOpacity(0.5),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🎨 BONUS : TextFormField adapté avec couleurs du thème
class MilitaryTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final bool obscureText;

  const MilitaryTextFormField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.validator,
    this.obscureText = false,
  }) : super(key: key);

  // 🎨 Couleurs du thème pour cohérence
  static const Color textLight = Color(0xFFF7FAFC);
  static const Color lightMetal = Color(0xFF718096);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.black87),
        prefixIcon: Icon(prefixIcon, color: lightMetal),
        border: const OutlineInputBorder(),
        // 🎨 FOND ADAPTÉ AU THÈME SOMBRE
        filled: true,
        fillColor: textLight.withOpacity(0.95),
        // Blanc cassé du thème
        focusedBorder: const OutlineInputBorder(
          borderSide:
              BorderSide(color: Color(0xFF48BB78), width: 2), // Vert militaire
        ),
      ),
      validator: validator,
    );
  }
}
