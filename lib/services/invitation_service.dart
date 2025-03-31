import 'dart:async';

import 'package:airsoft_game_map/models/websocket/websocket_message.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as client;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/game_state_service.dart';
import '../../services/websocket_service.dart';
import '../models/game_map.dart';
import '../models/invitation.dart';

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

    final invitationPayload = {
      'fromUserId': _authService.currentUser!.id,
      'fromUsername': _authService.currentUser!.username,
      'toUserId': userId,
      'toUsername': username,
      'mapId': _gameStateService.selectedMap!.id,
      'fieldId': _gameStateService.selectedMap!.field?.id,
      'mapName': _gameStateService.selectedMap!.name,
    };

    final jsonInvitation = {
      'type': 'GAME_INVITATION',
      'payload': invitationPayload,
      'timestamp': DateTime
          .now()
          .millisecondsSinceEpoch,
    };

    final invitation = WebSocketMessage.fromJson(jsonInvitation);

    // Envoyer via WebSocket
    await _webSocketService.sendMessage(
        '/app/invitation', invitation);

    // Ajouter à la liste des invitations envoyées
    _sentInvitations.add(invitation);
    notifyListeners();
  }

  void _handleWebSocketMessage(WebSocketMessage message) {
    final messageJson = message.toJson();
    final type = messageJson['type'];
    final payload = messageJson['payload'];
    if (type == 'GAME_INVITATION') {
      print('📬 Invitation de jeu reçue');


      print('🧾 Payload invitation : $payload');
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
        print('📬 Réponse à une invitation reçue');

        final response = messageJson['payload'];

        print('🧾 Payload réponse : $response');

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
          print('👤 Joueur rejoint : ${payload['username']}');

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
          print('👋 Joueur parti : ${payload['username']}');

          // Supprimer le joueur de la liste des joueurs connectés
          _gameStateService.removeConnectedPlayer(payload['playerId']);
        } else if (messageJson['type'] == 'FIELD_CLOSED') {
          // Le terrain a été fermé
          print('🚪 Terrain fermé');

          // Si l'utilisateur n'est pas l'hôte, il doit être déconnecté
          if (!_authService.currentUser!.hasRole('HOST')) {
            _gameStateService.reset();
          }
        }
      }
    }
  }

  Future<void> respondToInvitation(BuildContext context,
      Map<String, dynamic> invitation, bool accept) async {
    final payload = invitation['payload'] ?? {};
    // Vérifier que les valeurs nécessaires existent
    final toUserId = payload['toUserId'];
    final fromUserId = payload['fromUserId'];
    final mapId = payload['mapId'];
    final fieldId = payload['fieldId'];

    if (toUserId == null || fromUserId == null || mapId == null) {
      print('❌ Données d\'invitation incomplètes');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Données d\'invitation incomplètes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final apiService = Provider.of<ApiService>(context, listen: false);
    final response = {
      'type': 'INVITATION_RESPONSE',
      'payload': {
        'fromUserId': payload['toUserId'],
        'toUserId': payload['fromUserId'],
        'mapId': payload['mapId'],
        'fieldId': payload['fieldId'],
        'accepted': accept,
        'timestamp': DateTime.now().toIso8601String(),
      }
    };

    print('📤 Envoi de la réponse à l’invitation : accept=$accept');
    print('🧾 Invitation envoyée : ${jsonEncode(response)}');
    print('📨 Envoi via STOMP vers /app/invitation-response...');

    // ✅ Envoi via STOMP avec destination explicite
    await _webSocketService.sendMessage(
        '/app/invitation-response', response as WebSocketMessage);

    print('✅ Réponse envoyée avec succès');

    // Si l'invitation est acceptée, mettre à jour l'état du jeu
    if (accept) {
      // Pour le joueur qui accepte l'invitation
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId != null && currentUserId == toUserId) {
        // Mettre à jour l'état du jeu avec les informations de la carte
        final mapName = payload['mapName'] ?? 'Carte sans nom';
        final mapId = payload['mapId'];
        final map = GameMap(
          id: mapId,
          name: mapName,
          imageUrl: '', // À compléter si disponible
          description: '', // À compléter si disponible
        );

        try {
          print('🔁 Mise à jour GameMap via PUT /maps/${mapId}');
          final mapResponse = await apiService.get('maps/${mapId}');
          if (mapResponse != null) {
            final selectedMap = GameMap.fromJson(mapResponse);
            _gameStateService.selectMap(selectedMap);

            final field = selectedMap.field;
            if (field != null) {
              _gameStateService.handleTerrainOpen(field, apiService);

              // Ajouter le joueur à la liste des joueurs connectés
              final currentUsername =
                  _authService.currentUser?.username ?? 'Joueur';
              final player = {
                'id': currentUserId,
                'username': currentUsername,
                'teamId': null, // Pas d'équipe par défaut
              };
              _gameStateService.addConnectedPlayer(player);

              // Envoyer un message PLAYER_JOINED via WebSocket
              final joinMessage = {
                'type': 'PLAYER_JOINED',
                'payload': {
                  'playerId': currentUserId,
                  'username': currentUsername,
                  'mapId': mapId,
                  'teamId': null,
                }
              };

              _webSocketService.sendMessage(
                  '/app/player-joined', joinMessage as WebSocketMessage);
              _webSocketService.subscribeToField(field!.id!);
            } else {
              print("❌ La carte sélectionnée n'est pas liée à un terrain.");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Aucun terrain associé à cette carte."),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            print("❌ Impossible de récupérer les détails de la carte.");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                Text("Impossible de récupérer les détails de la carte."),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          print(
              '❌ Erreur lors de la récupération des détails de la carte : $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Erreur lors de la récupération des détails de la carte'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    // Retirer de la liste des invitations en attente
    _pendingInvitations.removeWhere((inv) {
      final invToJson = inv.toJson();
      final invPayload = invToJson['payload'] ?? {};
      return invPayload['fromUserId'] == fromUserId &&
          invPayload['mapId'] == mapId;
    });

    notifyListeners();
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
