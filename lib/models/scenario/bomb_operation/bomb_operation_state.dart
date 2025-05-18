/// Énumération représentant les différents états possibles d'une session de jeu Opération Bombe
enum BombOperationState {
  /// En attente du début de la partie
  waiting,
  
  /// Round actif, les joueurs peuvent se déplacer et interagir
  roundActive,
  
  /// Une bombe a été posée et le timer est en cours
  bombPlanted,
  
  /// Un joueur est en train de désamorcer la bombe
  defusing,
  
  /// La bombe a été désamorcée avec succès
  bombDefused,
  
  /// La bombe a explosé
  bombExploded,
  
  /// Le round est terminé
  roundEnd,
  
  /// La partie est terminée
  gameEnd
}

/// Extensions pour ajouter des fonctionnalités à l'énumération BombOperationState
extension BombOperationStateExtension on BombOperationState {
  /// Obtient le nom d'affichage de l'état
  String get displayName {
    switch (this) {
      case BombOperationState.waiting:
        return 'En attente';
      case BombOperationState.roundActive:
        return 'Round actif';
      case BombOperationState.bombPlanted:
        return 'Bombe posée';
      case BombOperationState.defusing:
        return 'Désamorçage en cours';
      case BombOperationState.bombDefused:
        return 'Bombe désamorcée';
      case BombOperationState.bombExploded:
        return 'Bombe explosée';
      case BombOperationState.roundEnd:
        return 'Fin du round';
      case BombOperationState.gameEnd:
        return 'Fin de la partie';
    }
  }
  
  /// Convertit une chaîne en BombOperationState
  static BombOperationState fromString(String value) {
    switch (value.toLowerCase()) {
      case 'waiting':
        return BombOperationState.waiting;
      case 'roundactive':
        return BombOperationState.roundActive;
      case 'bombplanted':
        return BombOperationState.bombPlanted;
      case 'defusing':
        return BombOperationState.defusing;
      case 'bombdefused':
        return BombOperationState.bombDefused;
      case 'bombexploded':
        return BombOperationState.bombExploded;
      case 'roundend':
        return BombOperationState.roundEnd;
      case 'gameend':
        return BombOperationState.gameEnd;
      default:
        throw ArgumentError('Valeur d\'état invalide: $value');
    }
  }
}
