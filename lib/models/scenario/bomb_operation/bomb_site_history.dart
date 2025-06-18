/// Modèle pour l'historique d'un site de bombe
class BombSiteHistory {
  final int id;
  final int gameSessionId;
  final int originalBombSiteId;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final String status;
  
  // Timestamps pour la timeline
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? activatedAt;
  final DateTime? armedAt;
  final DateTime? disarmedAt;
  final DateTime? explodedAt;
  
  // Informations sur les joueurs
  final int? armedByUserId;
  final String? armedByUserName;
  final int? disarmedByUserId;
  final String? disarmedByUserName;
  
  // Informations sur le timer
  final int? bombTimer;
  final DateTime? expectedExplosionAt;
  
  // Calculs pour le replay
  final int? timeRemainingSeconds;
  final bool? shouldHaveExploded;

  const BombSiteHistory({
    required this.id,
    required this.gameSessionId,
    required this.originalBombSiteId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.activatedAt,
    this.armedAt,
    this.disarmedAt,
    this.explodedAt,
    this.armedByUserId,
    this.armedByUserName,
    this.disarmedByUserId,
    this.disarmedByUserName,
    this.bombTimer,
    this.expectedExplosionAt,
    this.timeRemainingSeconds,
    this.shouldHaveExploded,
  });

  factory BombSiteHistory.fromJson(Map<String, dynamic> json) {
    return BombSiteHistory(
      id: json['id'] as int,
      gameSessionId: json['gameSessionId'] as int,
      originalBombSiteId: json['originalBombSiteId'] as int,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      activatedAt: json['activatedAt'] != null ? DateTime.parse(json['activatedAt'] as String) : null,
      armedAt: json['armedAt'] != null ? DateTime.parse(json['armedAt'] as String) : null,
      disarmedAt: json['disarmedAt'] != null ? DateTime.parse(json['disarmedAt'] as String) : null,
      explodedAt: json['explodedAt'] != null ? DateTime.parse(json['explodedAt'] as String) : null,
      armedByUserId: json['armedByUserId'] as int?,
      armedByUserName: json['armedByUserName'] as String?,
      disarmedByUserId: json['disarmedByUserId'] as int?,
      disarmedByUserName: json['disarmedByUserName'] as String?,
      bombTimer: json['bombTimer'] as int?,
      expectedExplosionAt: json['expectedExplosionAt'] != null ? DateTime.parse(json['expectedExplosionAt'] as String) : null,
      timeRemainingSeconds: json['timeRemainingSeconds'] as int?,
      shouldHaveExploded: json['shouldHaveExploded'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameSessionId': gameSessionId,
      'originalBombSiteId': originalBombSiteId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'activatedAt': activatedAt?.toIso8601String(),
      'armedAt': armedAt?.toIso8601String(),
      'disarmedAt': disarmedAt?.toIso8601String(),
      'explodedAt': explodedAt?.toIso8601String(),
      'armedByUserId': armedByUserId,
      'armedByUserName': armedByUserName,
      'disarmedByUserId': disarmedByUserId,
      'disarmedByUserName': disarmedByUserName,
      'bombTimer': bombTimer,
      'expectedExplosionAt': expectedExplosionAt?.toIso8601String(),
      'timeRemainingSeconds': timeRemainingSeconds,
      'shouldHaveExploded': shouldHaveExploded,
    };
  }

  /// Vérifie si le site était actif à un moment donné
  bool wasActiveAt(DateTime timestamp) {
    if (activatedAt == null) return false;
    if (timestamp.isBefore(activatedAt!)) return false;
    
    // Le site reste actif jusqu'à ce qu'il soit armé, désarmé ou explosé
    if (armedAt != null && timestamp.isAfter(armedAt!)) return false;
    if (disarmedAt != null && timestamp.isAfter(disarmedAt!)) return false;
    if (explodedAt != null && timestamp.isAfter(explodedAt!)) return false;
    
    return true;
  }

  /// Vérifie si le site était armé à un moment donné
  bool wasArmedAt(DateTime timestamp) {
    if (armedAt == null) return false;
    if (timestamp.isBefore(armedAt!)) return false;
    
    // Le site reste armé jusqu'à ce qu'il soit désarmé ou explosé
    if (disarmedAt != null && timestamp.isAfter(disarmedAt!)) return false;
    if (explodedAt != null && timestamp.isAfter(explodedAt!)) return false;
    
    return true;
  }

  /// Vérifie si le site était désarmé à un moment donné
  bool wasDisarmedAt(DateTime timestamp) {
    return disarmedAt != null && !timestamp.isBefore(disarmedAt!);
  }

  /// Vérifie si le site avait explosé à un moment donné
  bool wasExplodedAt(DateTime timestamp) {
    return explodedAt != null && !timestamp.isBefore(explodedAt!);
  }

  /// Obtient le statut du site à un moment donné
  String getStatusAt(DateTime timestamp) {
    if (wasExplodedAt(timestamp)) return 'EXPLODED';
    if (wasDisarmedAt(timestamp)) return 'DISARMED';
    if (wasArmedAt(timestamp)) return 'ARMED';
    if (wasActiveAt(timestamp)) return 'ACTIVE';
    return 'INACTIVE';
  }
}

