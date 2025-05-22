import 'bomb_site.dart';

/// Modèle représentant un scénario d'Opération Bombe
class BombOperationScenario {
  /// Identifiant unique du scénario
  final int? id;
  
  /// scénario
  final int? scenarioId;

  /// Durée du timer de la bombe en secondes
  final int bombTimer;
  
  /// Durée nécessaire pour désamorcer la bombe en secondes
  final int defuseTime;

  /// Nombre de sites de bombe à activer aléatoirement par round
  final int? activeSites;

  final String? attackTeamName;
  final String? defenseTeamName;
  
  /// Liste des sites de bombe associés à ce scénario
  final List<BombSite>? bombSites;

  /// Indique si les zones de la carte doivent être affichées
  final bool showZones;

  /// Indique si les points d'intérêt de la carte doivent être affichés
  final bool showPointsOfInterest;

  /// Constructeur
  BombOperationScenario({
    this.id,
    this.scenarioId,
    required this.bombTimer,
    required this.defuseTime,
    this.activeSites,
    this.attackTeamName,
    this.defenseTeamName,
    this.bombSites,
    this.showZones = true,
    this.showPointsOfInterest = true,
  });

  /// Crée une instance de BombOperationScenario à partir d'un objet JSON
  factory BombOperationScenario.fromJson(Map<String, dynamic> json) {
    List<BombSite>? sites;
    if (json['bombSites'] != null) {
      sites = (json['bombSites'] as List)
          .map((site) => BombSite.fromJson(site))
          .toList();
    }

    return BombOperationScenario(
      id: json['id'],
      scenarioId: json['scenarioId'],
      bombTimer: json['bombTimer'],
      defuseTime: json['defuseTime'],
      activeSites: json['activeSites'],
      attackTeamName: json['attackTeamName'],
      defenseTeamName: json['defenseTeamName'],
      bombSites: sites,
      showZones: json['showZones'] ?? true,
      showPointsOfInterest: json['showPointsOfInterest'] ?? true,
    );
  }

  /// Convertit cette instance en objet JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'scenarioId': scenarioId,
      'bombTimer': bombTimer,
      'defuseTime': defuseTime,
      'activeSites': activeSites,
      'attackTeamName': attackTeamName,
      'defenseTeamName': defenseTeamName,
      'showZones': showZones,
      'showPointsOfInterest': showPointsOfInterest,
    };
    
    if (bombSites != null) {
      data['bombSites'] = bombSites!.map((site) => site.toJson()).toList();
    }
    
    return data;
  }
  
  /// Crée une copie de cette instance avec les valeurs spécifiées remplacées
  BombOperationScenario copyWith({
    int? id,
    String? name,
    String? description,
    int? bombTimer,
    int? defuseTime,
    int? activeSitesPerRound,
    bool? active,
    List<BombSite>? bombSites,
    bool? showZones,
    bool? showPointsOfInterest,
  }) {
    return BombOperationScenario(
      id: id ?? this.id,
      scenarioId: scenarioId ?? this.scenarioId,
      bombTimer: bombTimer ?? this.bombTimer,
      defuseTime: defuseTime ?? this.defuseTime,
      activeSites: activeSites ?? this.activeSites,
      attackTeamName: attackTeamName ?? this.attackTeamName,
      defenseTeamName: defenseTeamName ?? this.defenseTeamName,
      bombSites: bombSites ?? this.bombSites,
      showZones: showZones ?? this.showZones,
      showPointsOfInterest: showPointsOfInterest ?? this.showPointsOfInterest,
    );
  }
}
