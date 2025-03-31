import 'package:airsoft_game_map/services/game_state_service.dart';
import 'package:airsoft_game_map/services/navigation_service.dart';
import 'package:airsoft_game_map/services/team_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'services/notifications.dart' as notifications;
import 'services/player_connection_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le service de notifications
  await notifications.initNotifications();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettings = InitializationSettings(android: androidSettings);
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Initialiser le service de navigation global
  GetIt.I.registerSingleton<NavigationService>(NavigationService());

  // Tu peux maintenant récupérer le navigatorKey comme ça :
  final navigatorKey = GetIt.I<NavigationService>().navigatorKey;

  runApp(
    MultiProvider(
      providers: [
        /// le client HTTP *en premier*
        Provider<http.Client>(create: (_) => http.Client()),

        /// AuthService
        ChangeNotifierProvider(create: (_) => AuthService()),

        /// ApiService a besoin de AuthService + Client
        ProxyProvider2<AuthService, http.Client, ApiService>(
          update: (_, authService, client, __) => ApiService(authService, client),
        ),

        /// GameStateService dépend de ApiService
        ProxyProvider2<ApiService, WebSocketService, GameStateService>(
          update: (_, apiService, wsService, __) => GameStateService(apiService, wsService),
        ),

        /// TeamService dépend de ApiService et GameStateService
        ProxyProvider2<ApiService, GameStateService, TeamService>(
          update: (_, apiService, gameStateService, __) =>
              TeamService(apiService, gameStateService),
        ),

        /// PlayerConnectionService dépend de ApiService + Client
        ProxyProvider2<ApiService, http.Client, PlayerConnectionService>(
          update: (_, apiService, client, __) => PlayerConnectionService(
            baseUrl: ApiService.baseUrl,
            client: client,
          ),
        ),

        /// WebSocketService dépend de AuthService, GameStateService, TeamService
        ProxyProvider3<AuthService, GameStateService, TeamService, WebSocketService>(
          update: (_, authService, gameStateService, teamService, __) =>
              WebSocketService(authService, gameStateService, teamService, navigatorKey),
        ),

      ],
      child: App(),
    ),
  );
}

