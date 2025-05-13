import "coordinate.dart"; // Assuming coordinate.dart is in the same directory

class MapPointOfInterest {
  final String id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final String iconIdentifier; // e.g., "ammo_icon", "flag_icon"
  final String type; // e.g., "AMMO_CACHE", "FLAG"
  final Map<String, dynamic>? properties; // Changed to Map<String, dynamic> for flexibility

  MapPointOfInterest({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.iconIdentifier,
    required this.type,
    this.properties,
  });

  Coordinate get position => Coordinate(latitude: latitude, longitude: longitude);

  factory MapPointOfInterest.fromJson(Map<String, dynamic> json) {
    return MapPointOfInterest(
      id: json["id"] as String,
      name: json["name"] as String,
      description: json["description"] as String?,
      latitude: (json["latitude"] as num).toDouble(),
      longitude: (json["longitude"] as num).toDouble(),
      iconIdentifier: json["iconIdentifier"] as String,
      type: json["type"] as String,
      properties: json["properties"] != null ? Map<String, dynamic>.from(json["properties"] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "latitude": latitude,
      "longitude": longitude,
      "iconIdentifier": iconIdentifier,
      "type": type,
      "properties": properties,
    };
  }
}

