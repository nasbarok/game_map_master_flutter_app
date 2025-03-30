import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/invitation.dart';

class InvitationApiService {
  final String baseUrl;
  final http.Client client;

  InvitationApiService({required this.baseUrl, required this.client});

  // Créer une invitation
  Future<Invitation> createInvitation(int fieldId, int userId) async {
    final url = '$baseUrl/api/invitations';
    final queryParams = {
      'fieldId': fieldId.toString(),
      'userId': userId.toString(),
    };
    
    final response = await client.post(
      Uri.parse(url).replace(queryParameters: queryParams),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 201) {
      return Invitation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create invitation: ${response.body}');
    }
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

  // Récupérer les invitations pour un scénario
  Future<List<Invitation>> getInvitationsForScenario(int scenarioId) async {
    final url = '$baseUrl/api/invitations/scenario/$scenarioId';
    
    final response = await client.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final List<dynamic> invitationsJson = jsonDecode(response.body);
      return invitationsJson.map((json) => Invitation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get invitations for scenario: ${response.body}');
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

  // Annuler une invitation
  Future<void> cancelInvitation(int invitationId) async {
    final url = '$baseUrl/api/invitations/$invitationId';
    
    final response = await client.delete(Uri.parse(url));
    
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel invitation: ${response.body}');
    }
  }
}
