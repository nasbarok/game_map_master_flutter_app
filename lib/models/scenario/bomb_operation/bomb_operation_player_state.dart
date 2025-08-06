import 'bomb_operation_session.dart';
import 'bomb_operation_team.dart';

/// Modèle représentant l'état d'un joueur pendant une partie d'Opération Bombe
class BombOperationPlayerState {
  /// Identifiant unique de l'état du joueur
  final int? id;
  
  /// Session de jeu associée
  final BombOperationSession? bombOperationSession;
  
  /// Identifiant de la session de jeu
  final int sessionId;
  
  /// Identifiant de l'utilisateur
  final int userId;
  
  /// Nom d'utilisateur pour l'affichage
  final String? username;
  
  /// Équipe du joueur (attaque ou défense)
  final BombOperationTeam team;
  
  /// Indique si le joueur est vivant
  final bool isAlive;
  
  /// Indique si le joueur possède un kit de désamorçage
  final bool hasDefuseKit;
  
  /// Date de création
  final DateTime createdAt;
  
  /// Date de dernière mise à jour
  final DateTime lastUpdated;

  /// Constructeur
  BombOperationPlayerState({
    this.id,
    this.bombOperationSession,
    required this.sessionId,
    required this.userId,
    this.username,
    required this.team,
    this.isAlive = true,
    this.hasDefuseKit = false,
    required this.createdAt,
    required this.lastUpdated,
  });

  /// Crée une instance de BombOperationPlayerState à partir d'un objet JSON
  factory BombOperationPlayerState.fromJson(Map<String, dynamic> json) {
    return BombOperationPlayerState(
      id: json['id'],
      bombOperationSession: json['bombOperationSession'] != null
          ? BombOperationSession.fromJson(json['bombOperationSession'])
          : null,
      sessionId: json['sessionId'] ?? json['bombOperationSessionId'],
      userId: json['userId'],
      username: json['username'],
      team: json['team'] != null
          ? BombOperationTeamExtension.fromString(json['team'])
          : BombOperationTeam.defense,
      isAlive: json['isAlive'] ?? true,
      hasDefuseKit: json['hasDefuseKit'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  /// Convertit cette instance en objet JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'sessionId': sessionId,
      'userId': userId,
      'username': username,
      'team': team.toString().split('.').last,
      'isAlive': isAlive,
      'hasDefuseKit': hasDefuseKit,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'lastUpdated': lastUpdated.toUtc().toIso8601String(),
    };
    
    return data;
  }
  
  /// Crée une copie de cette instance avec les valeurs spécifiées remplacées
  BombOperationPlayerState copyWith({
    int? id,
    BombOperationSession? bombOperationSession,
    int? sessionId,
    int? userId,
    String? username,
    BombOperationTeam? team,
    bool? isAlive,
    bool? hasDefuseKit,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return BombOperationPlayerState(
      id: id ?? this.id,
      bombOperationSession: bombOperationSession ?? this.bombOperationSession,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      team: team ?? this.team,
      isAlive: isAlive ?? this.isAlive,
      hasDefuseKit: hasDefuseKit ?? this.hasDefuseKit,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
