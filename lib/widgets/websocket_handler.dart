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

    // Initialiser le callback pour les invitations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final invitationService = Provider.of<InvitationService>(context, listen: false);
        invitationService.onInvitationReceivedDialog = (invitation) {
          _showInvitationDialog(invitation);
        };
      }
    });
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
      case 'PLAYER_JOINED':
        _handlePlayerJoined(message);
        break;
      case 'PLAYER_LEFT':
        _handlePlayerLeft(message);
        break;
      case 'TERRAIN_CLOSED':
        _handleTerrainClosed(message);
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
      case 'GAME_STARTED':
        _handleGameStarted(message);
        break;
      case 'GAME_ENDED':
        _handleGameEnded(message);
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
    try {
      notifications.showInvitationNotification(invitation);
    } catch (e) {
      print('Erreur lors de l\'affichage de la notification: $e');
    }

    final payload = invitation['payload'];
    // Afficher également un dialogue
    print('🔔 Ouverture du dialogue pour invitation de ${payload['fromUsername']} sur carte "${payload['mapName']}"');

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invitation reçue'),
          content: Text('${payload['fromUsername']} vous invite à rejoindre la carte "${payload['mapName']}"'),
          actions: [
            TextButton(
              onPressed: () {
                // Refuser l'invitation
                print('❌ Invitation refusée par l\'utilisateur');
                final invitationService = Provider.of<InvitationService>(context, listen: false);
                invitationService.respondToInvitation(invitation, false);
                Navigator.of(context).pop();
              },
              child: const Text('Refuser'),
            ),
            ElevatedButton(
              onPressed: () {
                // Accepter l'invitation
                print('✅ Invitation acceptée par l\'utilisateur');
                final invitationService = Provider.of<InvitationService>(context, listen: false);
                invitationService.respondToInvitation(invitation, true);
                Navigator.of(context).pop();

                // Naviguer vers l'écran de lobby
                context.go('/gamer/lobby');
              },
              child: const Text('Accepter'),
            ),
          ],
        ),
      );
    }
  }

  void _handlePlayerJoined(Map<String, dynamic> message) {
    final payload = message['payload'];
    final gameStateService = Provider.of<GameStateService>(context, listen: false);

    // Ajouter le joueur à la liste des joueurs connectés
    final player = {
      'id': payload['playerId'],
      'username': payload['username'],
      'teamId': payload['teamId'],
    };

    gameStateService.addConnectedPlayer(player);

    // Afficher une notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${payload['username']} a rejoint la partie'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handlePlayerLeft(Map<String, dynamic> message) {
    final payload = message['payload'];
    final gameStateService = Provider.of<GameStateService>(context, listen: false);

    // Supprimer le joueur de la liste des joueurs connectés
    gameStateService.removeConnectedPlayer(payload['playerId']);

    // Afficher une notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${payload['username']} a quitté la partie'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleTerrainClosed(Map<String, dynamic> message) {
    final gameStateService = Provider.of<GameStateService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    // Si l'utilisateur est un joueur (non host), naviguer vers l'écran principal
    if (!authService.currentUser!.hasRole('HOST')) {
      // Afficher une notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le terrain a été fermé par l\'hôte'),
            backgroundColor: Colors.red,
          ),
        );

        // Naviguer vers l'écran principal
        context.go('/gamer');
      }
    }

    // Mettre à jour l'état du jeu
    gameStateService.reset();
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

  void _handleGameStarted(Map<String, dynamic> message) {
    final gameStateService = Provider.of<GameStateService>(context, listen: false);
    final payload = message['payload'];

    // Mettre à jour l'état du jeu
    gameStateService.startGame();

    // Si une durée est spécifiée, synchroniser le temps
    if (payload['endTime'] != null) {
      final endTimeStr = payload['endTime'] as String;
      final endTime = DateTime.parse(endTimeStr);
      gameStateService.syncGameTime(endTime);
    }

    // Afficher une notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La partie a commencé !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleGameEnded(Map<String, dynamic> message) {
    final gameStateService = Provider.of<GameStateService>(context, listen: false);

    // Mettre à jour l'état du jeu
    gameStateService.stopGame();

    // Afficher une notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La partie est terminée !'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
