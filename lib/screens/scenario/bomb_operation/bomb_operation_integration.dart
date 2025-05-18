import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import '../../../models/scenario.dart';
import '../../../services/auth_service.dart';
import '../../../services/scenario/bomb_operation/bomb_operation_scenario_service.dart';
import '../../../services/scenario_service.dart';
import 'bomb_operation_config_screen.dart';

/// Extension du ScenarioFormScreen pour intégrer le scénario Opération Bombe
class BombOperationIntegration {
  /// Ajoute le type "Opération Bombe" à la liste des types de scénarios
  static void addScenarioType(List<Map<String, dynamic>> scenarioTypes) {
    scenarioTypes.add({
      'name': 'Opération Bombe',
      'value': 'bomb_operation',
    });
  }

  /// Gère la sélection du type "Opération Bombe"
  static Future<void> handleBombOperationTypeSelected(
    BuildContext context,
    Scenario? existingScenario,
    TextEditingController nameController,
    TextEditingController descriptionController,
    int? gameMapId,
  ) async {
    try {
      final scenarioService = ScenarioService(GetIt.I());
      final authService = GetIt.I<AuthService>();
      final currentUser = authService.currentUser;
      // Déterminer les données
      final newScenario = Scenario(
        id: existingScenario?.id,
        name: nameController.text.isNotEmpty
            ? nameController.text
            : 'Scénario Opération Bombe',
        description: descriptionController.text,
        type: 'bomb_operation',
        gameMapId: gameMapId,
        creator: currentUser,
        gameSessionId: null,
        active: existingScenario?.active ?? false,
      );

      Scenario savedScenario;

      if (existingScenario == null) {
        // Création directe
        savedScenario = await scenarioService.addScenario(newScenario);
      } else {
        // Mise à jour directe
        savedScenario = await scenarioService.updateScenario(newScenario);
      }

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BombOperationConfigScreen(
              scenarioId: savedScenario.id!,
              scenarioName: savedScenario.name,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du scénario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Ajoute un bouton de configuration pour un scénario Opération Bombe existant
  static Widget buildConfigButton(BuildContext context, Scenario scenario) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BombOperationConfigScreen(
              scenarioId: scenario.id!,
              scenarioName: scenario.name,
            ),
          ),
        );
      },
      icon: const Icon(Icons.settings),
      label: const Text('Configurer l\'Opération Bombe'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }
}
