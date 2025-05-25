import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../models/scenario/bomb_operation/bomb_operation_notification.dart';
import '../../../models/scenario/bomb_operation/bomb_operation_scenario.dart';
import '../../../models/scenario/bomb_operation/bomb_operation_score.dart';
import '../../../models/scenario/bomb_operation/bomb_site.dart';
import '../../api_service.dart';

/// Service dédié à la gestion des scénarios Opération Bombe
class BombOperationScenarioService {
  final ApiService _apiService;
  
  /// Contrôleur de flux pour les notifications d'événements
  final _notificationController = StreamController<BombOperationNotification>.broadcast();
  
  /// Flux d'événements pour les notifications
  Stream<BombOperationNotification> get notificationStream => _notificationController.stream;

  /// Constructeur
  BombOperationScenarioService(this._apiService);

  /// Libère les ressources
  void dispose() {
    _notificationController.close();
  }

  /// Récupère un scénario Opération Bombe par son ID
  Future<BombOperationScenario> getBombOperationScenario(int scenarioId) async {
    final response = await _apiService.get('scenarios/bomb-operation/$scenarioId');
    return BombOperationScenario.fromJson(response);
  }

  /// Crée un nouveau scénario Opération Bombe
  Future<BombOperationScenario> createBombOperationScenario(BombOperationScenario scenario) async {
    final response = await _apiService.post('scenarios/bomb-operation', scenario.toJson());
    return BombOperationScenario.fromJson(response);
  }

  /// Met à jour un scénario Opération Bombe existant
  Future<BombOperationScenario> updateBombOperationScenario(BombOperationScenario scenario) async {
    final response = await _apiService.put(
      'scenarios/bomb-operation/${scenario.id}', 
      scenario.toJson()
    );
    return BombOperationScenario.fromJson(response);
  }

  /// Récupère tous les sites de bombe d'un scénario
  Future<List<BombSite>> getBombSites(int bombOperationScenarioId) async {
    final response = await _apiService.get('scenarios/bomb-operation/$bombOperationScenarioId/bomb-sites');
    return (response as List).map((item) => BombSite.fromJson(item)).toList();
  }

  /// Crée un nouveau site de bombe
  Future<BombSite> createBombSite(BombSite site) async {
    final json = site.toJson();
    print('[BombOperationScenarioService] [createBombSite] Payload envoyé: $json');
    final response = await _apiService.post(
      'scenarios/bomb-operation/${site.scenarioId}/bomb-sites',
      json,
    );
    print('[BombOperationScenarioService] [createBombSite] Réponse du serveur: $response');
    return BombSite.fromJson(response);
  }

  /// Met à jour un site de bombe existant
  Future<BombSite> updateBombSite(BombSite site) async {
    final response = await _apiService.put(
      'scenarios/bomb-operation/bomb-sites/${site.id}',
      site.toJson()
    );
    print('[BombOperationScenarioService] [updateBombSite] Réponse du serveur: $response');
    return BombSite.fromJson(response);
  }

  /// Supprime un site de bombe
  Future<void> deleteBombSite(int siteId) async {
    await _apiService.delete('scenarios/bomb-operation/bomb-sites/$siteId');
  }

  /// S'assure qu'un scénario Opération Bombe existe pour l'ID de scénario donné
  /// Si le scénario n'existe pas, il sera créé avec des valeurs par défaut
  Future<BombOperationScenario> ensureBombOperationScenario(int scenarioId) async {
    final response = await _apiService.post('scenarios/bomb-operation/$scenarioId/ensure', {});

    // Loguer la réponse brute pour vérifier la structure des données
    print("[BombOperationScenarioService] [ensureBombOperationScenario] Réponse brute du serveur : $response");

    // Assurer que la réponse est valide et conforme au format attendu
    try {
      return BombOperationScenario.fromJson(response);
    } catch (e) {
      print("[BombOperationScenarioService] [ensureBombOperationScenario] Erreur lors du parsing de la réponse : $e");
      rethrow; // Relancer l'exception pour un traitement ultérieur
    }
  }

  /// Récupère les scores d'un scénario Opération Bombe
  Future<List<BombOperationScore>> getScores(int scenarioId) async {
    final response = await _apiService.get('scenarios/bomb-operation/$scenarioId/scores');
    return (response as List).map((item) => BombOperationScore.fromJson(item)).toList();
  }

  /// Réinitialise les scores d'un scénario Opération Bombe
  Future<void> resetScores(int scenarioId) async {
    await _apiService.post('scenarios/bomb-operation/$scenarioId/reset-scores', {});
  }

  /// Ajoute une notification au flux d'événements
  void addNotification(BombOperationNotification notification) {
    _notificationController.add(notification);
  }
}
