import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

        /// PlayerConnectionService a besoin de ApiService + Client
        ProxyProvider2<ApiService, http.Client, PlayerConnectionService>(
          update: (_, apiService, client, __) => PlayerConnectionService(
            baseUrl: ApiService.baseUrl,
            client: client,
          ),
        ),

        /// WebSocketService a besoin de AuthService
        ProxyProvider<AuthService, WebSocketService>(
          update: (_, authService, __) => WebSocketService(authService),
        ),

      ],
      child: App(),
    ),
  );
}

