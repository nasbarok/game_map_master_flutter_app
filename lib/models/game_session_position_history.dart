import 'package:game_map_master_flutter_app/models/player_position.dart';

/// Modèle représentant l'historique des positions des joueurs pour une session de jeu
class GameSessionPositionHistory {
  /// Identifiant de la session de jeu
  final int gameSessionId;
  
  /// Positions des joueurs, organisées par userId
  /// Map<userId, List<PlayerPosition>>
  final Map<int, List<PlayerPosition>> playerPositions;

  /// Constructeur
  GameSessionPositionHistory({
    required this.gameSessionId,
    required this.playerPositions,
  });

  /// Crée une instance de GameSessionPositionHistory à partir d'un objet JSON
  factory GameSessionPositionHistory.fromJson(Map<String, dynamic> json) {
    final Map<int, List<PlayerPosition>> positions = {};
    
    (json['playerPositions'] as Map<String, dynamic>).forEach((userId, positionsList) {
      positions[int.parse(userId)] = (positionsList as List)
          .map((pos) => PlayerPosition.fromJson(pos))
          .toList();
    });
    
    return GameSessionPositionHistory(
      gameSessionId: json['gameSessionId'],
      playerPositions: positions,
    );
  }

  /// Convertit cette instance en objet JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> positionsJson = {};
    
    playerPositions.forEach((userId, positions) {
      positionsJson[userId.toString()] = positions.map((pos) => pos.toJson()).toList();
    });
    
    return {
      'gameSessionId': gameSessionId,
      'playerPositions': positionsJson,
    };
  }
}
