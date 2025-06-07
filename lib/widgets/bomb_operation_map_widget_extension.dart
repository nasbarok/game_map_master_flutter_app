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
    required double currentZoom,
  }) {
    if (disableBombSites == null || disableBombSites.isEmpty) {
      return [];
    }

    final List<Marker> markers = [];

    // Déterminer le rôle de l'équipe de l'utilisateur
    final bool isAttacker = isAttackTeam(userTeamId, teamRoles);
    final bool isDefender = isDefenseTeam(userTeamId, teamRoles);

    // Parcourir tous les sites de bombe
    for (final site in disableBombSites) {
      // Déterminer si ce site est actif pour ce round
      final bool isActive = activeBombSites.contains(site.id);

      // Déterminer si une bombe est plantée sur ce site
      final bool isPlanted = activeBombSites.contains(site.id);

      // Déterminer si ce site doit être visible pour l'utilisateur
      bool isVisible = false;
      bool isGreyed = false;

      if (isAttacker) {
        // Les attaquants (terroristes) voient uniquement les bombes sélectionnées pour la partie
        isVisible = isActive;
        isGreyed = false; // Les terroristes voient toujours les bombes actives en couleur normale
      } else if (isDefender) {
        // Les défenseurs (anti-terroristes) voient toutes les bombes
        isVisible = true; // Toujours visible

        // Mais les bombes non actives ou non plantées sont grisées
        isGreyed = !isPlanted && !isActive;
      }
      final radiusInPixels = AppUtils.metersToPixels(site.radius, site.latitude, currentZoom);

      // Si le site doit être visible, ajouter un marqueur
      if (isVisible) {
        markers.add(
          Marker(
            point: LatLng(site.latitude, site.longitude),
            width: radiusInPixels * 2, // Diamètre = 2 * rayon
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
    required bool isAttacker,
    required bool isGreyed,
    required double radiusInPixels,
  }) {
    // Couleur du marqueur
    Color markerColor;
    if (isGreyed) {
      markerColor = Colors.grey;
    } else if (isPlanted) {
      markerColor = Colors.red;
    } else {
      markerColor = site.getColor(context);
    }

    // Déterminer l'icône
    final IconData iconData = isPlanted
        ? Icons.warning_amber_rounded
        : Icons.dangerous;

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
        // Texte du nom centré, noir avec ombre blanche
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
