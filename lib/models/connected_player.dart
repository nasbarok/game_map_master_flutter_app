import 'package:flutter/material.dart';
import '../../models/game_map.dart';
import '../../models/team.dart';
import '../../models/user.dart';

class ConnectedPlayer {
  final int id;
  final User user;
  final GameMap gameMap;
  final Team? team;
  final DateTime joinedAt;
  final bool active;

  ConnectedPlayer({
    required this.id,
    required this.user,
    required this.gameMap,
    this.team,
    required this.joinedAt,
    required this.active,
  });

  factory ConnectedPlayer.fromJson(Map<String, dynamic> json) {
    return ConnectedPlayer(
      id: json['id'],
      user: User.fromJson(json['user']),
      gameMap: GameMap.fromJson(json['gameMap']),
      team: json['team'] != null ? Team.fromJson(json['team']) : null,
      joinedAt: DateTime.parse(json['joinedAt']),
      active: json['active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'gameMap': gameMap.toJson(),
      'team': team?.toJson(),
      'joinedAt': joinedAt.toIso8601String(),
      'active': active,
    };
  }
}
