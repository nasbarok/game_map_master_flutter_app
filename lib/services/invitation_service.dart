import 'dart:async';

import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/game_state_service.dart';
import '../../services/websocket_service.dart';
import '../models/game_map.dart';
import '../models/invitation.dart';
import '../models/websocket/game_invitation_message.dart';
import '../models/websocket/invitation_response_message.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

import 'invitation_api_service.dart';

class InvitationService extends ChangeNotifier {
  final WebSocketService _webSocketService;
  final AuthService _authService;
  final GameStateService _gameStateService;
  final InvitationApiService _invitationApiService;

  StreamSubscription<WebSocketMessage>? _messageSubscription;

  InvitationService(this._webSocketService, this._authService,
      this._gameStateService, this._invitationApiService) {
    _messageSubscription = _webSocketService.messageStream.listen(
        _handleWebSocketMessage as void Function(WebSocketMessage event)?);
  }

  // listes depuis DB
  List<Invitation> _sentInvitations = [];
  List<Invitation> _receivedInvitations = [];

  List<Invitation> get sentInvitations => List.unmodifiable(_sentInvitations);
  List<Invitation> get receivedInvitations => List.unmodifiable(_receivedInvitations);
  int get sentPendingCount => _sentInvitations.where((i) => i.isPending).length;

  List<Invitation> get receivedPendingInvitations =>
      _receivedInvitations.where((i) => i.isPending).toList(growable: false);

  List<WebSocketMessage> get pendingInvitations => [];

  List<WebSocketMessage> get sentInvitationsOld => [];
  void Function(Map<String, dynamic> invitation)? onInvitationReceivedDialog;

  get baseUrl => null;

  bool canSendInvitations() {
    // Vérifier si l'utilisateur est un host et si son terrain est ouvert
    final user = _authService.currentUser;
    return user != null &&
        user.hasRole('HOST') &&
        _gameStateService.isTerrainOpen;
  }

  Future<void> sendInvitation(int userId) async {
    if (!canSendInvitations()) {
      throw Exception(
          'Vous devez être un host avec un terrain ouvert pour envoyer des invitations');
    }

    final fieldId = _gameStateService.selectedMap!.field!.id!;

    try {
      // 1. Créer/récupérer l'invitation en base
      final invitation =
          await _invitationApiService.createOrGetInvitation(fieldId, userId);

      // 2. Envoyer le WebSocket seulement si l'invitation est PENDING
/*      if (invitation.isPending) {
        final wsMessage = GameInvitationMessage(
          fieldId: fieldId,
          senderId: _authService.currentUser!.id!,
          targetUserId: userId,
        );
        await _webSocketService.sendMessage('/app/invitation', wsMessage);
        logger.d(
            '✅ Invitation WebSocket envoyée pour ${invitation.targetUsername}');
      } else {
        logger.d(
            'ℹ️ Invitation déjà existante avec statut: ${invitation.status}');
      }*/
    } catch (e) {
      logger.e('Erreur lors de l\'envoi d\'invitation: $e');
      rethrow;
    }
  }

  void _Old_handleWebSocketMessage(WebSocketMessage message) {
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
          //_pendingInvitations.add(message);
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

  /// Répondre à une invitation
  Future<void> respondToInvitation(
      BuildContext context, int invitationId, bool accept) async {
    try {
      // 1. Répondre via API
      final updatedInvitation =
          await _invitationApiService.respondToInvitation(invitationId, accept);

      // 2. Envoyer WebSocket de réponse
      final response = InvitationResponseMessage(
        senderId: _authService.currentUser!.id!,
        targetUserId: updatedInvitation.senderId,
        fieldId: updatedInvitation.fieldId,
        accepted: accept,
        fromUsername: _authService.currentUser!.username,
        mapName: updatedInvitation.fieldName,
      );

      await _webSocketService.sendMessage('/app/invitation-response', response);

      logger.d('✅ Réponse à l\'invitation: ${accept ? "Acceptée" : "Refusée"}');

      // 3. Si accepté, connecter au terrain
      if (accept) {
        final currentUser = _authService.currentUser;
        final isCurrentUserHost = currentUser?.hasRole('HOST') ?? false;

        if (isCurrentUserHost && _gameStateService.canStartHostVisit()) {
          // 🆕 CAS HOST VISITEUR
          await _handleHostVisitAcceptance(context, updatedInvitation);
        } else {
          // CAS GAMER NORMAL
          await _handleGamerAcceptance(context, updatedInvitation);
        }
      }

      // 3. Refresh automatique des invitations reçues
      await loadReceivedInvitations();

      // 4. Rafraîchir les invitations reçues
      await loadReceivedInvitations();

      logger.d('✅ Réponse à l\'invitation: ${accept ? "Acceptée" : "Refusée"}');
    } catch (e) {
      logger.e('Erreur lors de la réponse à l\'invitation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erreur lors du traitement de l'invitation"),
            backgroundColor: Colors.red),
      );
    }
  }

  /// Méthode de compatibilité pour l'ancienne signature
  Future<void> respondToInvitationOld(BuildContext context,
      Map<String, dynamic> invitationJson, bool accept) async {
    // Extraire l'ID de l'invitation depuis le JSON
    final invitationId = invitationJson['id'] as int?;
    if (invitationId != null) {
      await respondToInvitation(context, invitationId, accept);
    }
  }

  /// Charger les invitations envoyées depuis la DB
  Future<void> loadSentInvitations() async {
    if (_gameStateService.selectedMap?.field?.id == null) return;

    try {
      final fieldId = _gameStateService.selectedMap!.field!.id!;
      _sentInvitations =
          await _invitationApiService.getSentInvitations(fieldId);
      notifyListeners();
      logger.d('✅ ${_sentInvitations.length} invitations envoyées chargées');
    } catch (e) {
      logger.e('Erreur lors du chargement des invitations envoyées: $e');
    }
  }

  /// Charger les invitations reçues depuis la DB
  Future<void> loadReceivedInvitations() async {
    try {
      _receivedInvitations =
          await _invitationApiService.getReceivedInvitations();
      notifyListeners();
      logger.d('✅ ${_receivedInvitations.length} invitations reçues chargées');
    } catch (e) {
      logger.e('Erreur lors du chargement des invitations reçues: $e');
    }
  }


  /// Annuler une invitation
  Future<void> cancelInvitation(int invitationId) async {
    try {
      await _invitationApiService.cancelInvitation(invitationId);
      await loadSentInvitations();
      logger.d('✅ Invitation annulée');
    } catch (e) {
      logger.e('Erreur lors de l\'annulation de l\'invitation: $e');
      rethrow;
    }
  }

  /// Vérifier si une invitation pending existe déjà
  bool hasPendingInvitation(int targetUserId) {
    return _sentInvitations.any((invitation) =>
        invitation.targetUserId == targetUserId && invitation.isPending);
  }

  /// Compter les invitations en attente envoyées
  Future<int> countPendingInvitations() async {
    if (_gameStateService.selectedMap?.field?.id == null) return 0;

    try {
      final fieldId = _gameStateService.selectedMap!.field!.id!;
      return await _invitationApiService.countPendingInvitations(fieldId);
    } catch (e) {
      return _sentInvitations.where((inv) => inv.isPending).length;
    }
  }

  /// Compter les invitations reçues en attente
  Future<int> countReceivedPendingInvitations() async {
    try {
      return await _invitationApiService.countReceivedPendingInvitations();
    } catch (e) {
      return _receivedInvitations.where((inv) => inv.isPending).length;
    }
  }

  // Garder la logique WebSocket existante pour les notifications temps réel
  void _handleWebSocketMessage(WebSocketMessage message) {
    switch (message.type) {
      case 'GAME_INVITATION':
        _handleGameInvitation(message);
        break;
      case 'INVITATION_RESPONSE':
        _handleInvitationResponse(message);
        break;
    }
  }

  void _handleGameInvitation(WebSocketMessage message) {
    // 1) rafraîchir la liste depuis l’API (source de vérité)
    loadReceivedInvitations();

    // 2) afficher un dialog immédiat si demandé
    if (onInvitationReceivedDialog != null) {
      final json = message.toJson();
      final payload = (json['payload'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      onInvitationReceivedDialog!(payload);
    }
  }

  void _handleInvitationResponse(WebSocketMessage message) {
    // Notification temps réel + refresh des invitations envoyées
    loadSentInvitations();
  }

  /// 🆕 Gérer l'acceptation d'invitation par un host (mode visiteur)
  Future<void> _handleHostVisitAcceptance(BuildContext context, Invitation invitation) async {
    try {
      // 1. Récupérer les informations du terrain visité
      final apiService = GetIt.I<ApiService>();
      final fieldData = await apiService.get('fields/${invitation.fieldId}');

      // 2. Créer un GameMap temporaire pour le terrain visité
      final visitedMap = GameMap.fromJson(fieldData);

      // 3. Démarrer la visite host
      _gameStateService.startHostVisit(visitedMap);

      // 4. Connecter au terrain comme un gamer
      _gameStateService.restoreSessionIfNeeded(apiService, invitation.fieldId);

      // 5. Navigation vers GameLobbyScreen
      if (context.mounted) {
        context.go('/gamer/lobby');
      }

      // 6. Afficher notification
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connecté au terrain ${invitation.fieldName} en tant que visiteur'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }

      logger.d('🏠➡️🎮 Host connecté en visiteur sur: ${invitation.fieldName}');

    } catch (e) {
      logger.e('Erreur lors de la connexion host visiteur: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la connexion au terrain'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Gérer l'acceptation d'invitation par un gamer normal
  Future<void> _handleGamerAcceptance(BuildContext context, Invitation invitation) async {
    try {
      final apiService = GetIt.I<ApiService>();
      _gameStateService.restoreSessionIfNeeded(apiService, invitation.fieldId);

      if (context.mounted) {
        context.go('/gamer/lobby');
      }

      logger.d('🎮 Gamer connecté au terrain: ${invitation.fieldName}');

    } catch (e) {
      logger.e('Erreur lors de la connexion gamer: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la connexion au terrain'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
