class TreasureHuntScore {
  final int? id;
  final int userId;
  final String username;
  final int? teamId;
  final String? teamName;
  final int score;
  final int treasuresFound;

  TreasureHuntScore({
    this.id,
    required this.userId,
    required this.username,
    this.teamId,
    this.teamName,
    required this.score,
    required this.treasuresFound,
  });

  factory TreasureHuntScore.fromJson(Map<String, dynamic> json) {
    return TreasureHuntScore(
      id: json['id'],
      userId: json['userId'],
      username: json['username'],
      teamId: json['teamId'],
      teamName: json['teamName'],
      score: json['score'],
      treasuresFound: json['treasuresFound'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'teamId': teamId,
      'teamName': teamName,
      'score': score,
      'treasuresFound': treasuresFound,
    };
  }
}
