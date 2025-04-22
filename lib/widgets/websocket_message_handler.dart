import 'dart:async';
import 'package:airsoft_game_map/services/team_service.dart';
import 'package:airsoft_game_map/services/websocket/web_socket_game_session_handler.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/scenario/scenario_dto.dart';
import '../models/scenario/treasure_hunt/treasure_hunt_notification.dart';
import '../models/websocket/player_kicked_message.dart';
import '../models/websocket/websocket_message.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/scenario/treasure_hunt/treasure_hunt_service.dart';
import '../services/websocket_service.dart';
import '../services/notifications.dart' as notifications;
import '../services/invitation_service.dart';
import '../../services/game_state_service.dart';

class WebSocketMessageHandler {
  final AuthService authService;
  final GameStateService gameStateService;
  final TeamService teamService;
  final WebSocketGameSessionHandler webSocketGameSessionHandler;

  WebSocketMessageHandler({
    required this.authService,
    required this.gameStateService,
    required this.teamService,
    required this.webSocketGameSessionHandler,
  });

  void handleWebSocketMessage(WebSocketMessage message, BuildContext context) {
    // Traiter les différents types de messages WebSocket
    print('🔄 Traitement par WebSocketMessageHandler : ${message.type}');
    final type = message.type;
    final messageToJson = message.toJson();
    final currentUserId = authService.currentUser?.id;

    // Attention : on n'ignore PAS PLAYER_KICKED même si senderId == currentUserId
    if (message.senderId == currentUserId &&
        type != 'PLAYER_KICKED' &&
        type != 'INVITATION_RESPONSE' &&
        type != 'TREASURE_FOUND') {
      print('⏩ Ignoré : message envoyé par moi-même');
      return;
    }

    print('📥 Message WebSocket reçu: type=$type');
    print('🧾 Contenu: $message');
    switch (type) {
      case 'INVITATION_RECEIVED':
        _showInvitationDialog(messageToJson, context);
        break;
      case 'INVITATION_RESPONSE':
        _handleInvitationResponse(messageToJson, context);
        break;
      case 'PLAYER_KICKED':
        _handlePlayerKicked(messageToJson, context);
        break;
      case 'PLAYER_CONNECTED':
        _handlePlayerConnected(messageToJson, context);
        break;
      case 'PLAYER_DISCONNECTED':
        _handlePlayerDisconnected(messageToJson, context);
        break;
      case 'FIELD_OPENED':
        _handleFieldOpened(messageToJson, context);
        break;
      case 'FIELD_CLOSED':
        _handleFieldClosed(messageToJson, context);
        break;
      case 'TEAM_UPDATE':
        _handleTeamUpdate(messageToJson, context);
        break;
      case 'TEAM_CREATED':
        _handleTeamCreated(messageToJson, context);
        break;
      case 'TEAM_DELETED':
        _handleTeamDeleted(messageToJson, context);
        break;
      case 'SCENARIO_UPDATE':
        _handleScenarioUpdate(messageToJson, context);
        break;
      case 'GAME_SESSION_STARTED':
        webSocketGameSessionHandler.handleGameSessionStarted(
            messageToJson, context);
        break;
      case 'GAME_SESSION_ENDED':
        webSocketGameSessionHandler.handleGameSessionEnded(
            messageToJson, context);
        break;
      case 'PARTICIPANT_JOINED':
        webSocketGameSessionHandler.handleParticipantJoined(
            messageToJson, context);
        break;
      case 'PARTICIPANT_LEFT':
        webSocketGameSessionHandler.handleParticipantLeft(
            messageToJson, context);
        break;
      case 'SCENARIO_ADDED':
        webSocketGameSessionHandler.handleScenarioAdded(messageToJson, context);
        break;
      case 'SCENARIO_ACTIVATED':
        webSocketGameSessionHandler.handleScenarioActivated(
            messageToJson, context);
        break;
      case 'SCENARIO_DEACTIVATED':
        webSocketGameSessionHandler.handleScenarioDeactivated(
            messageToJson, context);
        break;
      case 'TREASURE_FOUND':
        webSocketGameSessionHandler.handleTreasureFound(messageToJson, context);
        break;
      default:
        print('Message WebSocket non géré: $messageToJson');
    }
  }

  void _handleInvitationResponse(
      Map<String, dynamic> invitationResponse, BuildContext context) {
    final payload = invitationResponse['payload'];
    final userId = payload['fromUserId'];
    final username = payload['fromUsername'] ?? 'Joueur';
    final teamName = payload['teamName'] ?? 'Sans équipe';
    final bool accepted = payload['accepted'] == true;
    final int senderId = invitationResponse['senderId'];
    final currentUserId = authService.currentUser?.id;

    if (senderId == currentUserId) {
      print(
          '⏩ [websocket_message_handler] [_handleInvitationResponse] Ignoré : message envoyé par moi-même');
      return;
    }

    print(
        '📥 [websocket_message_handler] [_handleInvitationResponse] Invitation response reçue : $payload');

    if (!accepted) {
      // ❌ Refus
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(username + ' a refusé l\'invitation'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      print(
          '✅ [websocket_message_handler] [_handleInvitationResponse] Invitation acceptée par ${payload['fromUsername']} (ID: ${payload['fromUserId']})');

      // ✅ Ne rien faire si le joueur est déjà dans la liste
      final alreadyInList = gameStateService.connectedPlayersList.any(
        (player) => player['id'] == userId,
      );
      // ✅ Accepté → ajout du joueur dans GameStateService
      print(
          '👀 [websocket_message_handler] [_handleInvitationResponse] Est déjà dans la liste ? $alreadyInList');

      if (!alreadyInList) {
        gameStateService.incrementConnectedPlayers(payload);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(username + ' a rejoint le terrain !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // méthode pour afficher le dialogue d'invitation
  void _showInvitationDialog(
      Map<String, dynamic> invitation, BuildContext context) {
    final currentUser = authService.currentUser;
    final payload = invitation['payload'];
    final fieldId = payload['fieldId'];

    if (gameStateService.selectedField?.id == fieldId &&
        gameStateService.isTerrainOpen) {
      print('⏩ Invitation ignorée car déjà connecté au terrain $fieldId');
      return;
    }

    // Utiliser le service de notifications pour afficher une notification
    try {
      notifications.showInvitationNotification(invitation);
    } catch (e) {
      print('Erreur lors de l\'affichage de la notification: $e');
    }

    // Afficher également un dialogue
    print(
        '🔔 Ouverture du dialogue pour invitation de ${payload['fromUsername']} sur carte "${payload['mapName']}"');

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
              final invitationService = context.read<InvitationService>();
              invitationService.respondToInvitation(context, invitation, false);
              Navigator.of(context).pop();
            },
            child: const Text('Refuser'),
          ),
          ElevatedButton(
            onPressed: () async {
              final invitationService = context.read<InvitationService>();
              final gameStateService = context.read<GameStateService>();
              final apiService = context.read<ApiService>();

              // 1. Envoi réponse ACCEPT
              await invitationService.respondToInvitation(
                  context, invitation, true);

              // 3. Restore session complète
              await gameStateService.restoreSessionIfNeeded(apiService);

              // 4. Fermer dialogue
              if (context.mounted) {
                Navigator.of(context).pop();
                if (currentUser != null) {
                  if (currentUser.hasRole('HOST')) {
                    context.go('/host');
                  } else {
                    context.go('/gamer/lobby');
                  }
                }
              }
            },
            child: const Text('Accepter'),
          ),
        ],
      ),
    );
  }

  void _handlePlayerConnected(
      Map<String, dynamic> message, BuildContext context) {
    final payload = message['payload'];

    // Ajouter le joueur à la liste des joueurs connectés
    final player = {
      'id': payload['playerId'],
      'username': payload['playerUsername'],
      'teamId': payload['teamId'],
    };

    gameStateService.addConnectedPlayer(player);

    // Afficher une notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${payload['playerUsername']} a rejoint le terrain'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handlePlayerDisconnected(
      Map<String, dynamic> message, BuildContext context) {
    final payload = message['payload'];
    final currentUserId = authService.currentUser?.id;
    final playerId = payload['playerId'];
    final fieldId = payload['fieldId'];
    final webSocketService = context.read<WebSocketService>();

    if (playerId == currentUserId) {
      // Si c'est l'utilisateur actuel qui a été déconnecté
      gameStateService.reset();
      _showDisconnectedNotification(context);
      webSocketService.unsubscribeFromField(fieldId);
    } else {
      // Mettre à jour la liste des joueurs connectés
      gameStateService.removeConnectedPlayer(playerId);

      // Afficher une notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${payload['playerUsername']} a quitté la partie'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleFieldOpened(Map<String, dynamic> message, BuildContext context) {
    final payload = message['payload'];
    final fieldId = payload['fieldId'];
    final ownerUsername = payload['ownerUsername'];
    final senderId = message['senderId'];
    final currentUserId = authService.currentUser?.id;

    print('🟢 FIELD_OPENED reçu : terrain ID=$fieldId, par $ownerUsername');

    // Si c’est le host lui-même (senderId == current user)
    if (senderId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vous avez ouvert le terrain'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📢 Le terrain a été ouvert par $ownerUsername'),
          backgroundColor: Colors.blue,
        ),
      );
    }

    // Activation du terrain côté GameStateService
    gameStateService.setTerrainOpen(true);
  }

  void _handleFieldClosed(Map<String, dynamic> message, BuildContext context) {
    final payload = message['payload'];
    final fieldId = payload['fieldId'];
    final ownerUsername = payload['ownerUsername'];
    final senderId = message['senderId'];

    final webSocketService = context.read<WebSocketService>();

    final currentUserId = authService.currentUser?.id;
    final isHost = authService.currentUser?.hasRole('HOST') ?? false;

    print('🧹 Terrain fermé par $ownerUsername (ID terrain: $fieldId)');

    if (senderId == currentUserId) {
      // ✅ Terrain fermé par moi-même
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vous avez fermé le terrain avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (!isHost) {
      // 🚫 Terrain fermé par un autre (et je ne suis pas Host)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⛔ $ownerUsername à fermé le terrain'),
          backgroundColor: Colors.red,
        ),
      );
    }
    webSocketService.unsubscribeFromField(fieldId);
    gameStateService.reset();
  }

  void _showGameInvitation(Map<String, dynamic> message, BuildContext context) {
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

  void _handleTeamUpdate(Map<String, dynamic> message, BuildContext context) {
    print('🟦 TEAM_UPDATE reçu : $message');
    final payload = message['payload'];
    final int mapId = payload['mapId'];
    final int userId = payload['userId'];
    final dynamic teamId = payload['teamId'];
    final String action = payload['action'];
    if (message['senderId'] == authService.currentUser?.id) {
      print('⏩ Message WebSocket émis par moi-même (senderId), on ignore');
      return;
    }

    if (action == 'ASSIGN_PLAYER') {
      if (teamId == null) {
        print('➖ Retrait du joueur $userId de son équipe');
        teamService.removePlayerFromTeam(userId, mapId);
      } else {
        print('➕ Assignation du joueur $userId à l\'équipe $teamId');
        final currentTeamId = teamService.getTeamIdForPlayer(userId);

        if (currentTeamId != teamId) {
          print(
              '🔄 Tentative d\'assignation du joueur $userId à l\'équipe $teamId');
          teamService.assignPlayerToTeam(userId, teamId, mapId);
        } else {
          print('⏸️ Assignation ignorée : joueur déjà dans l’équipe $teamId');
        }
      }
    } else if (action == 'REMOVE_FROM_TEAM') {
      print('➖ Retrait du joueur $userId de son équipe (REMOVE_FROM_TEAM)');
      teamService.removePlayerLocally(userId, mapId);
    } else {
      print('❓ Action non supportée ou inconnue : $action');
    }

    print('✅ TEAM_UPDATE traité');
  }

  void _handleScenarioUpdate(
      Map<String, dynamic> message, BuildContext context) {
    final payload = message['payload'] as Map<String, dynamic>?;
    if (payload == null) {
      print('❌ [WebSocketHandler] Payload manquant dans SCENARIO_UPDATE');
      return;
    }

    final fieldId = payload['fieldId'];
    final List<Map<String, dynamic>>? scenarioDtosMapList =
        payload['scenarioDtos'];
    if (scenarioDtosMapList == null) {
      print('❌ [WebSocketHandler] SCENARIO_UPDATE sans scénarioDtos');
      return;
    }
    final List<ScenarioDTO> scenarioDtos =
        scenarioDtosMapList.map((dto) => ScenarioDTO.fromJson(dto)).toList();

    print('📥 [WebSocketHandler] SCENARIO_UPDATE reçu pour fieldId=$fieldId');

    if (scenarioDtos == null || scenarioDtos.isEmpty) {
      print('⚠️ Aucun scénario reçu dans SCENARIO_UPDATE');
      return;
    }

    final gameStateService = context.read<GameStateService>();
    gameStateService.setSelectedScenarios(scenarioDtos);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Scénarios mis à jour sur le terrain'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _handleTreasureFound(
      Map<String, dynamic> message, BuildContext context) {
    final payload = message['payload'];
    final treasureFoundData = TreasureFoundData.fromJson(payload);

    final treasureHuntService = GetIt.I<TreasureHuntService>();
    treasureHuntService.addTreasureFoundEvent(treasureFoundData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${treasureFoundData.username} a trouvé le trésor "${treasureFoundData.treasureName}"'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleGameStarted(Map<String, dynamic> message, BuildContext context) {
    final payload = message['payload'];
    final gameId = payload['gameId'];
    // Mettre à jour l'état du jeu
    gameStateService.startGame(gameId);

    // Si une durée est spécifiée, synchroniser le temps
    if (payload['endTime'] != null) {
      final endTimeStr = payload['endTime'] as String;
      final endTime = DateTime.parse(endTimeStr);
      gameStateService.syncGameTime(endTime);
    }

    // Afficher une notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La partie a commencé !'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleGameEnded(Map<String, dynamic> message, BuildContext context) {
    // Mettre à jour l'état du jeu
    gameStateService.stopGameLocally();

    // Afficher une notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La partie est terminée !'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handlePlayerKicked(
      Map<String, dynamic> message, BuildContext context) async {
    try {
      final playerKicked = PlayerKickedMessage.fromJson(message);
      final currentUserId = authService.currentUser?.id;

      final apiService = GetIt.I<ApiService>();
      final webSocketService = GetIt.I<WebSocketService>();

      if (playerKicked.userId == currentUserId) {
        // 🟥 Si c'est moi qui ai été kické
        print('⛔ Vous avez été kické du terrain ${playerKicked.fieldId}');

        // Déconnexion et reset
        gameStateService.reset();

        // Supprimer l'historique localement
        try {
          await apiService
              .delete('fields-history/history/${playerKicked.fieldId}');
          print(
              '🧹 Historique supprimé pour le terrain ${playerKicked.fieldId}');
        } catch (e) {
          print('❌ Erreur lors de la suppression de l’historique : $e');
        }

        // Désabonnement WebSocket
        webSocketService.unsubscribeFromField(playerKicked.fieldId);

        // Message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⛔ Vous avez été exclu du terrain par l\'hôte'),
            backgroundColor: Colors.red,
          ),
        );

        // Retourner au menu principal
        if (context.mounted) {
          if (authService.currentUser!.hasRole('HOST')) {
            context.go('/host');
          } else {
            context.go('/gamer/lobby');
          }
        }
      } else {
        // ➖ Sinon, c'est un autre joueur qui a été kické
        print(
            '➖ Joueur ${playerKicked.username} (ID ${playerKicked.userId}) a été kické');

        // Supprimer de la liste
        gameStateService.removeConnectedPlayer(playerKicked.userId);

        // Message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚪 ${playerKicked.username} a été exclu du terrain'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur dans _handlePlayerKicked : $e');
    }
  }

  void _handleTeamCreated(Map<String, dynamic> message, BuildContext context) {
    print('🟩 TEAM_CREATED reçu : $message');
    final payload = message['payload'];
    final team = payload['team'];
    final mapId = payload['mapId'];

    if (team == null || mapId == null) {
      print('⚠️ Données TEAM_CREATED invalides');
      return;
    }

    try {
      teamService.addTeam(team, mapId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nouvelle équipe créée : ${team['name']}'),
          backgroundColor: Colors.blueAccent,
        ),
      );
    } catch (e) {
      print('❌ Erreur lors du traitement de TEAM_CREATED : $e');
    }
  }

  void _handleTeamDeleted(Map<String, dynamic> message, BuildContext context) {
    print('🟥 TEAM_DELETED reçu : $message');

    final payload = message['payload'];
    final int teamId = payload['teamId'];
    final int mapId = payload['mapId'];

    // Ne fais rien si c'est moi qui ai supprimé
    if (message['senderId'] == authService.currentUser?.id) {
      print('⏩ Message WebSocket TEAM_DELETED émis par moi-même, ignoré');
      return;
    }

    // Suppression uniquement en local (⚠️ ne pas appeler API)
    teamService.deleteTeamLocally(teamId, mapId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Une équipe a été supprimée.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showDisconnectedNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vous avez été déconnecté de la partie par l\'hôte'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }
}
