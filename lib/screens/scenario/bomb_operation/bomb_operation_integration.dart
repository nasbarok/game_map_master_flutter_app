import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import '../../../models/scenario.dart';
import '../../../models/game_map.dart';
import '../../../services/auth_service.dart';
import '../../../services/game_map_service.dart';
import '../../../services/scenario/bomb_operation/bomb_operation_scenario_service.dart';
import '../../../services/scenario_service.dart';
import 'bomb_operation_config_screen.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';
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
      // Vérifier si la carte sélectionnée a une configuration interactive
      if (gameMapId != null) {
        logger.d('[BombOperationIntegration] [handleBombOperationTypeSelected] GameMapId: $gameMapId');
        final gameMapService = GetIt.I<GameMapService>();
        final gameMap = await gameMapService.getGameMapById(gameMapId);

        if (!gameMap.hasInteractiveMapConfig) {
          if (context.mounted) {
            // Afficher une boîte de dialogue avec options pour éditer ou créer une carte interactive
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text('Carte non interactive'),
                  content: const Text(
                    'Cette carte n\'a pas de configuration interactive nécessaire pour le scénario "Opération Bombe".\n\n'
                    'Vous devez d\'abord configurer cette carte dans l\'éditeur de carte interactif ou sélectionner une autre carte déjà configurée.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('Retour'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        // TODO: Naviguer vers l'éditeur de carte interactif
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => InteractiveMapEditorScreen(gameMap: gameMap),
                        //   ),
                        // );
                      },
                      child: const Text('Éditer cette carte'),
                    ),
                  ],
                );
              },
            );
            return; // Arrêter l'exécution pour ne pas créer le scénario
          }
        }
      } else {
        logger.d('[BombOperationIntegration] [handleBombOperationTypeSelected] GameMapId null');
        // Aucune carte sélectionnée
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez sélectionner une carte avant de créer un scénario "Opération Bombe"'),
              backgroundColor: Colors.red,
            ),
          );
          return; // Arrêter l'exécution pour ne pas créer le scénario
        }
      }

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

      logger.d('[BombOperationIntegration] [handleBombOperationTypeSelected] Scénario créé: ${newScenario.toJson()}');

      Scenario savedScenario;

      if (existingScenario == null) {
        // Création directe
        savedScenario = await scenarioService.addScenario(newScenario);
        logger.d('[BombOperationIntegration] [handleBombOperationTypeSelected] Scénario créé: ${savedScenario.toJson()}');
      } else {
        // Mise à jour directe
        savedScenario = await scenarioService.updateScenario(newScenario);
        logger.d('[BombOperationIntegration] [handleBombOperationTypeSelected] Scénario mis à jour: ${savedScenario.toJson()}');
      }

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BombOperationConfigScreen(
              scenarioId: savedScenario.id!,
              scenarioName: savedScenario.name,
              gameMapId: savedScenario.gameMapId!,
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
      onPressed: () async {
        // Vérifier si la carte associée au scénario a une configuration interactive
        if (scenario.gameMapId != null) {
          final gameMapService = GetIt.I<GameMapService>();
          final gameMap = await gameMapService.getGameMapById(scenario.gameMapId!);

          if (!gameMap.hasInteractiveMapConfig) {
            if (context.mounted) {
              // Afficher une boîte de dialogue avec options pour éditer ou créer une carte interactive
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Carte non interactive'),
                    content: const Text(
                      'La carte associée à ce scénario n\'a pas de configuration interactive nécessaire pour le scénario "Opération Bombe".\n\n'
                      'Vous devez d\'abord configurer cette carte dans l\'éditeur de carte interactif ou associer une autre carte déjà configurée à ce scénario.'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text('Retour'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          // TODO: Naviguer vers l'éditeur de carte interactif
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => InteractiveMapEditorScreen(gameMap: gameMap),
                          //   ),
                          // );
                        },
                        child: const Text('Éditer cette carte'),
                      ),
                    ],
                  );
                },
              );
              return; // Arrêter l'exécution pour ne pas ouvrir l'écran de configuration
            }
          }
        }

        // Si la carte est valide, naviguer vers l'écran de configuration
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BombOperationConfigScreen(
              scenarioId: scenario.id!,
              scenarioName: scenario.name,
              gameMapId: scenario.gameMapId!,
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
