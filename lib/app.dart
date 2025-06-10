import 'package:airsoft_game_map/services/navigation_service.dart';
import 'package:airsoft_game_map/widgets/websocket_initializer.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
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
import '../screens/gamer/game_lobby_screen.dart';
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  final navigationService = GetIt.instance<NavigationService>();

  @override
  Widget build(BuildContext context) {
    final navigatorKey = navigationService.navigatorKey;

    final router = GoRouter(
      navigatorKey: navigatorKey,
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
          builder: (context, state) => const HostDashboardScreen(),
        ),
        GoRoute(
          path: '/gamer/lobby',
          builder: (context, state) {
            final refresh = state.queryParameters['refresh'];
            return GameLobbyScreen(key: ValueKey(refresh));
          },
        ),
      ],
      redirect: (context, state) {
       final authService = GetIt.I<AuthService>();
        final isLoggedIn = authService.isLoggedIn;
        final isLoggingIn = state.location == '/login' || state.location == '/register';
        final isSplash = state.location == '/splash';

        if (isSplash) return null;
        if (!isLoggedIn && !isLoggingIn) return '/login';
        if (isLoggedIn && isLoggingIn) {
          final user = authService.currentUser;
          if (user != null) {
            return user.hasRole('HOST') ? '/host' : '/gamer/lobby';
          }
        }
        return null;
      },
    );

    return WebSocketInitializer(
      child: MaterialApp.router(
        title: 'Airsoft Game Master',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}
