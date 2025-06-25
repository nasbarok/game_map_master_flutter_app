import 'dart:math' as math;


import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/scenario/bomb_operation/bomb_operation_scenario.dart';
import '../models/scenario/bomb_operation/bomb_operation_state.dart';
import '../models/scenario/bomb_operation/bomb_operation_team.dart';
import '../models/scenario/bomb_operation/bomb_site.dart';
import '../utils/app_utils.dart';

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
    required List<BombSite> explodedBombSites,
    required double currentZoom,
  }) {
    final List<Marker> markers = [];

    final bool isAttacker = isAttackTeam(userTeamId, teamRoles);
    final bool isDefender = isDefenseTeam(userTeamId, teamRoles);

/*    logger.d('🎯 [BombOperationMapWidgetExtension] Rôle détecté : ${isAttacker ? "Attacker" : isDefender ? "Defender" : "Spectator/Unknown"}');
    logger.d('🧩 [BombOperationMapWidgetExtension] toActivateBombSites: ${toActivateBombSites.map((b) => b.name).join(", ")}');
    logger.d('🛑 [BombOperationMapWidgetExtension] disableBombSites: ${disableBombSites.map((b) => b.name).join(", ")}');
    logger.d('🔥 [BombOperationMapWidgetExtension] activeBombSites: ${activeBombSites.map((b) => b.name).join(", ")}');
    logger.d('💥 [BombOperationMapWidgetExtension] explodedBombSites: ${explodedBombSites.map((b) => b.name).join(", ")}');*/

    final Set<int> activeIds = activeBombSites.map((e) => e.id!).toSet();
    final Set<int> explodedIds = explodedBombSites.map((e) => e.id!).toSet();
    final Set<int> toActivateIds = toActivateBombSites.map((e) => e.id!).toSet();
    final Set<int> disableIds = disableBombSites.map((e) => e.id!).toSet();

    // Sélection explicite des sites visibles
    Iterable<BombSite> visibleSites = [];

    if (isAttacker) {
      visibleSites = [
        ...toActivateBombSites,
        ...activeBombSites,
        ...explodedBombSites,
      ];
    } else if (isDefender) {
      visibleSites = [
        ...disableBombSites,
        ...activeBombSites,
        ...explodedBombSites,
      ];
    }

    for (final site in visibleSites) {
      final int siteId = site.id!;
      final bool isPlanted = activeIds.contains(siteId);
      final bool isExploded = explodedIds.contains(siteId);
      final bool isDisarmed = activeBombSites.any((b) => b.id == siteId && b.active == false);
      final bool isToActivate = isAttacker && toActivateIds.contains(siteId);
      final bool isGreyed = isDefender && !isPlanted && !isDisarmed && !isExploded;

      final radiusInPixels =
      AppUtils.metersToPixels(site.radius, site.latitude, currentZoom);

      markers.add(
        Marker(
          point: LatLng(site.latitude, site.longitude),
          width: radiusInPixels * 2,
          height: radiusInPixels * 2,
          child: _buildBombSiteMarker(
            context: context,
            site: site,
            isPlanted: isPlanted,
            isExploded: isExploded,
            isDisarmed: isDisarmed,
            isToActivate: isToActivate,
            isAttacker: isAttacker,
            isDefender: isDefender,
            isGreyed: isGreyed,
            radiusInPixels: radiusInPixels,
          ),
        ),
      );
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

  /// Construit un marqueur pour un site de bombe
  Widget _buildBombSiteMarker({
    required BuildContext context,
    required BombSite site,
    required bool isPlanted,
    required bool isExploded,
    required bool isDisarmed,
    required bool isToActivate,
    required bool isAttacker,
    required bool isDefender,
    required bool isGreyed,
    required double radiusInPixels,
  }) {
    Color markerColor;
    IconData markerIcon;

    if (isExploded) {
      markerColor = Colors.black;
      markerIcon = Icons.whatshot;
    } else if (isDisarmed) {
      markerColor = Colors.blue;
      markerIcon = Icons.shield;
    } else if (isPlanted) {
      markerColor = Colors.red.shade800;
      markerIcon = Icons.local_fire_department;
    } else if (isToActivate) {
      markerColor = Colors.red.shade200;
      markerIcon = Icons.location_on;
    } else if (isGreyed) {
      markerColor = Colors.grey;
      markerIcon = Icons.location_on;
    } else {
      markerColor = site.getColor(context);
      markerIcon = Icons.location_on;
    }

    final double dynamicFontSize = math.max(8, radiusInPixels / 3);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: radiusInPixels * 2,
          height: radiusInPixels * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: markerColor.withOpacity(0.2),
            border: Border.all(
              color: markerColor,
              width: isExploded ? 3 : 2,
            ),
          ),
        ),
        Icon(
          markerIcon,
          color: markerColor,
          size: dynamicFontSize * 1.2,
        ),
        Positioned(
          bottom: radiusInPixels * 0.1,
          child: Text(
            site.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isExploded ? Colors.white : Colors.black,
              fontSize: dynamicFontSize,
              fontWeight: isExploded ? FontWeight.w900 : FontWeight.bold,
              shadows: [
                Shadow(
                  offset: const Offset(0, 0),
                  blurRadius: 2,
                  color: isExploded ? Colors.black : Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
