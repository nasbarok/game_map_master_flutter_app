class GameMap {
  final int? id;
  final String name;
  final String? description;
  final int? fieldId;
  final int? ownerId;
  final List<int>? scenarioIds;
  final String? imageUrl;
  final double? scale;

  GameMap({
    this.id,
    required this.name,
    this.description,
    this.fieldId,
    this.ownerId,
    this.scenarioIds,
    this.imageUrl,
    this.scale,
  });

  factory GameMap.fromJson(Map<String, dynamic> json) {
    return GameMap(
      id: json['id'] as int?,
      name: json['name'] ?? 'Sans nom',
      description: json['description'],
      fieldId: json['fieldId'] as int?,
      ownerId: json['ownerId'] as int?,
      scenarioIds: json['scenarioIds'] != null
          ? List<int>.from(json['scenarioIds'])
          : null,
      imageUrl: json['imageUrl'],
      scale: (json['scale'] as num?)?.toDouble(),
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
    };
  }
}
