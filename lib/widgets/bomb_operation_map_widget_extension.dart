import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_scenario.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_state.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_team.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_site.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:airsoft_game_map/utils/logger.dart';

/// Extension d'affichage pour GameMapWidget (ou tout widget similaire) avec gestion des sites de bombe
extension BombOperationMapWidgetExtension on Object {
  /// Génère les marqueurs pour les sites de bombe selon le rôle de l'utilisateur et l'état du jeu
  List<Marker> generateBombSiteMarkers({
    required BuildContext context,
    required BombOperationScenario bombScenario,
    required BombOperationState gameState,
    required Map<int, BombOperationTeam> teamRoles,
    required int? userTeamId,
    required List<BombSite> toActivateBombSites,
    required List<BombSite> disableBombSites,
    required List<BombSite> activeBombSites,
  }) {
    if (bombScenario.bombSites == null || bombScenario.bombSites!.isEmpty) {
      return [];
    }

    final List<Marker> markers = [];

    // Déterminer le rôle de l’équipe
    final bool isAttacker = isAttackTeam(userTeamId, teamRoles);
    final bool isDefender = isDefenseTeam(userTeamId, teamRoles);

    for (final site in bombScenario.bombSites!) {
      final bool isPlantedOrActivated = activeBombSites.contains(site.id);
      final bool isInToActivate = toActivateBombSites.any((s) => s.id == site.id);
      final bool isInDisabled = disableBombSites.any((s) => s.id == site.id);

      bool isVisible = false;
      bool isGreyed = false;

      if (isAttacker) {
        // Les attaquants voient uniquement les bombes "à activer"
        isVisible = isInToActivate;
        isGreyed = false;
      } else if (isDefender) {
        // Les défenseurs voient toutes les bombes désactivées + celles activées
        isVisible = isInDisabled || isPlantedOrActivated;
        isGreyed = !isPlantedOrActivated;
      }

      if (isVisible) {
        markers.add(
          Marker(
            point: LatLng(site.latitude, site.longitude),
            width: 50,
            height: 50,
            child: _buildBombSiteMarker(
              context: context,
              site: site,
              isPlanted: isPlantedOrActivated,
              isAttacker: isAttacker,
              isGreyed: isGreyed,
            ),
          ),
        );
      }
    }

    return markers;
  }

  bool isAttackTeam(int? teamId, Map<int, BombOperationTeam> teamRoles) {
    if (teamId == null) return false;
    return teamRoles[teamId] == BombOperationTeam.attack;
  }

  bool isDefenseTeam(int? teamId, Map<int, BombOperationTeam> teamRoles) {
    if (teamId == null) return false;
    return teamRoles[teamId] == BombOperationTeam.defense;
  }

  /// Construit le widget représentant un site de bombe
  Widget _buildBombSiteMarker({
    required BuildContext context,
    required BombSite site,
    required bool isPlanted,
    required bool isAttacker,
    required bool isGreyed,
  }) {
    final Color markerColor = isGreyed
        ? Colors.grey
        : isPlanted
        ? Colors.red
        : site.getColor(context);

    final IconData icon = isPlanted
        ? Icons.warning_amber_rounded
        : Icons.dangerous;

    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: markerColor.withOpacity(0.2),
            border: Border.all(color: markerColor, width: 2),
          ),
        ),
        Center(
          child: Icon(
            icon,
            color: markerColor,
            size: 30,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              site.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

}
