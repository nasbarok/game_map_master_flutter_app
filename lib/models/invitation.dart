import '../../models/scenario.dart';
import '../../models/team.dart';
import '../../models/user.dart';

class Invitation {
  final int id;
  final Scenario scenario;
  final User user;
  final Team? team;
  final String status; // "PENDING", "ACCEPTED", "DECLINED"
  final DateTime createdAt;
  final DateTime? respondedAt;

  Invitation({
    required this.id,
    required this.scenario,
    required this.user,
    this.team,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'],
      scenario: Scenario.fromJson(json['scenario']),
      user: User.fromJson(json['user']),
      team: json['team'] != null ? Team.fromJson(json['team']) : null,
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scenario': scenario.toJson(),
      'user': user.toJson(),
      'team': team?.toJson(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isDeclined => status == 'DECLINED';
}
