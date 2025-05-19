import 'bomb_site.dart';

/// Modèle représentant un scénario d'Opération Bombe
class BombOperationScenario {
  /// Identifiant unique du scénario
  final int? id;
  
  /// Nom du scénario
  final String name;
  
  /// Description du scénario
  final String? description;

  /// Durée du timer de la bombe en secondes
  final int bombTimer;
  
  /// Durée nécessaire pour désamorcer la bombe en secondes
  final int defuseTime;

  /// Nombre de sites de bombe à activer aléatoirement par round
  final int activeSitesPerRound;
  
  /// Indique si le scénario est actif
  final bool active;
  
  /// Liste des sites de bombe associés à ce scénario
  final List<BombSite>? bombSites;

  /// Indique si les zones de la carte doivent être affichées
  final bool showZones;

  /// Indique si les points d'intérêt de la carte doivent être affichés
  final bool showPointsOfInterest;

  /// Constructeur
  BombOperationScenario({
    this.id,
    required this.name,
    this.description,
    required this.bombTimer,
    required this.defuseTime,
    required this.activeSitesPerRound,
    this.active = true,
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
      name: json['name'],
      description: json['description'],
      bombTimer: json['bombTimer'],
      defuseTime: json['defuseTime'],
      activeSitesPerRound: json['activeSitesPerRound'],
      active: json['active'] ?? true,
      bombSites: sites,
      showZones: json['showZones'] ?? true,
      showPointsOfInterest: json['showPointsOfInterest'] ?? true,
    );
  }

  /// Convertit cette instance en objet JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'name': name,
      'description': description,
      'bombTimer': bombTimer,
      'defuseTime': defuseTime,
      'activeSitesPerRound': activeSitesPerRound,
      'active': active,
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
      name: name ?? this.name,
      description: description ?? this.description,
      bombTimer: bombTimer ?? this.bombTimer,
      defuseTime: defuseTime ?? this.defuseTime,
      activeSitesPerRound: activeSitesPerRound ?? this.activeSitesPerRound,
      active: active ?? this.active,
      bombSites: bombSites ?? this.bombSites,
      showZones: showZones ?? this.showZones,
      showPointsOfInterest: showPointsOfInterest ?? this.showPointsOfInterest,
    );
  }
}
