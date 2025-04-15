import 'field.dart';

class GameSession {
  final int? id;
  final Field? field;
  final bool active;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status; // "WAITING", "RUNNING", "COMPLETED"

  GameSession({
    this.id,
    this.field,
    required this.active,
    this.startTime,
    this.endTime,
    required this.status,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as int?,
      field: json['field'] != null ? Field.fromJson(json['field']) : null,
      active: json['active'] as bool,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field': field?.toJson(),
      'active': active,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status,
    };
  }
}
