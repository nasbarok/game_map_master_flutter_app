class TreasureHuntNotification {
  final String type;
  final String message;
  final dynamic data;

  TreasureHuntNotification({
    required this.type,
    required this.message,
    this.data,
  });

  factory TreasureHuntNotification.fromJson(Map<String, dynamic> json) {
    return TreasureHuntNotification(
      type: json['type'],
      message: json['message'],
      data: json['data'],
    );
  }

  bool get isTreasureFound => type == 'TREASURE_FOUND';
  bool get isScoreboardUpdate => type == 'SCOREBOARD_UPDATE';
  bool get isGameStart => type == 'GAME_START';
  bool get isGameEnd => type == 'GAME_END';
}

class TreasureFoundData {
  final String username;
  final String? teamName;
  final int points;
  final int totalScore;
  final bool isNewLeader;
  final int treasureId;
  final String treasureName;
  final String symbol;
  final int? gameSessionId;
  final int? scenarioId;

  TreasureFoundData({
    required this.username,
    this.teamName,
    required this.points,
    required this.totalScore,
    required this.isNewLeader,
    required this.treasureId,
    required this.treasureName,
    required this.symbol,
    this.gameSessionId,
    required this.scenarioId,
  });

  factory TreasureFoundData.fromJson(Map<String, dynamic> json) {
    return TreasureFoundData(
      username: json['username'],
      teamName: json['teamName'],
      points: json['points'],
      totalScore: json['totalScore'],
      isNewLeader: json['isNewLeader'],
      treasureId: json['treasureId'],
      treasureName: json['treasureName'],
      symbol: json['symbol'],
      gameSessionId: json['gameSessionId'],
      scenarioId: json['scenarioId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'teamName': teamName,
      'points': points,
      'totalScore': totalScore,
      'isNewLeader': isNewLeader,
      'treasureId': treasureId,
      'treasureName': treasureName,
      'symbol': symbol,
      'gameSessionId': gameSessionId,
      'scenarioId': scenarioId,
    };
  }
}
