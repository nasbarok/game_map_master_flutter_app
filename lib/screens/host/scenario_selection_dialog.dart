import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/scenario.dart';
import '../../services/api_service.dart';
import 'qr_code_generator_screen.dart';

class ScenarioSelectionDialog extends StatefulWidget {
  final int mapId;
  final Function(List<Map<String, dynamic>>) onScenariosSelected;

  const ScenarioSelectionDialog({
    Key? key,
    required this.mapId,
    required this.onScenariosSelected,
  }) : super(key: key);

  @override
  State<ScenarioSelectionDialog> createState() => _ScenarioSelectionDialogState();
}

class _ScenarioSelectionDialogState extends State<ScenarioSelectionDialog> {
  bool _isLoading = true;
  List<Scenario> _scenarios = [];
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
      final apiService = Provider.of<ApiService>(context, listen: false);
      final scenariosData = await apiService.get('scenarios');

      setState(() {
        _scenarios = List<Scenario>.from(
          scenariosData.map((scenarioData) => Scenario.fromJson(scenarioData))
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des scénarios: ${e.toString()}';
        _isLoading = false;
      });
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
              'Sélectionner un scénario',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Column(
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
                    : _scenarios.isEmpty
                        ? const Text(
                            'Aucun scénario disponible. Créez un scénario d\'abord.',
                            textAlign: TextAlign.center,
                          )
                        : SizedBox(
                            height: 300,
                            width: 300,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _scenarios.length,
                              itemBuilder: (context, index) {
                                final scenario = _scenarios[index];
                                return ListTile(
                                  title: Text(scenario.name),
                                  subtitle: Text(
                                    scenario.description ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    widget.onScenariosSelected([
                                      {
                                        'id': scenario.id,
                                        'name': scenario.name,
                                        'description': scenario.description,
                                      }
                                    ]);
                                    Navigator.pop(context); // on ferme le dialog
                                  },
                                );
                              },
                            ),
                          ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}
