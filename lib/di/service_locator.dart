import 'package:airsoft_game_map/services/player_location_service.dart';
import 'package:airsoft_game_map/services/scenario/bomb_operation/bomb_operation_scenario_service.dart';
import 'package:flutter/src/widgets/framework.dart';

import 'package:flutter/src/widgets/navigator.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as Http;

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/game_map_service.dart';
import '../services/game_session_service.dart';
import '../services/game_state_service.dart';
import '../services/geocoding_service.dart';
import '../services/history_service.dart';
import '../services/invitation_service.dart';
import '../services/navigation_service.dart';
import '../services/player_connection_service.dart';
import '../services/scenario/bomb_operation/bomb_operation_service.dart';
import '../services/scenario/bomb_operation/bomb_proximity_detection_service.dart';
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
import 'package:get_it/get_it.dart';

void setupServiceLocator() {
  // 1. Services de base http
  final authService = AuthService();
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

  final playerLocationService = PlayerLocationService(apiService,webSocketService);
  // 5. WebSocketManager
  final webSocketManager = WebSocketManager(
    webSocketService,
    playerHandler,
    teamHandler,
    fieldHandler,
  );

  // ✅ 6. ENREGISTREMENTS dans GetIt (dans cet ordre)
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


  // ✅ 7. ENREGISTRER LE SERVICE D'INVITATION À LA FIN
  final invitationService = InvitationService(
    webSocketService,
    authService,
    gameStateService,
  );
  GetIt.I.registerSingleton<InvitationService>(invitationService);
}

