import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../models/scenario/scenario_dto.dart';
import '../../models/scenario/treasure_hunt/treasure_hunt_scenario.dart';
import '../../services/api_service.dart';
import '../../services/game_state_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';
class ScenarioSelectionDialog extends StatefulWidget {
  final int mapId;

  const ScenarioSelectionDialog({
    Key? key,
    required this.mapId,
  }) : super(key: key);

  @override
  State<ScenarioSelectionDialog> createState() =>
      _ScenarioSelectionDialogState();
}

class _ScenarioSelectionDialogState extends State<ScenarioSelectionDialog> {
  bool _isLoading = true;
  List<ScenarioDTO> _scenarios = [];
  List<TreasureHuntScenario> _treasureHuntDetails = [];
  List<int> _selectedScenarioIds = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadScenarios();
  }

  Future<void> _loadScenarios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = GetIt.I<ApiService>();
      final scenariosData = await apiService.get('scenarios/owner/self/full');

      setState(() {
        _scenarios = List<ScenarioDTO>.from(scenariosData
            .map((scenarioData) => ScenarioDTO.fromJson(scenarioData)));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Erreur lors du chargement des scénarios: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _buildScenarioSubtitle(ScenarioDTO scenarioDTO) {
    if (scenarioDTO.treasureHuntScenario != null) {
      final treasureHunt = scenarioDTO.treasureHuntScenario!;
      return 'Chasse au trésor - ${treasureHunt.totalTreasures} QR codes';
    } else {
      return scenarioDTO.scenario.description ?? '';
    }
  }

  bool isScenarioSelectable(ScenarioDTO scenarioDTO) {
    final treasureHunt = scenarioDTO.treasureHuntScenario;

    if (treasureHunt != null) {
      if (treasureHunt.size == 'BIG') {
        // Déjà un BIG sélectionné différent ?
        final alreadyBigSelected = _scenarios.any((s) =>
            _selectedScenarioIds.contains(s.scenario.id) &&
            s.treasureHuntScenario?.size == 'BIG');

        if (alreadyBigSelected &&
            !_selectedScenarioIds.contains(scenarioDTO.scenario.id)) {
          return false;
        }
      } else if (treasureHunt.size == 'SMALL') {
        // Déjà un SMALL du même type sélectionné ?
        final alreadySameSmallSelected = _scenarios.any((s) =>
            _selectedScenarioIds.contains(s.scenario.id) &&
            s.treasureHuntScenario?.size == 'SMALL' &&
            s.scenario.type == scenarioDTO.scenario.type);

        if (alreadySameSmallSelected &&
            !_selectedScenarioIds.contains(scenarioDTO.scenario.id)) {
          return false;
        }
      }
    }

    // Si pas TreasureHunt ou pas de conflit
    return true;
  }

  Future<void> _validateScenarioSelection(
    BuildContext context,
    List<ScenarioDTO> allScenarios,
    List<int> selectedScenarioIds,
  ) async {
    final apiService = GetIt.I<ApiService>();
    final gameStateService = context.read<GameStateService>();

    final selectedScenarioDtos = allScenarios
        .where((dto) => selectedScenarioIds.contains(dto.scenario.id))
        .toList();

    try {
      final fieldId = gameStateService.selectedMap?.field?.id;
      if (fieldId != null) {
        // 1. API : Envoyer les IDs au backend
        await apiService.postList('fields/$fieldId/scenarios',
            selectedScenarioDtos.map((dto) => dto.toJson()).toList());

        // 2. Mise à jour locale : juste GameStateService
        WidgetsBinding.instance.addPostFrameCallback((_) {
          gameStateService.setSelectedScenarios(selectedScenarioDtos);
        });

        Navigator.pop(context); // Fermer le dialogue

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scénarios bien sélectionnés')),
        );
      }
    } catch (e) {
      logger.d('❌ Erreur lors de la mise à jour des scénarios: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la mise à jour des scénarios'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sélectionner les scénarios',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Column(
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadScenarios,
                    child: const Text('Réessayer'),
                  ),
                ],
              )
            else if (_scenarios.isEmpty)
              const Text(
                'Aucun scénario disponible.\nCréez un scénario d\'abord.',
                textAlign: TextAlign.center,
              )
            else
              SizedBox(
                height: 300,
                width: 300,
                child: ListView.builder(
                  itemCount: _scenarios.length,
                  itemBuilder: (context, index) {
                    final scenarioDTO = _scenarios[index];
                    final scenario = scenarioDTO.scenario;
                    final isSelected =
                        _selectedScenarioIds.contains(scenario.id);
                    return CheckboxListTile(
                      title: Text(scenario.name),
                      subtitle: Text(
                        _buildScenarioSubtitle(scenarioDTO),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: _selectedScenarioIds.contains(scenario.id),
                      onChanged: isScenarioSelectable(scenarioDTO)
                          ? (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedScenarioIds.add(scenario.id!);
                                } else {
                                  _selectedScenarioIds.remove(scenario.id);
                                }
                              });
                            }
                          : null,
                      // Désactive l'interaction si non sélectionnable
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Annuler => rien ne retourne
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => _validateScenarioSelection(
                      context, _scenarios, _selectedScenarioIds),
                  child: const Text('Valider'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
