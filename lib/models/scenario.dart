class Scenario {
  final int? id;
  final String name;
  final String? description;
  final String type;
  final int? gameMapId;
  final bool active;
  final DateTime? startTime;
  final DateTime? endTime;

  Scenario({
    this.id,
    required this.name,
    this.description,
    required this.type,
    this.gameMapId,
    this.active = false,
    this.startTime,
    this.endTime,
  });

  factory Scenario.fromJson(Map<String, dynamic> json) {
    return Scenario(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      gameMapId: json['gameMapId'],
      active: json['active'] ?? false,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'gameMapId': gameMapId,
      'active': active,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }
}
