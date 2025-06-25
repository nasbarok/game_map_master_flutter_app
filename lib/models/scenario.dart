import 'package:game_map_master_flutter_app/models/user.dart';

class Scenario {
  final int? id;
  final String name;
  final String? description;
  final String type;
  final int? gameMapId;
  final User? creator;

  final int? gameSessionId;
  final bool active;
  final DateTime? startTime;
  final DateTime? endTime;

  Scenario({
    this.id,
    required this.name,
    this.description,
    required this.type,
    this.gameMapId,
    required this.creator,
    this.gameSessionId,
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
      gameMapId: json['gameMap'] != null ? json['gameMap']['id'] : null,
      creator: json['creator'] != null ? User.fromJson(json['creator']) : null,
      gameSessionId: json['gameSessionId'],
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
      'gameMap': gameMapId != null ? {'id': gameMapId} : null,
      'creator': creator?.toJson(),
      'gameSessionId': gameSessionId,
      'active': active,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  Scenario copyWith({
    int? id,
    String? name,
    String? description,
    String? type,
    int? gameMapId,
    User? creator,
    int? gameSessionId,
    bool? active,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return Scenario(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      gameMapId: gameMapId ?? this.gameMapId,
      creator: creator ?? this.creator,
      gameSessionId: gameSessionId ?? this.gameSessionId,
      active: active ?? this.active,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
