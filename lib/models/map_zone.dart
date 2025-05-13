import "coordinate.dart";
import "dart:convert"; // For potential use if properties were complex

class MapZone {
  final String id;
  final String name;
  final String type;
  final String color;
  final List<Coordinate> zoneShape;
  final Map<String, dynamic>? properties; // Changed to Map<String, dynamic> for flexibility

  MapZone({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.zoneShape,
    this.properties,
  });

  factory MapZone.fromJson(Map<String, dynamic> json) {
    return MapZone(
      id: json["id"] as String,
      name: json["name"] as String,
      type: json["type"] as String,
      color: json["color"] as String,
      zoneShape: (json["zoneShape"] as List<dynamic>)
          .map((item) => Coordinate.fromJson(item as Map<String, dynamic>))
          .toList(),
      properties: json["properties"] != null ? Map<String, dynamic>.from(json["properties"] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "type": type,
      "color": color,
      "zoneShape": zoneShape.map((coord) => coord.toJson()).toList(),
      "properties": properties,
    };
  }
}

