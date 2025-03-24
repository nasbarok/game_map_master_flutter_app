import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'services/game_state_service.dart';
import 'screens/common/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/host/host_dashboard_screen.dart';
import 'screens/gamer/gamer_dashboard_screen.dart';
import 'widgets/websocket_handler.dart';

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  final _router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/host',
        builder: (context, state) => WebSocketHandler(
          child: const HostDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/gamer',
        builder: (context, state) => WebSocketHandler(
          child: const GamerDashboardScreen(),
        ),
      ),
    ],
    redirect: (context, state) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isLoggedIn = authService.isLoggedIn;
      final isLoggingIn = state.location == '/login' || state.location == '/register';
      final isSplash = state.location == '/splash';

      print('[Router] current location: ${state.location}');
      print('[Router] isLoggedIn: $isLoggedIn');

      if (isSplash) {
        print('[Router] On splash screen, no redirect');
        return null;
      }

      if (!isLoggedIn && !isLoggingIn) {
        print('[Router] Not logged in, redirecting to /login');
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        final user = authService.currentUser;
        print('[Router] Already logged in as ${user?.username}, redirecting to role');
        if (user != null) {
          final target = user.hasRole('HOST') ? '/host' : '/gamer';
          print('[Router] Redirect target: $target');
          return target;
        }
      }

      print('[Router] No redirect needed');
      return null;
    },

  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ProxyProvider<AuthService, ApiService>(
          update: (_, authService, __) => ApiService(authService),
        ),
        ChangeNotifierProxyProvider<AuthService, WebSocketService>(
          create: (_) => WebSocketService(null),
          update: (_, authService, previous) => previous!..updateAuthService(authService),
        ),
        // Ajout du nouveau service de gestion d'état du jeu
        ChangeNotifierProvider(create: (_) => GameStateService()),
      ],
      child: MaterialApp.router(
        title: 'Airsoft Game Master',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}
