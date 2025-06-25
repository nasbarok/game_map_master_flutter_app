import 'package:game_map_master_flutter_app/models/coordinate.dart';

/// Modèle représentant la position d'un joueur à un moment donné
class PlayerPosition {
  /// Identifiant unique de la position
  final int? id;
  
  /// Identifiant de l'utilisateur
  final int userId;
  
  /// Identifiant de la session de jeu
  final int gameSessionId;
  
  /// Identifiant de l'équipe (optionnel)
  final int? teamId;
  
  /// Latitude de la position
  final double latitude;
  
  /// Longitude de la position
  final double longitude;
  
  /// Horodatage de la position
  final DateTime timestamp;

  /// Constructeur
  PlayerPosition({
    this.id,
    required this.userId,
    required this.gameSessionId,
    this.teamId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  /// Crée une instance de PlayerPosition à partir d'un objet JSON
  factory PlayerPosition.fromJson(Map<String, dynamic> json) {
    return PlayerPosition(
      id: json['id'],
      userId: json['userId'],
      gameSessionId: json['gameSessionId'],
      teamId: json['teamId'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  /// Convertit cette instance en objet JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'gameSessionId': gameSessionId,
      'teamId': teamId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  /// Convertit cette position en objet Coordinate
  Coordinate toCoordinate() {
    return Coordinate(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
