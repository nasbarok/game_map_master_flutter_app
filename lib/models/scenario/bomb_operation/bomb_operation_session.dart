import 'package:flutter/material.dart';
import 'bomb_operation_scenario.dart';
import 'bomb_operation_state.dart';

/// Modèle représentant une session de jeu Opération Bombe en cours
class BombOperationSession {
  /// Identifiant unique de la session
  final int? id;
  
  /// Scénario associé à cette session
  final BombOperationScenario? bombOperationScenario;
  
  /// Identifiant de la session de jeu principale
  final int gameSessionId;
  
  /// Numéro du round actuel
  final int currentRound;
  
  /// Score de l'équipe d'attaque (Terroristes)
  final int attackTeamScore;
  
  /// Score de l'équipe de défense (Anti-terroristes)
  final int defenseTeamScore;
  
  /// État actuel du jeu
  final BombOperationState gameState;
  
  /// Horodatage du début du round actuel
  final DateTime? roundStartTime;
  
  /// Horodatage de la pose de la bombe
  final DateTime? bombPlantedTime;
  
  /// Horodatage du début du désamorçage
  final DateTime? defuseStartTime;
  
  /// Liste des identifiants des sites de bombe actifs pour ce round
  final List<int> activeBombSiteIds;
  
  /// Date de création de la session
  final DateTime createdAt;
  
  /// Date de dernière mise à jour de la session
  final DateTime lastUpdated;

  /// Constructeur
  BombOperationSession({
    this.id,
    this.bombOperationScenario,
    required this.gameSessionId,
    this.currentRound = 1,
    this.attackTeamScore = 0,
    this.defenseTeamScore = 0,
    this.gameState = BombOperationState.waiting,
    this.roundStartTime,
    this.bombPlantedTime,
    this.defuseStartTime,
    this.activeBombSiteIds = const [],
    required this.createdAt,
    required this.lastUpdated,
  });

  /// Crée une instance de BombOperationSession à partir d'un objet JSON
  factory BombOperationSession.fromJson(Map<String, dynamic> json) {
    return BombOperationSession(
      id: json['id'],
      bombOperationScenario: json['bombOperationScenario'] != null
          ? BombOperationScenario.fromJson(json['bombOperationScenario'])
          : null,
      gameSessionId: json['gameSessionId'],
      currentRound: json['currentRound'] ?? 1,
      attackTeamScore: json['attackTeamScore'] ?? 0,
      defenseTeamScore: json['defenseTeamScore'] ?? 0,
      gameState: json['gameState'] != null
          ? BombOperationStateExtension.fromString(json['gameState'])
          : BombOperationState.waiting,
      roundStartTime: json['roundStartTime'] != null
          ? DateTime.parse(json['roundStartTime'])
          : null,
      bombPlantedTime: json['bombPlantedTime'] != null
          ? DateTime.parse(json['bombPlantedTime'])
          : null,
      defuseStartTime: json['defuseStartTime'] != null
          ? DateTime.parse(json['defuseStartTime'])
          : null,
      activeBombSiteIds: json['activeBombSiteIds'] != null
          ? List<int>.from(json['activeBombSiteIds'])
          : [],
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
      'gameSessionId': gameSessionId,
      'currentRound': currentRound,
      'attackTeamScore': attackTeamScore,
      'defenseTeamScore': defenseTeamScore,
      'gameState': gameState.toString().split('.').last,
      'activeBombSiteIds': activeBombSiteIds,
    };
    
    if (bombOperationScenario != null) {
      data['bombOperationScenario'] = bombOperationScenario!.toJson();
    }
    
    if (roundStartTime != null) {
      data['roundStartTime'] = roundStartTime!.toIso8601String();
    }
    
    if (bombPlantedTime != null) {
      data['bombPlantedTime'] = bombPlantedTime!.toIso8601String();
    }
    
    if (defuseStartTime != null) {
      data['defuseStartTime'] = defuseStartTime!.toIso8601String();
    }
    
    data['createdAt'] = createdAt.toIso8601String();
    data['lastUpdated'] = lastUpdated.toIso8601String();
    
    return data;
  }
  
  /// Crée une copie de cette instance avec les valeurs spécifiées remplacées
  BombOperationSession copyWith({
    int? id,
    BombOperationScenario? bombOperationScenario,
    int? gameSessionId,
    int? currentRound,
    int? attackTeamScore,
    int? defenseTeamScore,
    BombOperationState? gameState,
    DateTime? roundStartTime,
    DateTime? bombPlantedTime,
    DateTime? defuseStartTime,
    List<int>? activeBombSiteIds,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return BombOperationSession(
      id: id ?? this.id,
      bombOperationScenario: bombOperationScenario ?? this.bombOperationScenario,
      gameSessionId: gameSessionId ?? this.gameSessionId,
      currentRound: currentRound ?? this.currentRound,
      attackTeamScore: attackTeamScore ?? this.attackTeamScore,
      defenseTeamScore: defenseTeamScore ?? this.defenseTeamScore,
      gameState: gameState ?? this.gameState,
      roundStartTime: roundStartTime ?? this.roundStartTime,
      bombPlantedTime: bombPlantedTime ?? this.bombPlantedTime,
      defuseStartTime: defuseStartTime ?? this.defuseStartTime,
      activeBombSiteIds: activeBombSiteIds ?? this.activeBombSiteIds,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  /// Calcule le temps restant pour la bombe en secondes
  int? getRemainingBombTime(BombOperationScenario scenario) {
    if (gameState != BombOperationState.bombPlanted || bombPlantedTime == null) {
      return null;
    }
    
    final elapsedSeconds = DateTime.now().difference(bombPlantedTime!).inSeconds;
    final remainingSeconds = scenario.bombTimer - elapsedSeconds;
    
    return remainingSeconds > 0 ? remainingSeconds : 0;
  }
  
  /// Calcule le temps restant pour le désamorçage en secondes
  int? getRemainingDefuseTime(BombOperationScenario scenario) {
    if (gameState != BombOperationState.defusing || defuseStartTime == null) {
      return null;
    }
    
    final elapsedSeconds = DateTime.now().difference(defuseStartTime!).inSeconds;
    final remainingSeconds = scenario.defuseTime - elapsedSeconds;
    
    return remainingSeconds > 0 ? remainingSeconds : 0;
  }
}
