import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../models/scenario.dart';
import '../../../models/game_map.dart';
import '../../../services/auth_service.dart';
import '../../../services/game_map_service.dart';
import '../../../services/scenario/bomb_operation/bomb_operation_scenario_service.dart';
import '../../../services/scenario_service.dart';
import '../../map_editor/interactive_map_editor_screen.dart';
import 'bomb_operation_config_screen.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';
/// Extension du ScenarioFormScreen pour intégrer le scénario Opération Bombe
class BombOperationIntegration {
  /// Ajoute le type "Opération Bombe" à la liste des types de scénarios
  static void addScenarioType(BuildContext context,List<Map<String, dynamic>> scenarioTypes) {
    final l10n = AppLocalizations.of(context)!;
    scenarioTypes.add({
      'name': l10n.scenarioTypeBombOperation,
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
      final l10n = AppLocalizations.of(context)!;
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
                  title: Text(l10n.nonInteractiveMapTitle),
                  content: Text(l10n.nonInteractiveMapMessage),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(l10n.backButton),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.push(
                           context,
                          MaterialPageRoute(
                            builder: (context) => InteractiveMapEditorScreen(initialMap: gameMap),
                           ),
                        );
                      },
                      child: Text(l10n.interactiveMapEditorTitleEdit(gameMap.name)),
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
            SnackBar(
              content: Text(l10n.mapRequiredError),
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
            : l10n.scenarioNameHeader(l10n.scenarioTypeBombOperation),
        description: descriptionController.text.isNotEmpty
            ? descriptionController.text
            : l10n.bombOperationDescription,
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
    final l10n = AppLocalizations.of(context)!;
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
                    title: Text(l10n.nonInteractiveMapTitle),
                    content: Text(l10n.nonInteractiveMapMessage),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        child: Text(l10n.backButton),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (context) => InteractiveMapEditorScreen(initialMap: gameMap),
                             ),
                           );
                        },
                        child: Text(l10n.interactiveMapEditorTitleEdit(gameMap.name)),
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
      label: Text(l10n.configureBombOperation),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }
}
