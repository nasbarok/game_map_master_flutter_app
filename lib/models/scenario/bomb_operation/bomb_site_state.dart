// Classe pour stocker l'état d'un site de bombe
import 'dart:ui';

import 'bomb_site_status.dart';

class BombSiteState {
  final Color color;
  final bool isPlanted;
  final bool isGreyed;
  final BombSiteStatus status;
  BombSiteState({
    required this.color,
    required this.isPlanted,
    required this.isGreyed,
    required this.status,
  });
}