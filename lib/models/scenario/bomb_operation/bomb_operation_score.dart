import 'bomb_operation_scenario.dart';

/// Modèle représentant le score d'un joueur dans le scénario Opération Bombe
class BombOperationScore {
  /// Identifiant unique du score
  final int? id;
  
  /// Scénario associé
  final BombOperationScenario? bombOperationScenario;
  
  /// Identifiant du scénario
  final int scenarioId;
  
  /// Identifiant de l'utilisateur
  final int userId;
  
  /// Identifiant de l'équipe
  final int? teamId;
  
  /// Identifiant de la session de jeu
  final int gameSessionId;
  
  /// Nombre de rounds gagnés
  final int roundsWon;
  
  /// Nombre de bombes posées
  final int bombsPlanted;
  
  /// Nombre de bombes désamorcées
  final int bombsDefused;
  
  /// Date de dernière mise à jour
  final DateTime lastUpdated;
  
  /// Date de création
  final DateTime createdAt;

  /// Constructeur
  BombOperationScore({
    this.id,
    this.bombOperationScenario,
    required this.scenarioId,
    required this.userId,
    this.teamId,
    required this.gameSessionId,
    this.roundsWon = 0,
    this.bombsPlanted = 0,
    this.bombsDefused = 0,
    required this.lastUpdated,
    required this.createdAt,
  });

  /// Crée une instance de BombOperationScore à partir d'un objet JSON
  factory BombOperationScore.fromJson(Map<String, dynamic> json) {
    return BombOperationScore(
      id: json['id'],
      bombOperationScenario: json['bombOperationScenario'] != null
          ? BombOperationScenario.fromJson(json['bombOperationScenario'])
          : null,
      scenarioId: json['scenarioId'] ?? json['bombOperationScenarioId'],
      userId: json['userId'],
      teamId: json['teamId'],
      gameSessionId: json['gameSessionId'],
      roundsWon: json['roundsWon'] ?? 0,
      bombsPlanted: json['bombsPlanted'] ?? 0,
      bombsDefused: json['bombsDefused'] ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Convertit cette instance en objet JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'scenarioId': scenarioId,
      'userId': userId,
      'teamId': teamId,
      'gameSessionId': gameSessionId,
      'roundsWon': roundsWon,
      'bombsPlanted': bombsPlanted,
      'bombsDefused': bombsDefused,
      'lastUpdated': lastUpdated.toUtc().toIso8601String(),
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
    
    return data;
  }
  
  /// Crée une copie de cette instance avec les valeurs spécifiées remplacées
  BombOperationScore copyWith({
    int? id,
    BombOperationScenario? bombOperationScenario,
    int? scenarioId,
    int? userId,
    int? teamId,
    int? gameSessionId,
    int? roundsWon,
    int? bombsPlanted,
    int? bombsDefused,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return BombOperationScore(
      id: id ?? this.id,
      bombOperationScenario: bombOperationScenario ?? this.bombOperationScenario,
      scenarioId: scenarioId ?? this.scenarioId,
      userId: userId ?? this.userId,
      teamId: teamId ?? this.teamId,
      gameSessionId: gameSessionId ?? this.gameSessionId,
      roundsWon: roundsWon ?? this.roundsWon,
      bombsPlanted: bombsPlanted ?? this.bombsPlanted,
      bombsDefused: bombsDefused ?? this.bombsDefused,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
