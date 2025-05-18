/// Énumération représentant les équipes dans le scénario Opération Bombe
enum BombOperationTeam {
  /// Équipe d'attaque (Terroristes)
  attack,
  
  /// Équipe de défense (Anti-terroristes)
  defense
}

/// Extensions pour ajouter des fonctionnalités à l'énumération BombOperationTeam
extension BombOperationTeamExtension on BombOperationTeam {
  /// Obtient le nom d'affichage de l'équipe
  String get displayName {
    switch (this) {
      case BombOperationTeam.attack:
        return 'Terroriste';
      case BombOperationTeam.defense:
        return 'Anti-terroriste';
    }
  }
  
  /// Convertit une chaîne en BombOperationTeam
  static BombOperationTeam fromString(String value) {
    if (value.toLowerCase() == 'attack') {
      return BombOperationTeam.attack;
    } else if (value.toLowerCase() == 'defense') {
      return BombOperationTeam.defense;
    } else {
      throw ArgumentError('Valeur d\'équipe invalide: $value');
    }
  }
}
