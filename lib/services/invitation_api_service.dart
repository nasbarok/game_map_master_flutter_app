import '../../models/invitation.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

class InvitationApiService {
  final ApiService _apiService;
  final AuthService _authService;

  InvitationApiService(this._apiService, this._authService);

  /// Créer ou récupérer une invitation (idempotent)
  Future<Invitation> createOrGetInvitation(
      int fieldId, int targetUserId) async {
    try {
      final response = await _apiService.post('invitations', {
        'fieldId': fieldId,
        'targetUserId': targetUserId,
      });

      return Invitation.fromJson(response);
    } catch (e) {
      logger.e('Erreur création invitation: $e');
      rethrow;
    }
  }

  /// Récupérer les invitations envoyées pour un terrain
  Future<List<Invitation>> getSentInvitations(int fieldId) async {
    try {
      final response =
          await _apiService.get('invitations/sent?fieldId=$fieldId');

      final List<dynamic> invitationsJson = response as List;
      return invitationsJson.map((json) => Invitation.fromJson(json)).toList();
    } catch (e) {
      logger.e('Erreur récupération invitations envoyées: $e');
      return [];
    }
  }

  /// Récupérer les invitations reçues
  Future<List<Invitation>> getReceivedInvitations() async {
    try {
      final response = await _apiService.get('invitations/received');

      final List<dynamic> invitationsJson = response as List;
      return invitationsJson.map((json) => Invitation.fromJson(json)).toList();
    } catch (e) {
      logger.e('Erreur récupération invitations reçues: $e');
      return [];
    }
  }

  /// Répondre à une invitation
  Future<Invitation> respondToInvitation(
      int invitationId, bool accepted) async {
    try {
      final response =
          await _apiService.post('invitations/$invitationId/respond', {
        'accepted': accepted,
      });

      return Invitation.fromJson(response);
    } catch (e) {
      logger.e('Erreur réponse invitation: $e');
      rethrow;
    }
  }

  /// Annuler une invitation
  Future<void> cancelInvitation(int invitationId) async {
    try {
      await _apiService.delete('invitations/$invitationId');
    } catch (e) {
      logger.e('Erreur annulation invitation: $e');
      rethrow;
    }
  }

  /// Compter les invitations en attente envoyées
  Future<int> countPendingInvitations(int fieldId) async {
    try {
      final response =
          await _apiService.get('invitations/count/pending?fieldId=$fieldId');
      return response as int;
    } catch (e) {
      logger.e('Erreur comptage invitations envoyées: $e');
      return 0;
    }
  }

  /// Compter les invitations reçues en attente
  Future<int> countReceivedPendingInvitations() async {
    try {
      final response = await _apiService.get('invitations/count/received');
      return response as int;
    } catch (e) {
      logger.e('Erreur comptage invitations reçues: $e');
      return 0;
    }
  }
}
