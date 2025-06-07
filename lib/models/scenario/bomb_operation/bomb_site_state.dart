// Classe pour stocker l'état d'un site de bombe
import 'dart:ui';

class BombSiteState {
  final Color color;
  final bool isPlanted;
  final bool isGreyed;

  BombSiteState({
    required this.color,
    required this.isPlanted,
    required this.isGreyed,
  });
}