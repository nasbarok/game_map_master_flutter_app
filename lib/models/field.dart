class Field {
  final int? id;
  final String name;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? sizeX;
  final double? sizeY;

  Field({
    this.id,
    required this.name,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.sizeX,
    this.sizeY,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      sizeX: json['sizeX']?.toDouble(),
      sizeY: json['sizeY']?.toDouble(),
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
    };
  }
}
