import 'dart:async';
import 'package:airsoft_game_map/services/team_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/websocket/websocket_message.dart';
import '../services/auth_service.dart';
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
  late StreamSubscription<WebSocketMessage> _subscription;

  @override
  void initState() {
    super.initState();
    final webSocketService =
        Provider.of<WebSocketService>(context, listen: false);

    // S'abonner au flux de messages WebSocket
    _subscription = webSocketService.messageStream.listen(_handleWebSocketMessage as void Function(WebSocketMessage event)?);

    // Connecter au WebSocket si ce n'est pas déjà fait
    if (!webSocketService.isConnected) {
      webSocketService.connect();
    }

    // Initialiser le callback pour les invitations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final invitationService =
            Provider.of<InvitationService>(context, listen: false);
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

  void _handleWebSocketMessage(WebSocketMessage message) {
    // Traiter les différents types de messages WebSocket
    final type = message.type;
    final messageToJson = message.toJson();
    print('📥 Message WebSocket reçu: type=$type');
    print('🧾 Contenu: $message');
    switch (type) {
      case 'INVITATION_RECEIVED':
        _showInvitationDialog(messageToJson);
        break;
      case 'INVITATION_RESPONSE':
        _handleInvitationResponse(messageToJson);
        break;
      case 'PLAYER_JOINED':
        _handlePlayerJoined(messageToJson);
        break;
      case 'PLAYER_KICKED':
        _handlePlayerKicked(messageToJson);
        break;
      case 'PLAYER_LEFT':
        _handlePlayerLeft(messageToJson);
        break;
      case 'TERRAIN_CLOSED':
        _handleTerrainClosed(messageToJson);
        break;
      case 'TEAM_UPDATE':
        _handleTeamUpdate(messageToJson);
        break;
      case 'SCENARIO_UPDATE':
        _handleScenarioUpdate(messageToJson);
        break;
      case 'TREASURE_FOUND':
        _handleTreasureFound(messageToJson);
        break;
      case 'GAME_STARTED':
        _handleGameStarted(messageToJson);
        break;
      case 'GAME_ENDED':
        _handleGameEnded(messageToJson);
        break;
      default:
        print('Message WebSocket non géré: $messageToJson');
    }
  }

  void _handleInvitationResponse(Map<String, dynamic> invitationResponse) {
    final payload = invitationResponse['payload'];
    final userId = payload['fromUserId'];
    final username = payload['fromUsername'] ?? 'Joueur';
    final teamName = payload['teamName'] ?? 'Sans équipe';
    final bool accepted = payload['accepted'] == true;

    if (!mounted) return;

    final gameStateService =
        Provider.of<GameStateService>(context, listen: false);

    print('📥 Invitation response reçue : $payload');

    if (!accepted) {
      // ❌ Refus
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text( username + ' a refusé l\'invitation'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      print(
          '✅ Invitation acceptée par ${payload['fromUsername']} (ID: ${payload['fromUserId']})');

      // ✅ Ne rien faire si le joueur est déjà dans la liste
      final alreadyInList = gameStateService.connectedPlayersList.any(
        (player) => player['id'] == userId,
      );
      // ✅ Accepté → ajout du joueur dans GameStateService
      print('👀 Est déjà dans la liste ? $alreadyInList');

      if (!alreadyInList) {
        gameStateService.incrementConnectedPlayers(payload);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text( username + ' a rejoint le terrain !'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
    print(
        '🔔 Ouverture du dialogue pour invitation de ${payload['fromUsername']} sur carte "${payload['mapName']}"');

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invitation reçue'),
          content: Text(
              '${payload['fromUsername']} vous invite à rejoindre la carte "${payload['mapName']}"'),
          actions: [
            TextButton(
              onPressed: () {
                // Refuser l'invitation
                print('❌ Invitation refusée par l\'utilisateur');
                final invitationService =
                    Provider.of<InvitationService>(context, listen: false);
                invitationService.respondToInvitation(context,invitation, false);
                Navigator.of(context).pop();
              },
              child: const Text('Refuser'),
            ),
            ElevatedButton(
              onPressed: () {
                // Accepter l'invitation
                print('✅ Invitation acceptée par l\'utilisateur');
                final invitationService =
                    Provider.of<InvitationService>(context, listen: false);
                invitationService.respondToInvitation(context,invitation, true);
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
    final gameStateService =
        Provider.of<GameStateService>(context, listen: false);

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
    final gameStateService =
        Provider.of<GameStateService>(context, listen: false);

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
    final gameStateService =
        Provider.of<GameStateService>(context, listen: false);
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
    print('🟦 TEAM_UPDATE reçu : $message');

    final payload = message['payload'];
    final mapId = payload['mapId'];
    final userId = payload['userId'];
    final teamId = payload['teamId'];
    final action = payload['action'];
    int playerId = payload['playerId'];

    final gameStateService =
    Provider.of<GameStateService>(context, listen: false);
    final TeamService teamService = Provider.of<TeamService>(context, listen: false);

    print('🧩 mapId: $mapId');
    print('👤 userId: $userId');
    print('🪧 teamId: $teamId');
    print('🔁 action: $action');

    if (action == 'REMOVE_FROM_TEAM') {
      print('➖ Suppression du joueur de son équipe');
      teamService.assignPlayerToTeam(playerId, teamId, mapId);
    } else {
      print('❓ Action non supportée ou inconnue : $action');
    }

    print('✅ TEAM_UPDATE traité');
  }

  void _handleScenarioUpdate(Map<String, dynamic> message) {
    // Mettre à jour l'état du scénario dans l'application
    // Cela pourrait déclencher une mise à jour de l'UI
  }

  void _handleTreasureFound(Map<String, dynamic> message) {
    final treasureData = message['data'] as Map<String, dynamic>? ?? {};
    final playerName =
        treasureData['playerName'] as String? ?? 'Joueur inconnu';
    final treasureName =
        treasureData['treasureName'] as String? ?? 'Trésor inconnu';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$playerName a trouvé le trésor "$treasureName"!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleGameStarted(Map<String, dynamic> message) {
    final gameStateService =
        Provider.of<GameStateService>(context, listen: false);
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
    final gameStateService =
        Provider.of<GameStateService>(context, listen: false);

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
  void _handlePlayerKicked(Map<String, dynamic> message) {
    final payload = message['payload'];
    final userId = message['playerId'];
    final _gameStateService =
        Provider.of<GameStateService>(context, listen: false);
    final _authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = _authService.currentUser?.id;

    // Si c'est l'utilisateur actuel qui a été déconnecté
    if (userId == currentUserId) {
      // Réinitialiser l'état du jeu
      _gameStateService.reset();
      // Afficher une notification à l'utilisateur
      _showKickedNotification();
    } else {
      // Mettre à jour la liste des joueurs connectés
      _gameStateService.removeConnectedPlayer(userId);
    }

    // Afficher une notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${payload['username']} a été exclu de la partie'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showKickedNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vous avez été déconnecté de la partie par l\'hôte'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}