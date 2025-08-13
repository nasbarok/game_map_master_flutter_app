import '../../models/scenario.dart';
import '../../models/team.dart';

class Invitation {
  final int id;
  final Scenario? scenario;
  final int fieldId;
  final String fieldName;
  final int senderId;
  final String senderUsername;
  final int targetUserId;
  final String targetUsername;
  final Team? team;
  final String status; // "PENDING", "ACCEPTED", "DECLINED", "CANCELED", "EXPIRED"
  final DateTime createdAt;
  final DateTime? respondedAt;

  Invitation({
    required this.id,
    required this.scenario,
    required this.fieldId,
    required this.fieldName,
    required this.senderId,
    required this.senderUsername,
    required this.targetUserId,
    required this.targetUsername,
    this.team,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'],
      scenario: (json['scenario'] is Map)
          ? Scenario.fromJson((json['scenario'] as Map).cast<String, dynamic>())
          : null,
      fieldId: json['fieldId'],
      fieldName: json['fieldName'],
      senderId: json['senderId'],
      senderUsername: json['senderUsername'],
      targetUserId: json['targetUserId'],
      targetUsername: json['targetUsername'],
      team: json['team'] != null ? Team.fromJson(json['team']) : null,
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scenario': scenario?.toJson(),
      'fieldId': fieldId,
      'fieldName': fieldName,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'targetUserId': targetUserId,
      'targetUsername': targetUsername,
      'team': team?.toJson(),
      'status': status,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'respondedAt': respondedAt?.toUtc().toIso8601String(),
    };
  }


  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isDeclined => status == 'DECLINED';
  bool get isCanceled => status == 'CANCELED';
  bool get isExpired => status == 'EXPIRED';
}
