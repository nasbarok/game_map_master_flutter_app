import 'user.dart';

class Field {
  final int? id;
  final String name;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? sizeX;
  final double? sizeY;
  final String? imageUrl;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final bool active;
  final User? owner;

  Field({
    this.id,
    required this.name,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.sizeX,
    this.sizeY,
    this.imageUrl,
    this.openedAt,
    this.closedAt,
    this.active = false,
    this.owner,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'],
      name: json['name'] ?? 'Terrain sans nom',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      sizeX: (json['sizeX'] as num?)?.toDouble(),
      sizeY: (json['sizeY'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      openedAt: json['openedAt'] != null ? DateTime.parse(json['openedAt']) : null,
      closedAt: json['closedAt'] != null ? DateTime.parse(json['closedAt']) : null,
      active: json['active'] ?? false,
      owner: json['owner'] != null ? User.fromJson(json['owner']) : null,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'sizeX': sizeX,
      'sizeY': sizeY,
      'imageUrl': imageUrl,
      'openedAt': openedAt?.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'active': active,
      'owner': owner?.toJson(),
    };
  }
}