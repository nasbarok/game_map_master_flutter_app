import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../services/navigation_service.dart';
import '../services/auth_service.dart';
import '../services/game_state_service.dart';

// Écrans
import '../screens/common/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/host/host_dashboard_screen.dart';
import '../screens/gamer/game_lobby_screen.dart';

GoRouter buildAppRouter() {
  final navKey = GetIt.I<NavigationService>().navigatorKey;
  final auth   = GetIt.I<AuthService>();
  final gs     = GetIt.I<GameStateService>();

  // Rebuild automatique du router quand auth/GS changent
  final refresh = Listenable.merge([auth, gs]);

  return GoRouter(
    navigatorKey: navKey,
    initialLocation: '/splash',
    refreshListenable: refresh,

    routes: [
      GoRoute(path: '/splash',   builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Dashboard Host (réservé host non-visiteur)
      GoRoute(path: '/host', builder: (_, __) => const HostDashboardScreen()),

      // Lobby gamer (host visiteur ou gamer normal)
      GoRoute(
        path: '/gamer/lobby',
        builder: (_, state) {
          final refresh = state.queryParameters['refresh'];
          return GameLobbyScreen(key: ValueKey(refresh));
        },
      ),

      // Alias facultatif pour compat
      GoRoute(path: '/game-lobby', redirect: (_, __) => '/gamer/lobby'),
    ],

    // Redirection globale et simple à raisonner
    redirect: (_, state) {
      final loc = state.location;
      final isAuthScreen = loc == '/login' || loc == '/register' || loc == '/splash';

      // 1) Ne rien faire sur /splash (il gère lui-même sa logique)
      if (loc == '/splash') return null;

      // 2) Sécurité d’accès sans session
      if (!auth.isLoggedIn && !isAuthScreen) return '/login';

      // 3) Déjà loggé mais sur /login|/register → router vers l’écran adapté
      if (auth.isLoggedIn && (loc == '/login' || loc == '/register')) {
        return gs.isHostInOwnTerrain ? '/host' : '/gamer/lobby';
      }

      // 4) Blocage d’accès au dashboard si pas host ou si host visite un autre terrain
      if (loc == '/host') {
        final isHost = auth.currentUser?.hasRole('HOST') ?? false;
        if (!isHost || gs.isHostVisiting) return '/gamer/lobby';
      }

      // 5) Si le host est sur son propre terrain → forcer /host
      if ((loc == '/gamer/lobby' || loc == '/game-lobby') && gs.isHostInOwnTerrain) {
        return '/host';
      }

      return null;
    },
  );
}
