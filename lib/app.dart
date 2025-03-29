import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/game_state_service.dart';
import '../services/invitation_service.dart';
import '../services/team_service.dart';
import '../screens/common/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/host/host_dashboard_screen.dart';
import '../screens/gamer/gamer_dashboard_screen.dart';
import '../screens/gamer/game_lobby_screen.dart';
import '../widgets/websocket_handler.dart';

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
        builder: (context, state) => const WebSocketHandler(
          child: HostDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/gamer',
        builder: (context, state) => const WebSocketHandler(
          child: GamerDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/gamer/lobby',
        builder: (context, state) => WebSocketHandler(
          child: const GameLobbyScreen(),
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
          final target = user.hasRole('HOST') ? '/host' : '/gamer/lobby';
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
        Provider<http.Client>(create: (_) => http.Client()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ProxyProvider<AuthService, ApiService>(
          update: (_, authService, __) => ApiService(authService, http.Client()),
        ),
        ChangeNotifierProxyProvider<AuthService, WebSocketService>(
          create: (_) => WebSocketService(null, null, null), // constructeur temporaire vide ou par défaut
          update: (_, authService, previous) => previous!..updateAuthService(authService),
        ),
        ChangeNotifierProvider(create: (_) => GameStateService(ApiService(AuthService(), http.Client()))),
        ChangeNotifierProxyProvider3<WebSocketService, AuthService, GameStateService, InvitationService>(
          create: (_) => InvitationService(
            // Valeurs par défaut temporaires, seront écrasées dans update
            Provider.debugCheckInvalidValueType != null ? WebSocketService(null,null,null ) : throw UnimplementedError(),
            AuthService(),
            GameStateService(ApiService(AuthService(), http.Client())),
          ),
          update: (_, webSocketService, authService, gameStateService, __) =>
              InvitationService(webSocketService, authService, gameStateService),
        ),
        ChangeNotifierProxyProvider2<ApiService, GameStateService, TeamService>(
          create: (_) => TeamService.placeholder(), // constructeur temporaire vide ou par défaut
          update: (_, apiService, gameStateService, __) =>
              TeamService(apiService, gameStateService),
        ),
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
