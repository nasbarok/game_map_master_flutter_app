import 'coordinate.dart';

class MapZone {
  final String id;
  final String name;
  final String type;
  final String color;
  final List<Coordinate> zoneShape;
  final Map<String, dynamic>? properties;
  final bool visible;

  MapZone({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.zoneShape,
    this.properties,
    this.visible = true, // Valeur par défaut
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
      properties: json["properties"] != null
          ? Map<String, dynamic>.from(json["properties"] as Map)
          : null,
      visible: json.containsKey("visible") ? json["visible"] as bool : true,
    );
  }

  get coordinates => null;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "type": type,
      "color": color,
      "zoneShape": zoneShape.map((coord) => coord.toJson()).toList(),
      "properties": properties,
      "visible": visible,
    };
  }

  MapZone copyWith({
    String? id,
    String? name,
    String? type,
    String? color,
    List<Coordinate>? zoneShape,
    Map<String, dynamic>? properties,
    bool? visible,
  }) {
    return MapZone(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      zoneShape: zoneShape ?? this.zoneShape,
      properties: properties ?? this.properties,
      visible: visible ?? this.visible,
    );
  }
}
