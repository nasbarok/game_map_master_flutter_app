import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/game_state_service.dart';
import '../../services/websocket_service.dart';

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

    // Retirer de la liste des invitations en attente
    _pendingInvitations.removeWhere(
            (inv) =>
        inv['payload']['fromUserId'] == payload['fromUserId'] &&
            inv['payload']['mapId'] == payload['mapId']
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

}
