import 'package:airsoft_game_map/models/user.dart';

import 'field.dart';

class GameMap {
  final int? id;
  final String name;
  final String? description;
  final int? fieldId;
  final int? ownerId;
  final List<int>? scenarioIds;
  final String? imageUrl;
  final double? scale;

  final User? owner;
  Field? field;

  GameMap({
    this.id,
    required this.name,
    this.description,
    this.fieldId,
    this.ownerId,
    this.scenarioIds,
    this.imageUrl,
    this.scale,
    this.owner,
    this.field,
  });

  factory GameMap.fromJson(Map<String, dynamic> json) {
    return GameMap(
      id: json['id'] as int?,
      name: json['name'] ?? 'Sans nom',
      description: json['description'] ?? '',
      fieldId: json['fieldId'] as int?,
      ownerId: json['ownerId'] as int?,
      scenarioIds: json['scenarioIds'] != null
          ? List<int>.from(json['scenarioIds'])
          : null,
      imageUrl: json['imageUrl'] ?? '',
      scale: (json['scale'] as num?)?.toDouble(),
      owner: json['owner'] != null ? User.fromJson(json['owner']) : null,
      field: json['field'] != null ? Field.fromJson(json['field']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'fieldId': fieldId,
      'ownerId': ownerId,
      'scenarioIds': scenarioIds,
      'imageUrl': imageUrl,
      'scale': scale,
      'owner': owner?.toJson(),
      'field': field?.toJson(),
    };
  }

  GameMap copyWith({
    int? id,
    String? name,
    String? description,
    int? fieldId,
    int? ownerId,
    List<int>? scenarioIds,
    String? imageUrl,
    double? scale,
    User? owner,
    Field? field,
  }) {
    return GameMap(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      fieldId: fieldId ?? this.fieldId,
      ownerId: ownerId ?? this.ownerId,
      scenarioIds: scenarioIds ?? this.scenarioIds,
      imageUrl: imageUrl ?? this.imageUrl,
      scale: scale ?? this.scale,
      owner: owner ?? this.owner,
      field: field ?? this.field,
    );
  }
}
