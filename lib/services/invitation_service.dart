import 'dart:async';

import 'package:airsoft_game_map/models/websocket/websocket_message.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as client;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/game_state_service.dart';
import '../../services/websocket_service.dart';
import '../models/field.dart';
import '../models/game_map.dart';
import '../models/invitation.dart';
import '../models/websocket/game_invitation_message.dart';
import '../models/websocket/invitation_response_message.dart';
import 'package:airsoft_game_map/utils/logger.dart';

class InvitationService extends ChangeNotifier {
  final WebSocketService _webSocketService;
  final AuthService _authService;
  final GameStateService _gameStateService;

  List<WebSocketMessage> _pendingInvitations = [];
  List<WebSocketMessage> _sentInvitations = [];
  StreamSubscription<WebSocketMessage>? _messageSubscription;

  InvitationService(this._webSocketService, this._authService,
      this._gameStateService) {
    _messageSubscription = _webSocketService.messageStream.listen(_handleWebSocketMessage as void Function(WebSocketMessage event)?);
  }

  List<WebSocketMessage> get pendingInvitations => _pendingInvitations;

  List<WebSocketMessage> get sentInvitations => _sentInvitations;

  void Function(Map<String, dynamic> invitation)? onInvitationReceivedDialog;

  get baseUrl => null;

  bool canSendInvitations() {
    // Vérifier si l'utilisateur est un host et si son terrain est ouvert
    final user = _authService.currentUser;
    return user != null &&
        user.hasRole('HOST') &&
        _gameStateService.isTerrainOpen;
  }

  Future<void> sendInvitation(int userId, String username) async {
    if (!canSendInvitations()) {
      throw Exception(
          'Vous devez être un host avec un terrain ouvert pour envoyer des invitations');
    }

    final fieldId = _gameStateService.selectedMap!.field!.id!;
    final senderId = _authService.currentUser!.id;

    final invitation = GameInvitationMessage(
      fieldId: fieldId,
      senderId: senderId!,
      targetUserId: userId,
    );

    // ✅ Envoi typé via WebSocket
    await _webSocketService.sendMessage('/app/invitation', invitation);

    // 🔄 Optionnel : enregistrer localement l'invitation envoyée
    _sentInvitations.add(invitation);
    notifyListeners();
  }


  void _handleWebSocketMessage(WebSocketMessage message) {
    final messageJson = message.toJson();
    final type = messageJson['type'];
    final payload = messageJson['payload'];
    if (type == 'GAME_INVITATION') {
      logger.d('📬 Invitation de jeu reçue');


      logger.d('🧾 Payload invitation : $payload');
      // Vérifier que toUserId existe et correspond à l'utilisateur actuel
      final toUserId = payload['toUserId'];
      final currentUserId = _authService.currentUser?.id;

      if (toUserId != null &&
          currentUserId != null &&
          toUserId == currentUserId) {
        {
          _pendingInvitations.add(message);
          notifyListeners();

          // ➕ Affichage du dialogue si défini
          if (onInvitationReceivedDialog != null) {
            onInvitationReceivedDialog!(messageJson);
          }
        }
      } else if (messageJson['type'] == 'INVITATION_RESPONSE') {
        logger.d('📬 Réponse à une invitation reçue');

        final response = messageJson['payload'];

        logger.d('🧾 Payload réponse : $response');

        final fromUserId = response['fromUserId'];
        final currentUserId = _authService.currentUser?.id;

        if (fromUserId != null &&
            currentUserId != null &&
            fromUserId == currentUserId) {
          final toUserId = response['toUserId'];
          final mapId = response['mapId'];
          if (toUserId != null && mapId != null) {}
          final index = _sentInvitations.indexWhere(
                (inv) {
                  final invToJson = inv.toJson();
              final invPayload = invToJson['payload'] ?? {};
              return invPayload['toUserId'] == toUserId &&
                  invPayload['mapId'] == mapId;
            },
          );

          if (index >= 0) {
            final invitation = _sentInvitations[index];
            final invitationToJson = invitation.toJson();
            invitationToJson['status'] =
            response['accepted'] == true ? 'accepted' : 'declined';
            notifyListeners();
          }
        } else if (messageJson['type'] == 'PLAYER_JOINED') {
          // Nouveau joueur a rejoint la partie
          final payload = messageJson['payload'];
          logger.d('👤 Joueur rejoint : ${payload['username']}');

          // Ajouter le joueur à la liste des joueurs connectés
          final player = {
            'id': payload['playerId'],
            'username': payload['username'],
            'teamId': payload['teamId'],
          };

          _gameStateService.addConnectedPlayer(player);
        } else if (messageJson['type'] == 'PLAYER_LEFT') {
          // Un joueur a quitté la partie
          final payload = messageJson['payload'];
          logger.d('👋 Joueur parti : ${payload['username']}');

          // Supprimer le joueur de la liste des joueurs connectés
          _gameStateService.removeConnectedPlayer(payload['playerId']);
        } else if (messageJson['type'] == 'FIELD_CLOSED') {
          // Le terrain a été fermé
          logger.d('🚪 Terrain fermé');

          // Si l'utilisateur n'est pas l'hôte, il doit être déconnecté
          if (!_authService.currentUser!.hasRole('HOST')) {
            _gameStateService.reset();
          }
        }
      }
    }
  }

  Future<void> respondToInvitation(
      BuildContext context,
      Map<String, dynamic> invitation,
      bool accept,
      ) async {
    try {
      final senderId = invitation['senderId'];
      final payload = invitation['payload'];
      final targetUserId = payload['targetUserId'];
      final fieldId = payload['fieldId'];
      final fromUsername = payload['fromUsername'];
      final mapName = payload['mapName'];

      final currentUserId = _authService.currentUser?.id;

      if (senderId == null || targetUserId == null || fieldId == null || currentUserId == null) {
        logger.d('❌ [invitation_service] [respondToInvitation] Invitation invalide ou utilisateur non connecté');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Invitation invalide.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Créer un message de réponse typé
      final response = InvitationResponseMessage(
        senderId: currentUserId,
        targetUserId: targetUserId,
        fieldId: fieldId,
        accepted: accept,
        fromUsername: fromUsername,
        mapName: mapName,
      );

      logger.d('📤 Envoi de la réponse à l’invitation : accept=$accept');
      await _webSocketService.sendMessage('/app/invitation-response', response);

      // Si l'invitation est acceptée, connecter le joueur au terrain
      if (accept) {
        final apiService = GetIt.I<ApiService>();
        _gameStateService.restoreSessionIfNeeded(apiService,fieldId);
      }

      // Supprimer des invitations en attente
      _pendingInvitations.removeWhere((inv) {
        final json = inv.toJson();
        return json['senderId'] == senderId && json['fieldId'] == fieldId;
      });

      notifyListeners();
    } catch (e) {
      logger.d('❌ Erreur respondToInvitation : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du traitement de l’invitation"), backgroundColor: Colors.red),
      );
    }
  }


  // Récupérer toutes les invitations pour l'utilisateur connecté
  Future<List<Invitation>> getMyInvitations() async {
    final url = '$baseUrl/api/invitations/me';

    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> invitationsJson = jsonDecode(response.body);
      return invitationsJson
          .map((json) => Invitation.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to get invitations: ${response.body}');
    }
  }

// Récupérer les invitations en attente
  Future<List<Invitation>> getMyPendingInvitations() async {
    final url = '$baseUrl/api/invitations/me/pending';

    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> invitationsJson = jsonDecode(response.body);
      return invitationsJson
          .map((json) => Invitation.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to get pending invitations: ${response.body}');
    }
  }

  // Accepter une invitation
  Future<Invitation> acceptInvitation(int invitationId) async {
    final url = '$baseUrl/api/invitations/$invitationId/accept';

    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Invitation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to accept invitation: ${response.body}');
    }
  }

  // Refuser une invitation
  Future<Invitation> declineInvitation(int invitationId) async {
    final url = '$baseUrl/api/invitations/$invitationId/decline';

    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Invitation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to decline invitation: ${response.body}');
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
