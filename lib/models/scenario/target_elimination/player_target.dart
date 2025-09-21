class PlayerTarget {
  final int id;
  final int scenarioId;
  final int playerId;
  final int? teamId;
  final int targetNumber;
  final String qrCode;
  final DateTime assignedAt;
  final DateTime? lastEliminatedAt;
  final bool active;
  final String? playerName;
  final String? teamName;

  PlayerTarget({
    required this.id,
    required this.scenarioId,
    required this.playerId,
    this.teamId,
    required this.targetNumber,
    required this.qrCode,
    required this.assignedAt,
    this.lastEliminatedAt,
    required this.active,
    this.playerName,
    this.teamName,
  });

  factory PlayerTarget.fromJson(Map<String, dynamic> json) {
    return PlayerTarget(
      id: json['id'] as int,
      scenarioId: json['scenarioId'] as int,
      playerId: json['playerId'] as int,
      teamId: json['teamId'] as int?,
      targetNumber: json['targetNumber'] as int,
      qrCode: json['qrCode'] as String,
      assignedAt: DateTime.parse(json['assignedAt'] as String),
      lastEliminatedAt: json['lastEliminatedAt'] != null
          ? DateTime.parse(json['lastEliminatedAt'] as String)
          : null,
      active: json['active'] as bool,
      playerName: json['playerName'] as String?,
      teamName: json['teamName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scenarioId': scenarioId,
      'playerId': playerId,
      'teamId': teamId,
      'targetNumber': targetNumber,
      'qrCode': qrCode,
      'assignedAt': assignedAt.toIso8601String(),
      'lastEliminatedAt': lastEliminatedAt?.toIso8601String(),
      'active': active,
      'playerName': playerName,
      'teamName': teamName,
    };
  }

  PlayerTarget copyWith({
    int? id,
    int? scenarioId,
    int? playerId,
    int? teamId,
    int? targetNumber,
    String? qrCode,
    DateTime? assignedAt,
    DateTime? lastEliminatedAt,
    bool? active,
    String? playerName,
    String? teamName,
  }) {
    return PlayerTarget(
      id: id ?? this.id,
      scenarioId: scenarioId ?? this.scenarioId,
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      targetNumber: targetNumber ?? this.targetNumber,
      qrCode: qrCode ?? this.qrCode,
      assignedAt: assignedAt ?? this.assignedAt,
      lastEliminatedAt: lastEliminatedAt ?? this.lastEliminatedAt,
      active: active ?? this.active,
      playerName: playerName ?? this.playerName,
      teamName: teamName ?? this.teamName,
    );
  }

  /// Vérifie si le joueur est en période d'immunité
  bool isInCooldown(int cooldownMinutes) {
    if (lastEliminatedAt == null) return false;
    
    final immunityEnd = lastEliminatedAt!.add(Duration(minutes: cooldownMinutes));
    return DateTime.now().isBefore(immunityEnd);
  }

  /// Retourne le temps restant d'immunité en minutes
  int getCooldownRemainingMinutes(int cooldownMinutes) {
    if (!isInCooldown(cooldownMinutes)) return 0;
    
    final immunityEnd = lastEliminatedAt!.add(Duration(minutes: cooldownMinutes));
    final remaining = immunityEnd.difference(DateTime.now());
    return remaining.inMinutes + 1; // +1 pour arrondir vers le haut
  }

  /// Retourne le temps restant d'immunité formaté (MM:SS)
  String getCooldownRemainingFormatted(int cooldownMinutes) {
    if (!isInCooldown(cooldownMinutes)) return '00:00';
    
    final immunityEnd = lastEliminatedAt!.add(Duration(minutes: cooldownMinutes));
    final remaining = immunityEnd.difference(DateTime.now());
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerTarget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PlayerTarget{id: $id, playerId: $playerId, targetNumber: $targetNumber, active: $active}';
  }
}

