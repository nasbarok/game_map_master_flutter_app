/// États possibles d'un site de bombe
enum BombSiteStatus {
  idle,      // Inactif, peut être armé
  armed,     // Armé, peut être désarmé ou va exploser
  disarmed,  // Désarmé, inactif
  exploded   // Explosé, inactif
}