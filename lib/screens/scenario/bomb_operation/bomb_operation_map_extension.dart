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

  /// Construit un marqueur pour un site de bombe
  Widget _buildBombSiteMarker({
    required BuildContext context,
    required BombSite site,
    required bool isPlanted,
    required bool isAttacker,
    required bool isGreyed,
    required double radiusInPixels,
  }) {
    // Couleur du marqueur selon l'état de la bombe
    Color markerColor;

    if (isGreyed) {
      // Bombe grisée (pour les anti-terroristes, bombes inactives)
      markerColor = Colors.grey;
    } else if (isPlanted) {
      // Bombe plantée (compte à rebours actif)
      markerColor = Colors.red;
    } else {
      // Couleur normale du site
      markerColor = site.getColor(context);
    }

    // Icône selon le rôle et l'état
    final IconData iconData = isPlanted
        ? Icons.warning_amber_rounded  // Bombe active
        : Icons.dangerous;  // Site de bombe normal

    return Stack(
      children: [
        // Cercle représentant le rayon d'action
        Container(
          width: radiusInPixels * 2,
          height: radiusInPixels * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: markerColor.withOpacity(0.2),
            border: Border.all(
              color: markerColor,
              width: 2,
            ),
          ),
        ),

        // Icône centrale
        Center(
          child: Icon(
            iconData,
            color: markerColor,
            size: math.min(30, radiusInPixels * 0.6),
          ),
        ),

        // Nom du site
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
