import 'dart:convert';

import 'package:game_map_master_flutter_app/models/user.dart';

import 'coordinate.dart';
import 'field.dart';
import 'map_point_of_interest.dart';
import 'map_zone.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

class GameMap {
  final int? id;
  late String name;
  late String? description;
  final int? fieldId;
  final int? ownerId;
  final List<int>? scenarioIds;
  final String? imageUrl;
  final double? scale;

  final User? owner;
  Field? field;

  // New fields for interactive map features
  late String? sourceAddress;
  late double? centerLatitude;
  late double? centerLongitude;
  late double? initialZoom;
  late String? fieldBoundaryJson; // Stores List<Coordinate> as JSON string
  late String? mapZonesJson; // Stores List<MapZone> as JSON string
  late String? mapPointsOfInterestJson; // Stores List<MapPointOfInterest> as JSON string

  // Fields for dual background images and their bounds
  late String? backgroundImageBase64; // Stores Base64 encoded static background image (standard map)
  late String? backgroundBoundsJson; // Stores LatLngBounds for standard map image as JSON string
  late String? satelliteImageBase64; // Stores Base64 encoded static background image (satellite view)
  late String? satelliteBoundsJson; // Stores LatLngBounds for satellite image as JSON string


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
    // New fields
    this.sourceAddress,
    this.centerLatitude,
    this.centerLongitude,
    this.initialZoom,
    this.fieldBoundaryJson,
    this.mapZonesJson,
    this.mapPointsOfInterestJson,
    this.backgroundImageBase64,
    this.backgroundBoundsJson,
    this.satelliteImageBase64,
    this.satelliteBoundsJson,
  });

  // Helper getters to deserialize JSON fields
  List<Coordinate>? get fieldBoundary {
    if (fieldBoundaryJson == null || fieldBoundaryJson!.isEmpty) {
      logger.w('[GameMap] ⚠️ fieldBoundaryJson est null');
      return null;
    }
    try {
      final List<dynamic> decodedJson = jsonDecode(fieldBoundaryJson!);
      final coords = decodedJson.map((item) => Coordinate.fromJson(item as Map<String, dynamic>)).toList();
      return coords;
    } catch (e, stack) {
      logger.e(stack);
      return null;
    }
  }

  List<MapZone>? get mapZones {
    if (mapZonesJson == null || mapZonesJson!.isEmpty) {
      logger.w('[GameMap] ⚠️ mapZonesJson est null ou vide');
      return null;
    }
    try {
      final List<dynamic> decodedJson = jsonDecode(mapZonesJson!);
      for (var item in decodedJson) {
        final zone = item as Map<String, dynamic>;
        if (!zone.containsKey('zoneShape') || zone['zoneShape'] == null || !(zone['zoneShape'] is List) || zone['zoneShape'].isEmpty) {
          logger.w('❌ Zone sans coordonnées : id=${zone['id']} name=${zone['name']}');
        }
        if (!zone.containsKey('color') || zone['color'] == null || zone['color'].toString().trim().length < 7) {
          logger.w('⚠️ Couleur de zone invalide ou vide : id=${zone['id']} color=${zone['color']}');
        }
      }
      return decodedJson.map((item) => MapZone.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e, stack) {
      logger.e('[GameMap] ❌ Erreur lors du parsing de mapZonesJson: $e');
      logger.e(stack);
      return null;
    }
  }


  List<MapPointOfInterest>? get mapPointsOfInterest {
    if (mapPointsOfInterestJson == null || mapPointsOfInterestJson!.isEmpty) return null;
    try {
      final List<dynamic> decodedJson = jsonDecode(mapPointsOfInterestJson!);
      return decodedJson.map((item) => MapPointOfInterest.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      logger.d('Error decoding mapPointsOfInterestJson: $e');
      return null;
    }
  }

  /// Vérifie si la carte a des coordonnées géographiques valides
  bool get hasValidCoordinates {
    return centerLatitude != null && centerLongitude != null;
  }

  /// Vérifie si la carte a une configuration interactive complète
  bool get hasInteractiveMapConfig {
    return hasValidCoordinates &&
           initialZoom != null &&
           fieldBoundaryJson != null &&
           fieldBoundaryJson!.isNotEmpty;
  }

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
      // New fields from JSON
      sourceAddress: json['sourceAddress'] as String?,
      centerLatitude: (json['centerLatitude'] as num?)?.toDouble(),
      centerLongitude: (json['centerLongitude'] as num?)?.toDouble(),
      initialZoom: (json['initialZoom'] as num?)?.toDouble(),
      fieldBoundaryJson: json['fieldBoundaryJson'] as String?,
      mapZonesJson: json['mapZonesJson'] as String?,
      mapPointsOfInterestJson: json['mapPointsOfInterestJson'] as String?,
      backgroundImageBase64: json['backgroundImageBase64'] as String?,
      backgroundBoundsJson: json['backgroundBoundsJson'] as String?, // New
      satelliteImageBase64: json['satelliteImageBase64'] as String?, // New
      satelliteBoundsJson: json['satelliteBoundsJson'] as String?, // New
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
      // New fields to JSON
      'sourceAddress': sourceAddress,
      'centerLatitude': centerLatitude,
      'centerLongitude': centerLongitude,
      'initialZoom': initialZoom,
      'fieldBoundaryJson': fieldBoundaryJson,
      'mapZonesJson': mapZonesJson,
      'mapPointsOfInterestJson': mapPointsOfInterestJson,
      'backgroundImageBase64': backgroundImageBase64,
      'backgroundBoundsJson': backgroundBoundsJson,
      'satelliteImageBase64': satelliteImageBase64,
      'satelliteBoundsJson': satelliteBoundsJson,
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
    // New fields for copyWith
    String? sourceAddress,
    double? centerLatitude,
    double? centerLongitude,
    double? initialZoom,
    String? fieldBoundaryJson,
    String? mapZonesJson,
    String? mapPointsOfInterestJson,
    String? backgroundImageBase64,
    String? backgroundBoundsJson,
    String? satelliteImageBase64,
    String? satelliteBoundsJson,
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
      // New fields
      sourceAddress: sourceAddress ?? this.sourceAddress,
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      initialZoom: initialZoom ?? this.initialZoom,
      fieldBoundaryJson: fieldBoundaryJson ?? this.fieldBoundaryJson,
      mapZonesJson: mapZonesJson ?? this.mapZonesJson,
      mapPointsOfInterestJson: mapPointsOfInterestJson ?? this.mapPointsOfInterestJson,
      backgroundImageBase64: backgroundImageBase64 ?? this.backgroundImageBase64,
      backgroundBoundsJson: backgroundBoundsJson ?? this.backgroundBoundsJson,
      satelliteImageBase64: satelliteImageBase64 ?? this.satelliteImageBase64,
      satelliteBoundsJson: satelliteBoundsJson ?? this.satelliteBoundsJson,
    );
  }
}
