class Team {
  final int? id;
  final String name;
  final String? description;
  final String? color;
  final int? ownerId;
  final List<int>? memberIds;

  Team({
    this.id,
    required this.name,
    this.description,
    this.color,
    this.ownerId,
    this.memberIds,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      color: json['color'],
      ownerId: json['ownerId'],
      memberIds: json['memberIds'] != null 
          ? List<int>.from(json['memberIds'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'ownerId': ownerId,
      'memberIds': memberIds,
    };
  }
}
