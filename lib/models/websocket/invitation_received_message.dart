import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';
import '../../models/invitation.dart'; // <-- pour toInvitation()

class InvitationReceivedMessage extends WebSocketMessage {
  // 🔹 Garde tes noms historiques
  final int fieldId;
  final int senderId;
  final int targetUserId;
  final String fromUsername; // alias de senderUsername
  final String mapName;      // alias de fieldName

  // 🔹 Champs nécessaires pour construire un Invitation complet
  final int id;
  final String targetUsername;
  final String status; // "PENDING", "ACCEPTED", ...
  final DateTime createdAt;
  final DateTime? respondedAt;

  InvitationReceivedMessage({
    required this.fieldId,
    required this.senderId,
    required this.targetUserId,
    required this.fromUsername,
    required this.mapName,
    required this.id,
    required this.targetUsername,
    required this.status,
    required this.createdAt,
    required this.respondedAt,
  }) : super('INVITATION_RECEIVED', senderId);

  factory InvitationReceivedMessage.fromJson(Map<String, dynamic> json) {
    final p = (json['payload'] as Map).cast<String, dynamic>();
    return InvitationReceivedMessage(
      fieldId: (p['fieldId'] as num).toInt(),
      senderId: (p['senderId'] as num).toInt(),
      targetUserId: (p['targetUserId'] as num).toInt(),

      // 🔁 mapping alias (JSON -> tes props historiques)
      fromUsername: (p['senderUsername'] as String?) ?? '',
      mapName: (p['fieldName'] as String?) ?? '',

      // 🔹 champs manquants mais présents dans le payload
      id: (p['id'] as num).toInt(),
      targetUsername: (p['targetUsername'] as String?) ?? '',
      status: (p['status'] as String?) ?? 'PENDING',
      createdAt: DateTime.parse(p['createdAt'] as String),
      respondedAt: (p['respondedAt'] as String?) != null
          ? DateTime.parse(p['respondedAt'] as String)
          : null,
    );
  }

  /// Adaptateur propre -> construit directement ton modèle `Invitation`
  Invitation toInvitation() {
    return Invitation(
      id: id,
      scenario: null,
      fieldId: fieldId,
      fieldName: mapName,             // alias inverse
      senderId: senderId,
      senderUsername: fromUsername,   // alias inverse
      targetUserId: targetUserId,
      targetUsername: targetUsername,
      team: null,
      status: status,
      createdAt: createdAt,
      respondedAt: respondedAt,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    // ⚠️ Évite d'utiliser un timestamp au type incertain
    return {
      'type': type,
      'senderId': senderId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': {
        'id': id,
        'fieldId': fieldId,
        'fieldName': mapName,            // on réémet côté serveur
        'senderId': senderId,
        'senderUsername': fromUsername,  // on réémet côté serveur
        'targetUserId': targetUserId,
        'targetUsername': targetUsername,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
      },
    };
  }
}
