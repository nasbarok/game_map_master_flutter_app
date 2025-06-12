import 'dart:math' as math;

import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_scenario.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_state.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_team.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_site.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:airsoft_game_map/utils/logger.dart';

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

    logger.d('🎯 [BombOperationMapWidgetExtension] Rôle détecté : ${isAttacker ? "Attacker" : isDefender ? "Defender" : "Spectator/Unknown"}');
    logger.d('🧩 [BombOperationMapWidgetExtension] toActivateBombSites: ${toActivateBombSites.map((b) => b.name).join(", ")}');
    logger.d('🛑 [BombOperationMapWidgetExtension] disableBombSites: ${disableBombSites.map((b) => b.name).join(", ")}');
    logger.d('🔥 [BombOperationMapWidgetExtension] activeBombSites: ${activeBombSites.map((b) => b.name).join(", ")}');
    logger.d('💥 [BombOperationMapWidgetExtension] explodedBombSites: ${explodedBombSites.map((b) => b.name).join(", ")}');

    final Set<int> activeIds = activeBombSites.map((e) => e.id!).toSet();
    final Set<int> explodedIds = explodedBombSites.map((e) => e.id!).toSet();

    // Sélection explicite des sites visibles
    Iterable<BombSite> visibleSites = [];

    if (isAttacker) {
      visibleSites = toActivateBombSites;
    } else if (isDefender) {
      visibleSites = disableBombSites;
    }

    for (final site in visibleSites) {
      final int siteId = site.id!;
      final bool isPlanted = activeIds.contains(siteId);
      final bool isExploded = explodedIds.contains(siteId);
      final bool isGreyed = isDefender && !isPlanted;

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
            isAttacker: isAttacker,
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
    required bool isAttacker,
    required bool isGreyed,
    required double radiusInPixels,
  }) {
    // Couleur du marqueur
    Color markerColor;
    IconData markerIcon;
    if (isExploded) {
      // ✨ NOUVEAU : Sites explosés en orange/rouge foncé
      markerColor = Colors.deepOrange.shade800;
      markerIcon = Icons.whatshot; // Icône de flamme/explosion
    } else if (isGreyed) {
      markerColor = Colors.grey;
      markerIcon = Icons.location_on;
    } else if (isPlanted) {
      markerColor = Colors.red.shade800;
      markerIcon = Icons.local_fire_department;
    } else if (isAttacker) {
      markerColor = Colors.red.shade200;
      markerIcon = Icons.location_on;
    } else {
      markerColor = site.getColor(context);
      markerIcon = Icons.location_on;
    }

    // Taille du texte en fonction du rayon
    final double dynamicFontSize = math.max(8, radiusInPixels / 3);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Cercle de rayon
        Container(
          width: radiusInPixels * 2,
          height: radiusInPixels * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: markerColor.withOpacity(0.2),
            border: Border.all(
              color: markerColor,
              width: isExploded ? 3 : 2, // ✨ Bordure plus épaisse si explosé
              style: isExploded ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
        ),

        // Icône au centre
        Icon(
          markerIcon,
          color: markerColor,
          size: dynamicFontSize * 1.2,
        ),

        // Nom du site (toujours affiché)
        Positioned(
          bottom: radiusInPixels * 0.1,
          child: Text(
            site.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isExploded ? Colors.white : Colors.black,
              // ✨ Texte blanc si explosé
              fontSize: dynamicFontSize,
              fontWeight: isExploded ? FontWeight.w900 : FontWeight.bold,
              // ✨ Plus gras si explosé
              shadows: [
                Shadow(
                  offset: const Offset(0, 0),
                  blurRadius: 2,
                  color: isExploded
                      ? Colors.black
                      : Colors.white, // ✨ Ombre inversée si explosé
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
