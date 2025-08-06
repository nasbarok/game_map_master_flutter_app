/// Modèle pour l'historique d'un site de bombe
class BombSiteHistory {
  final int id;
  final int? gameSessionId;
  final int originalBombSiteId;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final String status;
  
  // Timestamps pour la timeline
  final DateTime? createdAt;
  final DateTime? updatedAt;
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
      id: json['id'] as int? ?? -1,
      gameSessionId: json['gameSessionId'] as int?,
      originalBombSiteId: json['originalBombSiteId'] as int? ?? -1,
      name: json['name']?.toString() ?? 'Inconnu',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radius: (json['radius'] as num?)?.toDouble() ?? 5.0,
      status: json['status']?.toString() ?? 'INACTIVE',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      activatedAt: json['activatedAt'] != null ? DateTime.tryParse(json['activatedAt'].toString()) : null,
      armedAt: json['armedAt'] != null ? DateTime.tryParse(json['armedAt'].toString()) : null,
      disarmedAt: json['disarmedAt'] != null ? DateTime.tryParse(json['disarmedAt'].toString()) : null,
      explodedAt: json['explodedAt'] != null ? DateTime.tryParse(json['explodedAt'].toString()) : null,
      armedByUserId: json['armedByUserId'] as int?,
      armedByUserName: json['armedByUserName']?.toString(),
      disarmedByUserId: json['disarmedByUserId'] as int?,
      disarmedByUserName: json['disarmedByUserName']?.toString(),
      bombTimer: json['bombTimer'] as int?,
      expectedExplosionAt: json['expectedExplosionAt'] != null ? DateTime.tryParse(json['expectedExplosionAt'].toString()) : null,
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
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'activatedAt': activatedAt?.toUtc().toIso8601String(),
      'armedAt': armedAt?.toUtc().toIso8601String(),
      'disarmedAt': disarmedAt?.toUtc().toIso8601String(),
      'explodedAt': explodedAt?.toUtc().toIso8601String(),
      'armedByUserId': armedByUserId,
      'armedByUserName': armedByUserName,
      'disarmedByUserId': disarmedByUserId,
      'disarmedByUserName': disarmedByUserName,
      'bombTimer': bombTimer,
      'expectedExplosionAt': expectedExplosionAt?.toUtc().toIso8601String(),
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

  BombSiteHistory copyWith({
    int? id,
    int? gameSessionId,
    int? originalBombSiteId,
    String? name,
    double? latitude,
    double? longitude,
    double? radius,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? activatedAt,
    DateTime? armedAt,
    DateTime? disarmedAt,
    DateTime? explodedAt,
    int? armedByUserId,
    String? armedByUserName,
    int? disarmedByUserId,
    String? disarmedByUserName,
    int? bombTimer,
    DateTime? expectedExplosionAt,
    int? timeRemainingSeconds,
    bool? shouldHaveExploded,
  }) {
    return BombSiteHistory(
      id: id ?? this.id,
      gameSessionId: gameSessionId ?? this.gameSessionId,
      originalBombSiteId: originalBombSiteId ?? this.originalBombSiteId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activatedAt: activatedAt ?? this.activatedAt,
      armedAt: armedAt ?? this.armedAt,
      disarmedAt: disarmedAt ?? this.disarmedAt,
      explodedAt: explodedAt ?? this.explodedAt,
      armedByUserId: armedByUserId ?? this.armedByUserId,
      armedByUserName: armedByUserName ?? this.armedByUserName,
      disarmedByUserId: disarmedByUserId ?? this.disarmedByUserId,
      disarmedByUserName: disarmedByUserName ?? this.disarmedByUserName,
      bombTimer: bombTimer ?? this.bombTimer,
      expectedExplosionAt: expectedExplosionAt ?? this.expectedExplosionAt,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
      shouldHaveExploded: shouldHaveExploded ?? this.shouldHaveExploded,
    );
  }

}

