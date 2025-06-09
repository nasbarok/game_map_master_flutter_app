import 'package:flutter/material.dart';

/// Modèle représentant un site de bombe sur la carte
class BombSite {
  /// Identifiant unique du site de bombe
  final int? id;

  /// Identifiant du scénario auquel ce site appartient
  final int scenarioId;
  final int bombOperationScenarioId;

  /// Nom du site (ex: "Site A", "Site B")
  final String name;

  /// Latitude du site sur la carte
  final double latitude;

  /// Longitude du site sur la carte
  final double longitude;

  /// Rayon en mètres autour du point central où la bombe peut être posée/désamorcée
  final double radius;

  /// Couleur du marqueur sur la carte (format hexadécimal)
  final String? color;

  final bool active;
  /// Constructeur
  BombSite({
    this.id,
    required this.scenarioId,
    required this.bombOperationScenarioId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.color,
    this.active = false,
  });

  /// Crée une instance de BombSite à partir d'un objet JSON
  factory BombSite.fromJson(Map<String, dynamic> json) {
    return BombSite(
      id: json['id'],
      scenarioId: json['scenarioId'],
      bombOperationScenarioId: json['bombOperationScenarioId'],
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      radius: json['radius'].toDouble(),
      color: json['color'],
      active: json['active'] ?? false, // gestion de null-safe
    );
  }

  /// Convertit cette instance en objet JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scenarioId': scenarioId,
      'bombOperationScenarioId': bombOperationScenarioId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'color': color,
      'active': active,
    };
  }

  /// Crée une copie de cette instance avec les valeurs spécifiées remplacées
  BombSite copyWith({
    int? id,
    int? scenarioId,
    int? bombOperationScenarioId,
    String? name,
    double? latitude,
    double? longitude,
    double? radius,
    String? color,
    bool? active,
  }) {
    return BombSite(
      id: id ?? this.id,
      scenarioId: scenarioId ?? this.scenarioId,
      bombOperationScenarioId: bombOperationScenarioId ?? this.bombOperationScenarioId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      color: color ?? this.color,
      active: active ?? this.active,
    );
  }

  /// Obtient la couleur du marqueur sous forme d'objet Color
  Color getColor(BuildContext context) {
    if (color == null || color!.isEmpty) {
      return Theme.of(context).colorScheme.primary;
    }

    try {
      final colorValue = int.parse(color!.replaceAll('#', '0xFF'));
      return Color(colorValue);
    } catch (e) {
      return Theme.of(context).colorScheme.primary;
    }
  }
}
