import 'package:game_map_master_flutter_app/services/game_map_service.dart';
import 'package:game_map_master_flutter_app/services/game_session_service.dart';
import 'package:game_map_master_flutter_app/services/game_state_service.dart';
import 'package:game_map_master_flutter_app/services/geocoding_service.dart';
import 'package:game_map_master_flutter_app/services/history_service.dart';
import 'package:game_map_master_flutter_app/services/invitation_service.dart';
import 'package:game_map_master_flutter_app/services/location/advanced_location_service.dart';
import 'package:game_map_master_flutter_app/services/navigation_service.dart';
import 'package:game_map_master_flutter_app/services/player_location_service.dart';
import 'package:game_map_master_flutter_app/services/scenario/bomb_operation/bomb_operation_scenario_service.dart';
import 'package:game_map_master_flutter_app/services/scenario/bomb_operation/bomb_operation_service.dart';
import 'package:game_map_master_flutter_app/services/scenario/treasure_hunt/treasure_hunt_score_service.dart';
import 'package:game_map_master_flutter_app/services/scenario_service.dart';
import 'package:game_map_master_flutter_app/services/team_service.dart';
import 'package:game_map_master_flutter_app/services/websocket/bomb_operation_web_socket_handler.dart';
import 'package:game_map_master_flutter_app/services/websocket/treasure_hunt_websocket_handler.dart';
import 'package:game_map_master_flutter_app/services/websocket/web_socket_game_session_handler.dart';
import 'package:game_map_master_flutter_app/services/websocket/websocket_manager.dart';
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
import 'package:game_map_master_flutter_app/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  logger.d('⚡️ Starting app...');
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
        Provider<BombOperationService>.value(value: GetIt.I<BombOperationService>()),
        Provider<BombOperationScenarioService>.value(value: GetIt.I<BombOperationScenarioService>()),
        Provider<TreasureHuntWebSocketHandler>.value(value: GetIt.I<TreasureHuntWebSocketHandler>()),
        ChangeNotifierProvider<GameMapService>.value(value: GetIt.I<GameMapService>()),
        ChangeNotifierProvider<ScenarioService>.value(value: GetIt.I<ScenarioService>()),
        Provider<GameSessionService>.value(value: GetIt.I<GameSessionService>()),
        Provider<TreasureHuntScoreService>.value(value: GetIt.I<TreasureHuntScoreService>()),
        Provider<WebSocketGameSessionHandler>.value(value: GetIt.I<WebSocketGameSessionHandler>()),
        Provider<BombOperationWebSocketHandler>.value(value: GetIt.I<BombOperationWebSocketHandler>()),
        Provider<HistoryService>.value(value: GetIt.I<HistoryService>()),
        Provider<GeocodingService>.value(value: GetIt.I<GeocodingService>()),
        Provider<PlayerLocationService>.value(value: GetIt.I<PlayerLocationService>()),
        Provider<AdvancedLocationService>.value(value: GetIt.I<AdvancedLocationService>()),

        // Ajouter obligatoirement les nouveaux services ici
      ],
      child: App(),
    ),
  );
}
