
import 'package:game_map_master_flutter_app/services/invitation_api_service.dart';
import 'package:game_map_master_flutter_app/services/l10n/locale_service.dart';
import 'package:http/http.dart' as http;

import '../config/environment_config.dart';
import '../services/api_service.dart';
import '../services/audio/simple_voice_service.dart';
import '../services/auth_service.dart';
import '../services/game_map_service.dart';
import '../services/game_session_service.dart';
import '../services/game_state_service.dart';
import '../services/geocoding_service.dart';
import '../services/history_service.dart';
import '../services/invitation_service.dart';
import '../services/navigation_service.dart';
import '../services/player_connection_service.dart';
import '../services/player_location_service.dart';
import '../services/scenario/bomb_operation/bomb_operation_scenario_service.dart';
import '../services/scenario/bomb_operation/bomb_operation_service.dart';
import '../services/scenario/treasure_hunt/treasure_hunt_score_service.dart';
import '../services/scenario/treasure_hunt/treasure_hunt_service.dart';
import '../services/scenario_service.dart';
import '../services/team_service.dart';
import '../services/websocket/bomb_operation_web_socket_handler.dart';
import '../services/websocket/field_websocket_handler.dart';
import '../services/websocket/player_websocket_handler.dart';
import '../services/websocket/team_websocket_handler.dart';
import '../services/websocket/treasure_hunt_websocket_handler.dart';
import '../services/websocket/web_socket_game_session_handler.dart';
import '../services/websocket/websocket_manager.dart';
import '../services/websocket_service.dart';

import '../services/location/advanced_location_service.dart';
import '../services/location/location_filter.dart';
import '../services/location/movement_detector.dart';

import 'package:get_it/get_it.dart';

void setupServiceLocator() {

  // 0. ENREGISTRER LE SERVICE AUDIO (lazy → créé à la première utilisation)
  GetIt.I.registerLazySingleton<SimpleVoiceService>(() => SimpleVoiceService());

  //service locator
  final localServiceLocator = LocaleService();

  // 1. Services de base http
  final baseUrl = EnvironmentConfig.apiBaseUrl;
  final authService = AuthService(apiBaseUrl: baseUrl, authBaseUrl: '$baseUrl/auth');

  final apiService = ApiService(authService, http.Client());

  // TreasureHuntService
  final treasureHuntService = TreasureHuntService(apiService);
  final treasureHuntScoreService = TreasureHuntScoreService(apiService);
  final bombOperationScenarioService = BombOperationScenarioService(apiService);


  // 2. Services de base
  final gameStateService = GameStateService(apiService,treasureHuntService);
  final gameMapService = GameMapService(apiService);
  final scenarioService = ScenarioService(apiService);
  final teamService = TeamService(apiService, gameStateService);
  gameStateService.setTeamService(teamService);

  final playerConnectionService = PlayerConnectionService(apiService, gameStateService);
  final gameSessionService = GameSessionService(apiService);
  final historyService = HistoryService(apiService);
  final geocodingService = GeocodingService(apiService);

  // 2. Navigation
  final navigationService = NavigationService();
  final navigatorKey = navigationService.navigatorKey;

  // 3. WebSocketService (⚠️ doit être enregistré avant InvitationService)
  final webSocketService = WebSocketService(authService, gameStateService, teamService, navigatorKey);

  // 4. Handlers
  final playerHandler = PlayerWebSocketHandler(gameStateService, teamService);
  final teamHandler = TeamWebSocketHandler(teamService, authService);
  final fieldHandler = FieldWebSocketHandler(gameStateService, authService, navigatorKey);
  final webSocketGameSessionHandler = WebSocketGameSessionHandler(
    gameSessionService: gameSessionService,
    treasureHuntScoreService: treasureHuntScoreService,
  );

// TreasureHuntWebSocketHandler
  final treasureHuntWebSocketHandler = TreasureHuntWebSocketHandler(webSocketService);
  final bombOperationWebSocketHandler = BombOperationWebSocketHandler(authService,webSocketService, navigatorKey,apiService);
  final bombOperationService = BombOperationService(apiService,bombOperationWebSocketHandler);

  // Services de géolocalisation avancée
  final locationFilter = LocationFilter();
  final movementDetector = MovementDetector();

  final advancedLocationService = AdvancedLocationService(
    filter: locationFilter,
    movementDetector: movementDetector,
  );
  final playerLocationService = PlayerLocationService(
    apiService,
    webSocketService,
    advancedLocationService, // ← passe l'instance partagée
  );
  // 5. WebSocketManager
  final webSocketManager = WebSocketManager(
    webSocketService,
    playerHandler,
    teamHandler,
    fieldHandler,
  );

  final invitationApiService = InvitationApiService(apiService, authService);

  // ✅ 7. ENREGISTRER LE SERVICE D'INVITATION À LA FIN
  final invitationService = InvitationService(
    webSocketService,
    authService,
    gameStateService,
      invitationApiService
  );


  // ✅ 6. ENREGISTREMENTS dans GetIt (dans cet ordre)
  GetIt.I.registerSingleton<LocaleService>(localServiceLocator);
  GetIt.I.registerSingleton<AuthService>(authService);
  GetIt.I.registerSingleton<ApiService>(apiService);
  GetIt.I.registerSingleton<GameStateService>(gameStateService);
  GetIt.I.registerSingleton<GameMapService>(gameMapService);
  GetIt.I.registerSingleton<ScenarioService>(scenarioService);
  GetIt.I.registerSingleton<TeamService>(teamService);
  GetIt.I.registerSingleton<PlayerConnectionService>(playerConnectionService);
  GetIt.I.registerSingleton<NavigationService>(navigationService);
  GetIt.I.registerSingleton<WebSocketService>(webSocketService);
  GetIt.I.registerSingleton<WebSocketManager>(webSocketManager);
  GetIt.I.registerSingleton<TreasureHuntService>(treasureHuntService);
  GetIt.I.registerSingleton<TreasureHuntWebSocketHandler>(treasureHuntWebSocketHandler);
  GetIt.I.registerSingleton<TreasureHuntScoreService>(treasureHuntScoreService);
  GetIt.I.registerSingleton<WebSocketGameSessionHandler>(webSocketGameSessionHandler);
  GetIt.I.registerSingleton<GameSessionService>(gameSessionService);
  GetIt.I.registerSingleton<HistoryService>(historyService);
  GetIt.I.registerSingleton<GeocodingService>(geocodingService);
  GetIt.I.registerSingleton<BombOperationScenarioService>(bombOperationScenarioService);
  GetIt.I.registerSingleton<PlayerLocationService>(playerLocationService);
  GetIt.I.registerSingleton<BombOperationService>(bombOperationService);
  GetIt.I.registerSingleton<BombOperationWebSocketHandler>(bombOperationWebSocketHandler);
  GetIt.I.registerSingleton<LocationFilter>(locationFilter);
  GetIt.I.registerSingleton<MovementDetector>(movementDetector);
  GetIt.I.registerSingleton<AdvancedLocationService>(advancedLocationService);
  GetIt.I.registerSingleton<InvitationApiService>(invitationApiService);
  GetIt.I.registerSingleton<InvitationService>(invitationService);

}

