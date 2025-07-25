import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../services/auth_service.dart';
import '../services/game_state_service.dart';
import '../services/team_service.dart';
import '../services/websocket/bomb_operation_web_socket_handler.dart';
import '../services/websocket/web_socket_game_session_handler.dart';
import '../services/websocket_service.dart';
import 'websocket_message_handler.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

class WebSocketInitializer extends StatefulWidget {
  final Widget child;

  const WebSocketInitializer({Key? key, required this.child}) : super(key: key);

  @override
  State<WebSocketInitializer> createState() => _WebSocketInitializerState();
}

class _WebSocketInitializerState extends State<WebSocketInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    // ✅ On utilise GetIt au lieu de Provider
    if (!_initialized) {
      final auth = GetIt.I<AuthService>();
      final gameState = GetIt.I<GameStateService>();
      final teamService = GetIt.I<TeamService>();
      final webSocketService = GetIt.I<WebSocketService>();
      final webSocketGameSessionHandler = GetIt.I<WebSocketGameSessionHandler>();
      final bombOperationWebSocketHandler = GetIt.I<BombOperationWebSocketHandler>();

      final handler = WebSocketMessageHandler(
        authService: auth,
        gameStateService: gameState,
        teamService: teamService,
        webSocketGameSessionHandler: webSocketGameSessionHandler,
        bombOperationWebSocketHandler: bombOperationWebSocketHandler,
      );

      webSocketService.setMessageHandler(handler);

      _initialized = true;
      logger.d('✅ WebSocketHandler initialisé via GetIt');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
