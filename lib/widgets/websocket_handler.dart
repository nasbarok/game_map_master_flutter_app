import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';

class WebSocketHandler extends StatefulWidget {
  final Widget child;

  const WebSocketHandler({Key? key, required this.child}) : super(key: key);

  @override
  State<WebSocketHandler> createState() => _WebSocketHandlerState();
}

class _WebSocketHandlerState extends State<WebSocketHandler> {
  late StreamSubscription<Map<String, dynamic>> _subscription;
  
  @override
  void initState() {
    super.initState();
    final webSocketService = Provider.of<WebSocketService>(context, listen: false);
    
    // S'abonner au flux de messages WebSocket
    _subscription = webSocketService.messageStream.listen((message) {
      _handleWebSocketMessage(message);
    });
    
    // Connecter au WebSocket si ce n'est pas déjà fait
    if (!webSocketService.isConnected) {
      webSocketService.connect();
    }
  }
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
  
  void _handleWebSocketMessage(Map<String, dynamic> message) {
    // Traiter les différents types de messages WebSocket
    final String type = message['type'] as String? ?? '';
    
    switch (type) {
      case 'GAME_INVITATION':
        _showGameInvitation(message);
        break;
      case 'TEAM_UPDATE':
        _handleTeamUpdate(message);
        break;
      case 'SCENARIO_UPDATE':
        _handleScenarioUpdate(message);
        break;
      case 'TREASURE_FOUND':
        _handleTreasureFound(message);
        break;
      default:
        print('Message WebSocket non géré: $message');
    }
  }
  
  void _showGameInvitation(Map<String, dynamic> message) {
    final gameData = message['data'] as Map<String, dynamic>? ?? {};
    final gameName = gameData['name'] as String? ?? 'Partie inconnue';
    final hostName = gameData['hostName'] as String? ?? 'Hôte inconnu';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invitation à la partie "$gameName" par $hostName'),
        action: SnackBarAction(
          label: 'Voir',
          onPressed: () {
            // Naviguer vers l'écran de détails de la partie
          },
        ),
        duration: const Duration(seconds: 10),
      ),
    );
  }
  
  void _handleTeamUpdate(Map<String, dynamic> message) {
    // Mettre à jour l'état de l'équipe dans l'application
    // Cela pourrait déclencher une mise à jour de l'UI
  }
  
  void _handleScenarioUpdate(Map<String, dynamic> message) {
    // Mettre à jour l'état du scénario dans l'application
    // Cela pourrait déclencher une mise à jour de l'UI
  }
  
  void _handleTreasureFound(Map<String, dynamic> message) {
    final treasureData = message['data'] as Map<String, dynamic>? ?? {};
    final playerName = treasureData['playerName'] as String? ?? 'Joueur inconnu';
    final treasureName = treasureData['treasureName'] as String? ?? 'Trésor inconnu';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$playerName a trouvé le trésor "$treasureName"!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
