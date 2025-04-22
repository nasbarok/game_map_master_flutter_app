import 'package:flutter/material.dart';
import '../../models/scenario.dart';
import '../models/scenario/scenario_dto.dart';
import 'api_service.dart';

class ScenarioService extends ChangeNotifier {
  final ApiService _apiService;

  List<Scenario> _scenarios = [];

  List<Scenario> get scenarios => _scenarios;

  ScenarioService(this._apiService);

  // Charger tous les scénarios
  Future<void> loadScenarios() async {
    try {
      final response = await _apiService.get('scenarios/owner/self');
      _scenarios = (response as List).map((e) => Scenario.fromJson(e)).toList();
      notifyListeners();  // Met à jour l'UI
    } catch (e) {
      throw Exception('Erreur de chargement des scénarios: $e');
    }
  }

  // Ajouter un nouveau scénario
  Future<Scenario> addScenario(Scenario scenario) async {
    final response = await _apiService.post('scenarios', scenario.toJson());
    final newScenario = Scenario.fromJson(response);
    await loadScenarios();
    return newScenario;
  }


  // Mettre à jour un scénario existant
  Future<Scenario> updateScenario(Scenario scenario) async {
    final response = await _apiService.put('scenarios/${scenario.id}', scenario.toJson());
    final updatedScenario = Scenario.fromJson(response);
    await loadScenarios();
    return updatedScenario;
  }

  // Supprimer un scénario
  Future<void> deleteScenario(int scenarioId) async {
    try {
      await _apiService.delete('scenarios/$scenarioId');
      _scenarios.removeWhere((s) => s.id == scenarioId);
      notifyListeners();  // Met à jour l'UI
    } catch (e) {
      throw Exception('Erreur lors de la suppression du scénario: $e');
    }
  }

  Future<ScenarioDTO> getScenarioDTOById(int scenarioId) async {
    final response = await _apiService.get('scenarios/$scenarioId');
    return ScenarioDTO.fromJson(response);
  }
}
