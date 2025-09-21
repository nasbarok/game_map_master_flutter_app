class Elimination {
  final int id;
  final int scenarioId;
  final int killerId;
  final int victimId;
  final int? killerTeamId;
  final int? victimTeamId;
  final int gameSessionId;
  final int points;
  final DateTime eliminatedAt;
  final String qrCodeScanned;
  final String? killerName;
  final String? victimName;
  final String? killerTeamName;
  final String? victimTeamName;

  Elimination({
    required this.id,
    required this.scenarioId,
    required this.killerId,
    required this.victimId,
    this.killerTeamId,
    this.victimTeamId,
    required this.gameSessionId,
    required this.points,
    required this.eliminatedAt,
    required this.qrCodeScanned,
    this.killerName,
    this.victimName,
    this.killerTeamName,
    this.victimTeamName,
  });

  factory Elimination.fromJson(Map<String, dynamic> json) {
    return Elimination(
      id: json['id'] as int,
      scenarioId: json['scenarioId'] as int,
      killerId: json['killerId'] as int,
      victimId: json['victimId'] as int,
      killerTeamId: json['killerTeamId'] as int?,
      victimTeamId: json['victimTeamId'] as int?,
      gameSessionId: json['gameSessionId'] as int,
      points: json['points'] as int,
      eliminatedAt: DateTime.parse(json['eliminatedAt'] as String),
      qrCodeScanned: json['qrCodeScanned'] as String,
      killerName: json['killerName'] as String?,
      victimName: json['victimName'] as String?,
      killerTeamName: json['killerTeamName'] as String?,
      victimTeamName: json['victimTeamName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scenarioId': scenarioId,
      'killerId': killerId,
      'victimId': victimId,
      'killerTeamId': killerTeamId,
      'victimTeamId': victimTeamId,
      'gameSessionId': gameSessionId,
      'points': points,
      'eliminatedAt': eliminatedAt.toIso8601String(),
      'qrCodeScanned': qrCodeScanned,
      'killerName': killerName,
      'victimName': victimName,
      'killerTeamName': killerTeamName,
      'victimTeamName': victimTeamName,
    };
  }

  Elimination copyWith({
    int? id,
    int? scenarioId,
    int? killerId,
    int? victimId,
    int? killerTeamId,
    int? victimTeamId,
    int? gameSessionId,
    int? points,
    DateTime? eliminatedAt,
    String? qrCodeScanned,
    String? killerName,
    String? victimName,
    String? killerTeamName,
    String? victimTeamName,
  }) {
    return Elimination(
      id: id ?? this.id,
      scenarioId: scenarioId ?? this.scenarioId,
      killerId: killerId ?? this.killerId,
      victimId: victimId ?? this.victimId,
      killerTeamId: killerTeamId ?? this.killerTeamId,
      victimTeamId: victimTeamId ?? this.victimTeamId,
      gameSessionId: gameSessionId ?? this.gameSessionId,
      points: points ?? this.points,
      eliminatedAt: eliminatedAt ?? this.eliminatedAt,
      qrCodeScanned: qrCodeScanned ?? this.qrCodeScanned,
      killerName: killerName ?? this.killerName,
      victimName: victimName ?? this.victimName,
      killerTeamName: killerTeamName ?? this.killerTeamName,
      victimTeamName: victimTeamName ?? this.victimTeamName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Elimination && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Elimination{id: $id, killerId: $killerId, victimId: $victimId, points: $points, eliminatedAt: $eliminatedAt}';
  }
}

