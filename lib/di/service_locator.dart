import 'package:flutter/src/widgets/framework.dart';

import 'package:flutter/src/widgets/navigator.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/game_state_service.dart';
import '../services/navigation_service.dart';
import '../services/team_service.dart';
import '../services/websocket/field_websocket_handler.dart';
import '../services/websocket/player_websocket_handler.dart';
import '../services/websocket/team_websocket_handler.dart';
import '../services/websocket/websocket_manager.dart';
import '../services/websocket_service.dart';
import 'package:get_it/get_it.dart';

void setupServiceLocator() {
  // Services de base
  final authService = AuthService();
  final apiService = ApiService(authService, http.Client());
  final gameStateService = GameStateService(apiService);
  final teamService = TeamService(apiService, gameStateService);
  final navigationService = NavigationService();

  // WebSocket
  final webSocketService = WebSocketService(authService, gameStateService, teamService, navigationService as GlobalKey<NavigatorState>);

  // Handlers WebSocket
  final playerHandler = PlayerWebSocketHandler(gameStateService, teamService);
  final teamHandler = TeamWebSocketHandler(teamService);
  final fieldHandler = FieldWebSocketHandler(gameStateService, authService, navigationService as GlobalKey<NavigatorState>);

  // Manager WebSocket
  final webSocketManager = WebSocketManager(
    webSocketService,
    playerHandler,
    teamHandler,
    fieldHandler,
  );

  // Enregistrement des services
  GetIt.instance.registerSingleton<AuthService>(authService);
  GetIt.instance.registerSingleton<ApiService>(apiService);
  GetIt.instance.registerSingleton<GameStateService>(gameStateService);
  GetIt.instance.registerSingleton<TeamService>(teamService);
  GetIt.instance.registerSingleton<NavigationService>(navigationService);
  GetIt.instance.registerSingleton<WebSocketService>(webSocketService);
  GetIt.instance.registerSingleton<WebSocketManager>(webSocketManager);
}
