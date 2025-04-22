class GameSessionParticipant {
  final int id;
  final int gameSessionId;
  final int userId;
  final String username;
  final int? teamId;
  final String? teamName;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final String? participantType;
  GameSessionParticipant({
    required this.id,
    required this.gameSessionId,
    required this.userId,
    required this.username,
    this.teamId,
    this.teamName,
    required this.joinedAt,
    this.leftAt,
    this.participantType,
  });

  factory GameSessionParticipant.fromJson(Map<String, dynamic> json) {
    return GameSessionParticipant(
      id: json['id'],
      gameSessionId: json['gameSessionId'],
      userId: json['userId'],
      username: json['username'],
      teamId: json['teamId'],
      teamName: json['teamName'],
      joinedAt: _safeParseDateTime(json['createdAt']),
      leftAt: json['leftAt'] != null ? DateTime.parse(json['leftAt']) : null,
      participantType: json['participantType'] ?? 'PLAYER',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameSessionId': gameSessionId,
      'userId': userId,
      'username': username,
      'teamId': teamId,
      'teamName': teamName,
      'joinedAt': joinedAt.toIso8601String(),
      'leftAt': leftAt?.toIso8601String(),
      'participantType': participantType,
    };
  }

  bool isActive() {
    return leftAt == null;
  }
}
DateTime _safeParseDateTime(String? raw) {
  if (raw == null) return DateTime.now();

  try {
    // Troncature manuelle des microsecondes à 6 chiffres
    if (raw.contains('.') && raw.contains('T')) {
      final parts = raw.split('.');
      final timePart = parts[1].split('T').last;
      final micro = parts[1].substring(0, 6);
      raw = '${parts[0]}.${micro}';
    }

    return DateTime.parse(raw);
  } catch (e) {
    print('⚠️ Erreur de parsing DateTime: $e pour "$raw"');
    return DateTime.now();
  }
}
