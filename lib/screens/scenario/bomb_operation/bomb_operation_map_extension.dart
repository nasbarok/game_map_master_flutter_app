import 'dart:math' as math;

import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_scenario.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_state.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_team.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_site.dart';
import 'package:airsoft_game_map/screens/gamesession/game_map_screen.dart';
import 'package:airsoft_game_map/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:airsoft_game_map/utils/logger.dart';

/// Extension du GameMapScreen pour le scénario Opération Bombe
extension BombOperationMapExtension on GameMapScreen {

  /// Détermine si l'utilisateur est dans l'équipe d'attaque (terroriste)
  bool isAttackTeam(int? userTeamId, Map<int, BombOperationTeam> teamRoles) {
    if (userTeamId == null) return false;
    return teamRoles[userTeamId] == BombOperationTeam.attack;
  }

  /// Détermine si l'utilisateur est dans l'équipe de défense (anti-terroriste)
  bool isDefenseTeam(int? userTeamId, Map<int, BombOperationTeam> teamRoles) {
    if (userTeamId == null) return false;
    return teamRoles[userTeamId] == BombOperationTeam.defense;
  }

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
    required double currentZoom,
  }) {
    final List<Marker> markers = [];

    final bool isAttacker = isAttackTeam(userTeamId, teamRoles);
    final bool isDefender = isDefenseTeam(userTeamId, teamRoles);

  /*  logger.d('🎯 [BombOperationMapExtension] Rôle détecté : ${isAttacker ? "Attacker" : isDefender ? "Defender" : "Spectator/Unknown"}');
    logger.d('🧩 [BombOperationMapExtension] toActivateBombSites: ${toActivateBombSites.map((b) => b.name).join(", ")}');
    logger.d('🛑 [BombOperationMapExtension] disableBombSites: ${disableBombSites.map((b) => b.name).join(", ")}');
    logger.d('🔥 [BombOperationMapExtension] activeBombSites: ${activeBombSites.map((b) => b.name).join(", ")}');*/

    final Set<int> activeIds = activeBombSites.map((e) => e.id!).toSet();

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
            isAttacker: isAttacker,
            isGreyed: isGreyed,
            radiusInPixels: radiusInPixels,
          ),
        ),
      );
    }

    return markers;
  }

  /// Construit un marqueur pour un site de bombe
  Widget _buildBombSiteMarker({
    required BuildContext context,
    required BombSite site,
    required bool isPlanted,
    required bool isAttacker,
    required bool isGreyed,
    required double radiusInPixels,
  }) {
    // Couleur du marqueur
    Color markerColor;
    if (isGreyed) {
      markerColor = Colors.grey;
    } else if (isPlanted) {
      markerColor = Colors.red.shade800;
    } else if (isAttacker) {
      markerColor = Colors.red.shade200;
    } else {
      markerColor = site.getColor(context);
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
            border: Border.all(color: markerColor, width: 2),
          ),
        ),

        // Icône bombe au centre si plantée
        if (isPlanted)
          Icon(
            Icons.local_fire_department,
            color: markerColor,
            size: dynamicFontSize * 1.2,
          ),

        // Nom du site (toujours affiché)
        Text(
          site.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: dynamicFontSize,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                offset: Offset(0, 0),
                blurRadius: 2,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
