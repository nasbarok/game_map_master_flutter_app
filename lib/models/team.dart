class Team {
  int id;
  String name;
  List<dynamic> players;
  String? description;
  String? color;

  Team({
    required this.id,
    required this.name,
    this.players = const [],
    this.description = '',
    this.color,
  });
  
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      players: json['players'] ?? [],
      description: json['description'] ?? '',
      color: json['color'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'players': players,
      'description': description,
      'color': color,
    };
  }
}
