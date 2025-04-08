import 'package:flutter/src/widgets/framework.dart';

import 'package:flutter/src/widgets/navigator.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as Http;

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/game_state_service.dart';
import '../services/invitation_service.dart';
import '../services/navigation_service.dart';
import '../services/player_connection_service.dart';
import '../services/team_service.dart';
import '../services/websocket/field_websocket_handler.dart';
import '../services/websocket/player_websocket_handler.dart';
import '../services/websocket/team_websocket_handler.dart';
import '../services/websocket/websocket_manager.dart';
import '../services/websocket_service.dart';
import 'package:get_it/get_it.dart';

void setupServiceLocator() {
  // 1. Services de base
  final authService = AuthService();
  final apiService = ApiService(authService, http.Client());
  final gameStateService = GameStateService(apiService);
  final teamService = TeamService(apiService, gameStateService);
  gameStateService.setTeamService(teamService);

  final playerConnectionService = PlayerConnectionService(apiService, gameStateService);

  // 2. Navigation
  final navigationService = NavigationService();
  final navigatorKey = navigationService.navigatorKey;

  // 3. WebSocketService (⚠️ doit être enregistré avant InvitationService)
  final webSocketService = WebSocketService(authService, gameStateService, teamService, navigatorKey);

  // 4. Handlers
  final playerHandler = PlayerWebSocketHandler(gameStateService, teamService);
  final teamHandler = TeamWebSocketHandler(teamService, authService);
  final fieldHandler = FieldWebSocketHandler(gameStateService, authService, navigatorKey);

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
  GetIt.I.registerSingleton<TeamService>(teamService);
  GetIt.I.registerSingleton<PlayerConnectionService>(playerConnectionService);
  GetIt.I.registerSingleton<NavigationService>(navigationService);
  GetIt.I.registerSingleton<WebSocketService>(webSocketService);
  GetIt.I.registerSingleton<WebSocketManager>(webSocketManager);

  // ✅ 7. ENREGISTRER LE SERVICE D'INVITATION À LA FIN
  final invitationService = InvitationService(
    webSocketService,
    authService,
    gameStateService,
  );
  GetIt.I.registerSingleton<InvitationService>(invitationService);
}

