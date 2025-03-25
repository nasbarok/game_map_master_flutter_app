import 'dart:async';

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

  List<Map<String, dynamic>> _pendingInvitations = [];
  List<Map<String, dynamic>> _sentInvitations = [];
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  InvitationService(this._webSocketService, this._authService,
      this._gameStateService) {
    _messageSubscription =
        _webSocketService.messageStream.listen(_handleWebSocketMessage);
  }

  List<Map<String, dynamic>> get pendingInvitations => _pendingInvitations;

  List<Map<String, dynamic>> get sentInvitations => _sentInvitations;

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
      'mapName': _gameStateService.selectedMap!.name,
    };

    final invitation = {
      'type': 'GAME_INVITATION',
      'payload': invitationPayload,
      'timestamp': DateTime
          .now()
          .millisecondsSinceEpoch,
    };

    // Envoyer via WebSocket
    await _webSocketService.sendMessage('/app/invitation', invitation);

    // Ajouter à la liste des invitations envoyées
    _sentInvitations.add(invitation);
    notifyListeners();
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    if (message['type'] == 'GAME_INVITATION') {
      print('📬 Invitation de jeu reçue');

      final payload = message['payload'];

      print('🧾 Payload invitation : $payload');

      if (payload['toUserId'] == _authService.currentUser!.id) {
        _pendingInvitations.add(message);
        notifyListeners();

        // ➕ Affichage du dialogue si défini
        if (onInvitationReceivedDialog != null) {
          onInvitationReceivedDialog!(message);
        }
      }
    } else if (message['type'] == 'INVITATION_RESPONSE') {
      print('📬 Réponse à une invitation reçue');

      final response = message['payload'];

      print('🧾 Payload réponse : $response');

      if (response['fromUserId'] == _authService.currentUser!.id) {
        final index = _sentInvitations.indexWhere(
              (inv) =>
          inv['payload']['toUserId'] == response['toUserId'] &&
              inv['payload']['mapId'] == response['mapId'],
        );

        if (index >= 0) {
          _sentInvitations[index]['status'] =
          response['accepted'] ? 'accepted' : 'declined';
          notifyListeners();
        }
      }
    } else if (message['type'] == 'PLAYER_JOINED') {
      // Nouveau joueur a rejoint la partie
      final payload = message['payload'];
      print('👤 Joueur rejoint : ${payload['username']}');

      // Ajouter le joueur à la liste des joueurs connectés
      final player = {
        'id': payload['playerId'],
        'username': payload['username'],
        'teamId': payload['teamId'],
      };

      _gameStateService.addConnectedPlayer(player);
    } else if (message['type'] == 'PLAYER_LEFT') {
      // Un joueur a quitté la partie
      final payload = message['payload'];
      print('👋 Joueur parti : ${payload['username']}');

      // Supprimer le joueur de la liste des joueurs connectés
      _gameStateService.removeConnectedPlayer(payload['playerId']);
    } else if (message['type'] == 'TERRAIN_CLOSED') {
      // Le terrain a été fermé
      print('🚪 Terrain fermé');

      // Si l'utilisateur n'est pas l'hôte, il doit être déconnecté
      if (!_authService.currentUser!.hasRole('HOST')) {
        _gameStateService.reset();
      }
    }
  }

  Future<void> respondToInvitation(Map<String, dynamic> invitation,
      bool accept) async {
    final payload = invitation['payload'];

    final response = {
      'type': 'INVITATION_RESPONSE',
      'payload': {
        'fromUserId': payload['toUserId'],
        'toUserId': payload['fromUserId'],
        'mapId': payload['mapId'],
        'accepted': accept,
        'timestamp': DateTime.now().toIso8601String(),
      }
    };

    print('📤 Envoi de la réponse à l’invitation : accept=$accept');
    print('🧾 Invitation envoyée : ${jsonEncode(response)}');
    print('📨 Envoi via STOMP vers /app/invitation-response...');

    // ✅ Envoi via STOMP avec destination explicite
    await _webSocketService.sendMessage('/app/invitation-response', response);

    print('✅ Réponse envoyée avec succès');

    // Si l'invitation est acceptée, mettre à jour l'état du jeu
    if (accept) {
      // Pour le joueur qui accepte l'invitation
      if (_authService.currentUser!.id == payload['toUserId']) {
        // Mettre à jour l'état du jeu avec les informations de la carte
        final map = GameMap(
          id: payload['mapId'],
          name: payload['mapName'],
          imageUrl: '', // À compléter si disponible
          description: '', // À compléter si disponible
        );

        _gameStateService.selectMap(map);
        _gameStateService.toggleTerrainOpen(); // Ouvrir le terrain

        // Ajouter le joueur à la liste des joueurs connectés
        final player = {
          'id': _authService.currentUser!.id,
          'username': _authService.currentUser!.username,
          'teamId': null, // Pas d'équipe par défaut
        };

        _gameStateService.addConnectedPlayer(player);

        // Envoyer un message PLAYER_JOINED via WebSocket
        final joinMessage = {
          'type': 'PLAYER_JOINED',
          'payload': {
            'playerId': _authService.currentUser!.id,
            'username': _authService.currentUser!.username,
            'mapId': payload['mapId'],
            'teamId': null,
          }
        };

        _webSocketService.sendMessage('/app/player-joined', joinMessage);
      }
    }

    // Retirer de la liste des invitations en attente
    _pendingInvitations.removeWhere(
            (inv) =>
        inv['payload']['fromUserId'] == payload['fromUserId'] &&
            inv['payload']['mapId'] == payload['mapId']
    );

    notifyListeners();
  }

  // Récupérer toutes les invitations pour l'utilisateur connecté
  Future<List<Invitation>> getMyInvitations() async {
    final url = '$baseUrl/api/invitations/me';

    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> invitationsJson = jsonDecode(response.body);
      return invitationsJson.map((json) => Invitation.fromJson(json)).toList();
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
      return invitationsJson.map((json) => Invitation.fromJson(json)).toList();
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
