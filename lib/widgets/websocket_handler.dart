import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';
import '../services/notifications.dart' as notifications;
import '../services/invitation_service.dart';
import '../../services/game_state_service.dart';

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
    print('📥 Message WebSocket reçu: type=$type');
    print('🧾 Contenu: $message');
    switch (type) {
      case 'INVITATION_RECEIVED':
        _showInvitationDialog(message);
        break;
      case 'INVITATION_RESPONSE':
        _handleInvitationResponse(message);
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

  void _handleInvitationResponse(Map<String, dynamic> invitationResponse) {
    final payload = invitationResponse['payload'];
    final bool accepted = payload['accepted'] == true;

    if (!mounted) return;

    if (!accepted) {
      // ❌ Refus
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un joueur a refusé l\'invitation'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      // ✅ Accepté → ajout du joueur dans GameStateService
      final gameStateService = Provider.of<GameStateService>(
          context, listen: false);
      gameStateService.incrementConnectedPlayers();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Le joueur ${payload['fromUserId']} a rejoint la carte !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Nouvelle méthode pour afficher le dialogue d'invitation
  void _showInvitationDialog(Map<String, dynamic> invitation) {
    // Utiliser le service de notifications pour afficher une notification
    notifications.showInvitationNotification(invitation);
    final payload = invitation['payload'];
    // Afficher également un dialogue
    print('🔔 Ouverture du dialogue pour invitation de ${payload['fromUsername']} sur carte "${payload['mapName']}"');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invitation reçue'),
        content: Text('${payload['fromUsername']} vous invite à rejoindre la carte "${payload['mapName']}"'),
        actions: [
          TextButton(
            onPressed: () {
              // Refuser l'invitation
              print('❌ Invitation refusée par l’utilisateur');
              final invitationService = Provider.of<InvitationService>(context, listen: false);
              invitationService.respondToInvitation(invitation, false);
              Navigator.of(context).pop();
            },
            child: const Text('Refuser'),
          ),
          ElevatedButton(
            onPressed: () {
              // Accepter l'invitation
              print('✅ Invitation acceptée par l’utilisateur');
              final invitationService = Provider.of<InvitationService>(context, listen: false);
              invitationService.respondToInvitation(invitation, true);
              Navigator.of(context).pop();
            },
            child: const Text('Accepter'),
          ),
        ],
      ),
    );
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
