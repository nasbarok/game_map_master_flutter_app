import 'bomb_site_history.dart';

/// Modèle pour l'historique complet d'une session Bomb Operation
class BombOperationHistory {
  final int gameSessionId;
  final DateTime sessionStartTime;
  final DateTime? sessionEndTime;
  final String sessionStatus;

  // Informations sur le scénario
  final String scenarioName;
  final int bombTimer;
  final int defuseTime;
  final int armingTime;
  final int activeSites;

  // Informations sur les équipes
  final TeamHistory? attackTeam;
  final TeamHistory? defenseTeam;

  // Historique complet des sites
  final List<BombSiteHistory> bombSitesHistory;

  // Timeline des événements
  final List<BombEvent> timeline;

  // Statistiques finales
  final BombOperationStats finalStats;

  const BombOperationHistory({
    required this.gameSessionId,
    required this.sessionStartTime,
    this.sessionEndTime,
    required this.sessionStatus,
    required this.scenarioName,
    required this.bombTimer,
    required this.defuseTime,
    required this.armingTime,
    required this.activeSites,
    this.attackTeam,
    this.defenseTeam,
    required this.bombSitesHistory,
    required this.timeline,
    required this.finalStats,
  });

  factory BombOperationHistory.fromJson(Map<String, dynamic> json) {
    try {
      return BombOperationHistory(
        gameSessionId: json['gameSessionId'] as int? ?? -1,
        sessionStartTime: json['sessionStartTime'] != null
            ? DateTime.tryParse(json['sessionStartTime']) ?? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.fromMillisecondsSinceEpoch(0),
        sessionStatus: json['sessionStatus'] as String? ?? 'UNKNOWN',
        scenarioName: json['scenarioName'] as String? ?? 'Inconnu',
        bombTimer: json['bombTimer'] as int? ?? 0,
        defuseTime: json['defuseTime'] as int? ?? 0,
        armingTime: json['armingTime'] as int? ?? 0,
        activeSites: json['activeSites'] as int? ?? 0,
        attackTeam: json['attackTeam'] != null && json['attackTeam'] is Map<String, dynamic>
            ? TeamHistory.fromJson(json['attackTeam'])
            : null,
        defenseTeam: json['defenseTeam'] != null && json['defenseTeam'] is Map<String, dynamic>
            ? TeamHistory.fromJson(json['defenseTeam'])
            : null,
        bombSitesHistory: (json['bombSitesHistory'] as List<dynamic>?)
            ?.map((e) => BombSiteHistory.fromJson(e as Map<String, dynamic>))
            .toList() ??
            [],
        timeline: (json['timeline'] as List<dynamic>?)
            ?.map((e) => BombEvent.fromJson(e as Map<String, dynamic>))
            .toList() ??
            [],
        finalStats: json['finalStats'] != null && json['finalStats'] is Map<String, dynamic>
            ? BombOperationStats.fromJson(json['finalStats'])
            : const BombOperationStats(
          totalSites: 0,
          activatedSites: 0,
          armedSites: 0,
          disarmedSites: 0,
          explodedSites: 0,
          winningTeam: null,
          winCondition: null,
          sessionDurationMinutes: 0,
        ),
      );
    } catch (e) {
      throw FormatException('Erreur de parsing BombOperationHistory: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'gameSessionId': gameSessionId,
      'sessionStartTime': sessionStartTime.toIso8601String(),
      'sessionEndTime': sessionEndTime?.toIso8601String(),
      'sessionStatus': sessionStatus,
      'scenarioName': scenarioName,
      'bombTimer': bombTimer,
      'defuseTime': defuseTime,
      'armingTime': armingTime,
      'activeSites': activeSites,
      'attackTeam': attackTeam?.toJson(),
      'defenseTeam': defenseTeam?.toJson(),
      'bombSitesHistory': bombSitesHistory.map((e) => e.toJson()).toList(),
      'timeline': timeline.map((e) => e.toJson()).toList(),
      'finalStats': finalStats.toJson(),
    };
  }


  /// Obtient l'état des sites à un moment donné
  List<BombSiteHistory> getSitesStateAt(DateTime timestamp) {
    return bombSitesHistory.map((site) {
      // Créer une copie avec le statut à ce moment
      return BombSiteHistory(
        id: site.id,
        gameSessionId: site.gameSessionId,
        originalBombSiteId: site.originalBombSiteId,
        name: site.name,
        latitude: site.latitude,
        longitude: site.longitude,
        radius: site.radius,
        status: site.getStatusAt(timestamp),
        createdAt: site.createdAt,
        updatedAt: site.updatedAt,
        activatedAt: site.activatedAt,
        armedAt: site.armedAt,
        disarmedAt: site.disarmedAt,
        explodedAt: site.explodedAt,
        armedByUserId: site.armedByUserId,
        armedByUserName: site.armedByUserName,
        disarmedByUserId: site.disarmedByUserId,
        disarmedByUserName: site.disarmedByUserName,
        bombTimer: site.bombTimer,
        expectedExplosionAt: site.expectedExplosionAt,
        timeRemainingSeconds: site.timeRemainingSeconds,
        shouldHaveExploded: site.shouldHaveExploded,
      );
    }).toList();
  }

  /// Obtient les événements jusqu'à un moment donné
  List<BombEvent> getEventsUntil(DateTime timestamp) {
    return timeline.where((event) => !event.timestamp.isAfter(timestamp)).toList();
  }

  /// Calcule les statistiques à un moment donné
  BombOperationStats getStatsAt(DateTime timestamp) {
    final sitesAtTime = getSitesStateAt(timestamp);
    final eventsUntil = getEventsUntil(timestamp);

    final activatedSites = sitesAtTime.where((s) => s.getStatusAt(timestamp) != 'INACTIVE').length;
    final armedSites = sitesAtTime.where((s) => s.getStatusAt(timestamp) == 'ARMED').length;
    final disarmedSites = sitesAtTime.where((s) => s.getStatusAt(timestamp) == 'DISARMED').length;
    final explodedSites = sitesAtTime.where((s) => s.getStatusAt(timestamp) == 'EXPLODED').length;

    // Déterminer le gagnant à ce moment
    String? winningTeam;
    String? winCondition;

    if (explodedSites > disarmedSites) {
      winningTeam = 'ATTACK';
      winCondition = 'MORE_EXPLOSIONS';
    } else if (disarmedSites > explodedSites) {
      winningTeam = 'DEFENSE';
      winCondition = 'MORE_DISARMS';
    }

    final sessionDuration = timestamp.difference(sessionStartTime).inMinutes;

    return BombOperationStats(
      totalSites: bombSitesHistory.length,
      activatedSites: activatedSites,
      armedSites: armedSites,
      disarmedSites: disarmedSites,
      explodedSites: explodedSites,
      winningTeam: winningTeam,
      winCondition: winCondition,
      sessionDurationMinutes: sessionDuration,
    );
  }
}

/// Modèle pour l'historique d'une équipe
class TeamHistory {
  final String teamName;
  final String role; // "ATTACK" ou "DEFENSE"
  final List<String> playerNames;
  final int finalScore;
  final bool hasWon;

  const TeamHistory({
    required this.teamName,
    required this.role,
    required this.playerNames,
    required this.finalScore,
    required this.hasWon,
  });

  factory TeamHistory.fromJson(Map<String, dynamic> json) {
    return TeamHistory(
      teamName: json['teamName'] as String? ?? 'Équipe inconnue',
      role: json['role'] as String? ?? 'UNDEFINED',
      playerNames: (json['playerNames'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      finalScore: json['finalScore'] is int ? json['finalScore'] as int : 0,
      hasWon: json['hasWon'] is bool ? json['hasWon'] as bool : false,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'teamName': teamName,
      'role': role,
      'playerNames': List<String>.from(playerNames),
      'finalScore': finalScore,
      'hasWon': hasWon,
    };
  }
}

/// Modèle pour un événement dans la timeline
class BombEvent {
  final DateTime timestamp;
  final String eventType; // "ACTIVATED", "ARMED", "DISARMED", "EXPLODED"
  final String siteName;
  final String? playerName;
  final String? teamRole;
  final String description;
  final int? timeRemainingSeconds; // Pour les événements d'armement

  const BombEvent({
    required this.timestamp,
    required this.eventType,
    required this.siteName,
    this.playerName,
    this.teamRole,
    required this.description,
    this.timeRemainingSeconds,
  });

  factory BombEvent.fromJson(Map<String, dynamic> json) {
    return BombEvent(
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      eventType: json['eventType']?.toString() ?? 'UNKNOWN',
      siteName: json['siteName']?.toString() ?? 'Inconnu',
      playerName: json['playerName'] != null ? json['playerName'].toString() : null,
      teamRole: json['teamRole'] != null ? json['teamRole'].toString() : null,
      description: json['description']?.toString() ?? '',
      timeRemainingSeconds: json['timeRemainingSeconds'] is int
          ? json['timeRemainingSeconds'] as int
          : int.tryParse(json['timeRemainingSeconds']?.toString() ?? ''),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType,
      'siteName': siteName,
      if (playerName != null) 'playerName': playerName,
      if (teamRole != null) 'teamRole': teamRole,
      'description': description,
      if (timeRemainingSeconds != null) 'timeRemainingSeconds': timeRemainingSeconds,
    };
  }

}

/// Modèle pour les statistiques finales
class BombOperationStats {
  final int totalSites;
  final int activatedSites;
  final int armedSites;
  final int disarmedSites;
  final int explodedSites;
  final String? winningTeam;
  final String? winCondition; // "MORE_EXPLOSIONS", "MORE_DISARMS", "TIME_EXPIRED"
  final int sessionDurationMinutes;

  const BombOperationStats({
    required this.totalSites,
    required this.activatedSites,
    required this.armedSites,
    required this.disarmedSites,
    required this.explodedSites,
    this.winningTeam,
    this.winCondition,
    required this.sessionDurationMinutes,
  });

  factory BombOperationStats.fromJson(Map<String, dynamic> json) {
    return BombOperationStats(
      totalSites: json['totalSites'] is int ? json['totalSites'] : int.tryParse(json['totalSites'].toString()) ?? 0,
      activatedSites: json['activatedSites'] is int ? json['activatedSites'] : int.tryParse(json['activatedSites'].toString()) ?? 0,
      armedSites: json['armedSites'] is int ? json['armedSites'] : int.tryParse(json['armedSites'].toString()) ?? 0,
      disarmedSites: json['disarmedSites'] is int ? json['disarmedSites'] : int.tryParse(json['disarmedSites'].toString()) ?? 0,
      explodedSites: json['explodedSites'] is int ? json['explodedSites'] : int.tryParse(json['explodedSites'].toString()) ?? 0,
      winningTeam: json['winningTeam'] as String?, // null-safe
      winCondition: json['winCondition'] as String?, // null-safe
      sessionDurationMinutes: json['sessionDurationMinutes'] is int
          ? json['sessionDurationMinutes']
          : int.tryParse(json['sessionDurationMinutes'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSites': totalSites,
      'activatedSites': activatedSites,
      'armedSites': armedSites,
      'disarmedSites': disarmedSites,
      'explodedSites': explodedSites,
      'winningTeam': winningTeam,
      'winCondition': winCondition,
      'sessionDurationMinutes': sessionDurationMinutes,
    };
  }
}

