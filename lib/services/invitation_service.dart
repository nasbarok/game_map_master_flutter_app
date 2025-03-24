import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  InvitationService(this._webSocketService, this._authService, this._gameStateService) {
    _messageSubscription = _webSocketService.messageStream.listen(_handleWebSocketMessage);
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
      throw Exception('Vous devez être un host avec un terrain ouvert pour envoyer des invitations');
    }
    
    final invitation = {
      'type': 'invitation',
      'fromUserId': _authService.currentUser!.id,
      'fromUsername': _authService.currentUser!.username,
      'toUserId': userId,
      'toUsername': username,
      'mapId': _gameStateService.selectedMap!.id,
      'mapName': _gameStateService.selectedMap!.name,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Envoyer via WebSocket
    await _webSocketService.sendMessage('/app/invitation', invitation);
    
    // Ajouter à la liste des invitations envoyées
    _sentInvitations.add(invitation);
    notifyListeners();
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    if (message['type'] == 'invitation' &&
        message['toUserId'] == _authService.currentUser!.id) {
      _pendingInvitations.add(message);
      notifyListeners();

      // ➕ Appel de la fonction callback si définie
      if (onInvitationReceivedDialog != null) {
        onInvitationReceivedDialog!(message);
      }
    } else if (message['type'] == 'invitation_response' &&
        message['fromUserId'] == _authService.currentUser!.id) {
      final index = _sentInvitations.indexWhere(
              (inv) => inv['toUserId'] == message['toUserId'] &&
              inv['mapId'] == message['mapId']
      );

      if (index >= 0) {
        _sentInvitations[index]['status'] = message['accepted'] ? 'accepted' : 'declined';
        notifyListeners();
      }
    }
  }
  
  Future<void> respondToInvitation(Map<String, dynamic> invitation, bool accept) async {
    final response = {
      'type': 'invitation_response',
      'fromUserId': invitation['toUserId'],
      'toUserId': invitation['fromUserId'],
      'mapId': invitation['mapId'],
      'accepted': accept,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // ✅ Envoi via STOMP avec destination explicite
    await _webSocketService.sendMessage('/app/invitation-response', response);
    
    // Retirer de la liste des invitations en attente
    _pendingInvitations.removeWhere(
      (inv) => inv['fromUserId'] == invitation['fromUserId'] && 
              inv['mapId'] == invitation['mapId']
    );
    
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

}
