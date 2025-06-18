import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Interface abstraite pour les extensions de replay de scénarios
/// 
/// Cette interface définit le contrat que chaque scénario doit implémenter
/// pour être compatible avec le système de replay de GameReplayScreen.
/// 
/// Chaque scénario peut ainsi fournir :
/// - Sa propre logique de chargement des données
/// - Sa mise à jour d'état en fonction du temps
/// - Ses marqueurs spécifiques sur la carte
/// - Son panneau d'information personnalisé
abstract class ScenarioReplayExtension {
  
  /// Charge les données nécessaires pour le replay du scénario
  /// 
  /// [gameSessionId] : ID de la session de jeu à analyser
  /// 
  /// Cette méthode doit récupérer toutes les données historiques
  /// nécessaires au replay (états, événements, etc.)
  Future<void> loadData(int gameSessionId);
  
  /// Met à jour l'état du scénario pour un temps donné
  /// 
  /// [currentTime] : Temps actuel du replay
  /// 
  /// Cette méthode doit calculer l'état de tous les éléments
  /// du scénario (sites, objets, etc.) au temps spécifié
  void updateState(DateTime currentTime);
  
  /// Construit les marqueurs à afficher sur la carte
  /// 
  /// Retourne une liste de [Marker] représentant les éléments
  /// du scénario (sites de bombe, QR codes, zones, etc.)
  /// avec leur état visuel actuel
  List<Marker> buildMarkers();
  
  /// Construit le panneau d'information du scénario
  /// 
  /// Retourne un [Widget] optionnel contenant :
  /// - Les statistiques du scénario
  /// - La timeline des événements
  /// - Les résumés par équipe
  /// - Toute autre information pertinente
  /// 
  /// Retourne null si aucun panneau n'est nécessaire
  Widget? buildInfoPanel();
  
  /// Indique si le scénario a des données chargées
  /// 
  /// Retourne true si [loadData] a été appelé avec succès
  /// et que les données sont disponibles pour le replay
  bool get hasData;
  
  /// Obtient le nom du scénario
  /// 
  /// Retourne le nom du scénario pour l'affichage
  String get scenarioName;
  
  /// Obtient le type du scénario
  /// 
  /// Retourne le type du scénario (ex: "BOMB_OPERATION", "TREASURE_HUNT")
  String get scenarioType;
  
  /// Libère les ressources utilisées par l'extension
  /// 
  /// Cette méthode doit être appelée lors de la destruction
  /// de l'écran de replay pour nettoyer les ressources
  void dispose();
}

