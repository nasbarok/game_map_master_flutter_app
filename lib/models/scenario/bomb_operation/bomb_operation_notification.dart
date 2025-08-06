/// Modèle représentant une notification WebSocket pour le scénario Opération Bombe
class BombOperationNotification {
  /// Type de notification (ROUND_START, BOMB_PLANTED, DEFUSE_START, etc.)
  final String? type;
  
  /// Message textuel (utilisé principalement pour les erreurs)
  final String? message;
  
  /// Identifiants
  final int? sessionId;
  final int? userId;
  final int? killerUserId;
  final int? siteId;
  
  /// Informations de round
  final int? roundNumber;
  final int? attackTeamScore;
  final int? defenseTeamScore;
  
  /// Informations de bombe
  final String? siteName;
  final int? bombTimer;
  final int? defuseTime;
  final int? remainingTime;
  
  /// Informations d'équipe
  final String? winnerTeam;
  final String? reason;
  
  /// Informations de position
  final double? latitude;
  final double? longitude;
  final bool? isInActiveSite;
  
  /// Informations d'état
  final bool? isAlive;
  final String? gameState;
  
  /// Horodatage
  final DateTime? timestamp;
  
  /// Liste d'identifiants de sites actifs
  final List<int>? activeBombSiteIds;
  
  /// Données génériques (pour les notifications personnalisées)
  final dynamic data;

  /// Constructeur
  BombOperationNotification({
    this.type,
    this.message,
    this.sessionId,
    this.userId,
    this.killerUserId,
    this.siteId,
    this.roundNumber,
    this.attackTeamScore,
    this.defenseTeamScore,
    this.siteName,
    this.bombTimer,
    this.defuseTime,
    this.remainingTime,
    this.winnerTeam,
    this.reason,
    this.latitude,
    this.longitude,
    this.isInActiveSite,
    this.isAlive,
    this.gameState,
    this.timestamp,
    this.activeBombSiteIds,
    this.data,
  });

  /// Crée une instance de BombOperationNotification à partir d'un objet JSON
  factory BombOperationNotification.fromJson(Map<String, dynamic> json) {
    List<int>? activeSites;
    if (json['activeBombSiteIds'] != null) {
      activeSites = List<int>.from(json['activeBombSiteIds']);
    }
    
    return BombOperationNotification(
      type: json['type'],
      message: json['message'],
      sessionId: json['sessionId'],
      userId: json['userId'],
      killerUserId: json['killerUserId'],
      siteId: json['siteId'],
      roundNumber: json['roundNumber'],
      attackTeamScore: json['attackTeamScore'],
      defenseTeamScore: json['defenseTeamScore'],
      siteName: json['siteName'],
      bombTimer: json['bombTimer'],
      defuseTime: json['defuseTime'],
      remainingTime: json['remainingTime'],
      winnerTeam: json['winnerTeam'],
      reason: json['reason'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      isInActiveSite: json['isInActiveSite'],
      isAlive: json['isAlive'],
      gameState: json['gameState'],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      activeBombSiteIds: activeSites,
      data: json['data'],
    );
  }

  /// Convertit cette instance en objet JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (type != null) data['type'] = type;
    if (message != null) data['message'] = message;
    if (sessionId != null) data['sessionId'] = sessionId;
    if (userId != null) data['userId'] = userId;
    if (killerUserId != null) data['killerUserId'] = killerUserId;
    if (siteId != null) data['siteId'] = siteId;
    if (roundNumber != null) data['roundNumber'] = roundNumber;
    if (attackTeamScore != null) data['attackTeamScore'] = attackTeamScore;
    if (defenseTeamScore != null) data['defenseTeamScore'] = defenseTeamScore;
    if (siteName != null) data['siteName'] = siteName;
    if (bombTimer != null) data['bombTimer'] = bombTimer;
    if (defuseTime != null) data['defuseTime'] = defuseTime;
    if (remainingTime != null) data['remainingTime'] = remainingTime;
    if (winnerTeam != null) data['winnerTeam'] = winnerTeam;
    if (reason != null) data['reason'] = reason;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (isInActiveSite != null) data['isInActiveSite'] = isInActiveSite;
    if (isAlive != null) data['isAlive'] = isAlive;
    if (gameState != null) data['gameState'] = gameState;
    if (timestamp != null) data['timestamp'] = timestamp!.toUtc().toIso8601String();
    if (activeBombSiteIds != null) data['activeBombSiteIds'] = activeBombSiteIds;
    if (this.data != null) data['data'] = this.data;
    
    return data;
  }
  
  /// Crée une copie de cette instance avec les valeurs spécifiées remplacées
  BombOperationNotification copyWith({
    String? type,
    String? message,
    int? sessionId,
    int? userId,
    int? killerUserId,
    int? siteId,
    int? roundNumber,
    int? attackTeamScore,
    int? defenseTeamScore,
    String? siteName,
    int? bombTimer,
    int? defuseTime,
    int? remainingTime,
    String? winnerTeam,
    String? reason,
    double? latitude,
    double? longitude,
    bool? isInActiveSite,
    bool? isAlive,
    String? gameState,
    DateTime? timestamp,
    List<int>? activeBombSiteIds,
    dynamic data,
  }) {
    return BombOperationNotification(
      type: type ?? this.type,
      message: message ?? this.message,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      killerUserId: killerUserId ?? this.killerUserId,
      siteId: siteId ?? this.siteId,
      roundNumber: roundNumber ?? this.roundNumber,
      attackTeamScore: attackTeamScore ?? this.attackTeamScore,
      defenseTeamScore: defenseTeamScore ?? this.defenseTeamScore,
      siteName: siteName ?? this.siteName,
      bombTimer: bombTimer ?? this.bombTimer,
      defuseTime: defuseTime ?? this.defuseTime,
      remainingTime: remainingTime ?? this.remainingTime,
      winnerTeam: winnerTeam ?? this.winnerTeam,
      reason: reason ?? this.reason,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isInActiveSite: isInActiveSite ?? this.isInActiveSite,
      isAlive: isAlive ?? this.isAlive,
      gameState: gameState ?? this.gameState,
      timestamp: timestamp ?? this.timestamp,
      activeBombSiteIds: activeBombSiteIds ?? this.activeBombSiteIds,
      data: data ?? this.data,
    );
  }
}
