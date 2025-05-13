import 'package:airsoft_game_map/services/game_map_service.dart';
import 'package:airsoft_game_map/services/game_session_service.dart';
import 'package:airsoft_game_map/services/game_state_service.dart';
import 'package:airsoft_game_map/services/geocoding_service.dart';
import 'package:airsoft_game_map/services/history_service.dart';
import 'package:airsoft_game_map/services/invitation_service.dart';
import 'package:airsoft_game_map/services/navigation_service.dart';
import 'package:airsoft_game_map/services/scenario/treasure_hunt/treasure_hunt_score_service.dart';
import 'package:airsoft_game_map/services/scenario_service.dart';
import 'package:airsoft_game_map/services/team_service.dart';
import 'package:airsoft_game_map/services/websocket/treasure_hunt_websocket_handler.dart';
import 'package:airsoft_game_map/services/websocket/web_socket_game_session_handler.dart';
import 'package:airsoft_game_map/services/websocket/websocket_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'app.dart';
import 'di/service_locator.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'services/notifications.dart' as notifications;
import 'services/player_connection_service.dart';
import 'services/scenario/treasure_hunt/treasure_hunt_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await notifications.initNotifications();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettings = InitializationSettings(android: androidSettings);
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // ⚙️ Setup GetIt une seule fois ici
  setupServiceLocator();

  // 📦 Wrapping App with MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: GetIt.I<AuthService>()),
        Provider<ApiService>.value(value: GetIt.I<ApiService>()),
        ChangeNotifierProvider<GameStateService>.value(value: GetIt.I<GameStateService>()),
        ChangeNotifierProvider<TeamService>.value(value: GetIt.I<TeamService>()),
        ChangeNotifierProvider<WebSocketService>.value(value: GetIt.I<WebSocketService>()),
        ChangeNotifierProvider<InvitationService>.value(value: GetIt.I<InvitationService>()),
        Provider<NavigationService>.value(value: GetIt.I<NavigationService>()),
        Provider<WebSocketManager>.value(value: GetIt.I<WebSocketManager>()),
        Provider<PlayerConnectionService>.value(value: GetIt.I<PlayerConnectionService>()),
        Provider<TreasureHuntService>.value(value: GetIt.I<TreasureHuntService>()),
        Provider<TreasureHuntService>.value(value: GetIt.I<TreasureHuntService>()),
        Provider<TreasureHuntWebSocketHandler>.value(value: GetIt.I<TreasureHuntWebSocketHandler>()),
        ChangeNotifierProvider<GameMapService>.value(value: GetIt.I<GameMapService>()),
        ChangeNotifierProvider<ScenarioService>.value(value: GetIt.I<ScenarioService>()),
        Provider<GameSessionService>.value(value: GetIt.I<GameSessionService>()),
        Provider<TreasureHuntScoreService>.value(value: GetIt.I<TreasureHuntScoreService>()),
        Provider<WebSocketGameSessionHandler>.value(value: GetIt.I<WebSocketGameSessionHandler>()),
        Provider<HistoryService>.value(value: GetIt.I<HistoryService>()),
        Provider<GeocodingService>.value(value: GetIt.I<GeocodingService>()),
        // Ajouter obligatoirement les nouveaux services ici
      ],
      child: App(),
    ),
  );
}
