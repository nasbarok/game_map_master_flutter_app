import 'bomb_site.dart';

/// Modèle représentant un scénario d'Opération Bombe
class BombOperationScenario {
  /// Identifiant unique du scénario
  final int? id;
  
  /// Nom du scénario
  final String name;
  
  /// Description du scénario
  final String? description;
  
  /// Durée d'un round en secondes
  final int roundDuration;
  
  /// Durée du timer de la bombe en secondes
  final int bombTimer;
  
  /// Durée nécessaire pour désamorcer la bombe en secondes
  final int defuseTime;
  
  /// Nombre de rounds à jouer
  final int roundsToPlay;
  
  /// Nombre de sites de bombe à activer aléatoirement par round
  final int activeSitesPerRound;
  
  /// Indique si le scénario est actif
  final bool active;
  
  /// Liste des sites de bombe associés à ce scénario
  final List<BombSite>? bombSites;

  /// Constructeur
  BombOperationScenario({
    this.id,
    required this.name,
    this.description,
    required this.roundDuration,
    required this.bombTimer,
    required this.defuseTime,
    required this.roundsToPlay,
    required this.activeSitesPerRound,
    this.active = true,
    this.bombSites,
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
      roundDuration: json['roundDuration'],
      bombTimer: json['bombTimer'],
      defuseTime: json['defuseTime'],
      roundsToPlay: json['roundsToPlay'],
      activeSitesPerRound: json['activeSitesPerRound'],
      active: json['active'] ?? true,
      bombSites: sites,
    );
  }

  /// Convertit cette instance en objet JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'name': name,
      'description': description,
      'roundDuration': roundDuration,
      'bombTimer': bombTimer,
      'defuseTime': defuseTime,
      'roundsToPlay': roundsToPlay,
      'activeSitesPerRound': activeSitesPerRound,
      'active': active,
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
    int? roundDuration,
    int? bombTimer,
    int? defuseTime,
    int? roundsToPlay,
    int? activeSitesPerRound,
    bool? active,
    List<BombSite>? bombSites,
  }) {
    return BombOperationScenario(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      roundDuration: roundDuration ?? this.roundDuration,
      bombTimer: bombTimer ?? this.bombTimer,
      defuseTime: defuseTime ?? this.defuseTime,
      roundsToPlay: roundsToPlay ?? this.roundsToPlay,
      activeSitesPerRound: activeSitesPerRound ?? this.activeSitesPerRound,
      active: active ?? this.active,
      bombSites: bombSites ?? this.bombSites,
    );
  }
}
