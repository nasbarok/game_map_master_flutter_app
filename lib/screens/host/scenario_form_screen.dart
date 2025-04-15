import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../models/scenario.dart';
import '../../models/game_map.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_map_service.dart';
import '../../services/scenario_service.dart';
import '../scenario/treasure_hunt/treasure_hunt_config_screen.dart';

class ScenarioFormScreen extends StatefulWidget {
  final Scenario? scenario;

  const ScenarioFormScreen({Key? key, this.scenario}) : super(key: key);

  @override
  State<ScenarioFormScreen> createState() => _ScenarioFormScreenState();
}

class _ScenarioFormScreenState extends State<ScenarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedType;
  GameMap? _selectedMap;
  List<GameMap> _availableMaps = [];

  bool _isLoading = false;
  bool _isLoadingMaps = true;

  final List<Map<String, dynamic>> _scenarioTypes = [
    {'name': 'Chasse au trésor', 'value': 'treasure_hunt'},
    {'name': 'Capture de drapeau', 'value': 'capture_flag'},
    {'name': 'Domination', 'value': 'domination'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.scenario != null) {
      _nameController.text = widget.scenario!.name;
      _descriptionController.text = widget.scenario!.description ?? '';
      _selectedType = widget.scenario!.type;
    } else {
      _selectedType = null; //  Aucun type sélectionné au départ
    }

    _loadMaps();
  }

  Future<void> _loadMaps() async {
    setState(() {
      _isLoadingMaps = true;
    });

    try {
      final gameMapService = context.read<GameMapService>();
      if (gameMapService.gameMaps.isEmpty) {
        await gameMapService
            .loadGameMaps(); // Charger les cartes si pas encore chargées
      }
      final maps = gameMapService.gameMaps;

      GameMap? selected;

      if (widget.scenario != null &&
          widget.scenario!.gameMapId != null &&
          maps.isNotEmpty) {
        selected = maps.firstWhere(
          (map) => map.id == widget.scenario!.gameMapId,
          orElse: () => maps.first,
        );
      } else if (maps.isNotEmpty) {
        selected = maps.first;
      }

      setState(() {
        _availableMaps = maps;
        _selectedMap = selected;
        _isLoadingMaps = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMaps = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Erreur lors du chargement des cartes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveScenario() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMap == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une carte'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final scenarioService = context.read<ScenarioService>();

        final scenario = Scenario(
          id: widget.scenario?.id,
          name: _nameController.text,
          description: _descriptionController.text,
          type: _selectedType!,
          gameMapId: _selectedMap!.id,
          creator: GetIt.I<AuthService>().currentUser!,
          gameSessionId: null,
          active: widget.scenario?.active ?? false,
        );

        if (widget.scenario == null) {
          await scenarioService
              .addScenario(scenario); // Ajouter et recharger automatiquement
        } else {
          await scenarioService.updateScenario(
              scenario); // Modifier et recharger automatiquement
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scénario sauvegardé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scenario == null
            ? 'Nouveau scénario'
            : 'Modifier le scénario'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du scénario *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom pour le scénario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type de scénario *',
                        border: OutlineInputBorder(),
                      ),
                      items: _scenarioTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['value'],
                          child: Text(type['name']),
                        );
                      }).toList(),
                      onChanged: (widget.scenario != null &&
                              _selectedType == 'treasure_hunt')
                          ? null // Désactiver si édition et treasure_hunt
                          : (value) async {
                              if (value != null) {
                                setState(() {
                                  _selectedType = value;
                                });

                                if (value == 'treasure_hunt') {
                                  await _handleTreasureHuntTypeSelected();
                                }
                              }
                            },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner un type de scénario';
                        }
                        return null;
                      },
                    ),
                    if (widget.scenario != null &&
                        _selectedType == 'treasure_hunt') ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TreasureHuntConfigScreen(
                                scenarioId: widget.scenario!.id!,
                                scenarioName: widget.scenario!.name,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Configurer la chasse au trésor'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueGrey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _isLoadingMaps
                        ? const Center(child: CircularProgressIndicator())
                        : _availableMaps.isEmpty
                            ? const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Aucune carte disponible. Veuillez d\'abord créer une carte.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              )
                            : DropdownButtonFormField<GameMap>(
                                value: _selectedMap,
                                decoration: const InputDecoration(
                                  labelText: 'Carte *',
                                  border: OutlineInputBorder(),
                                ),
                                items: _availableMaps.map((map) {
                                  return DropdownMenuItem<GameMap>(
                                    value: map,
                                    child: Text(map.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMap = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Veuillez sélectionner une carte';
                                  }
                                  return null;
                                },
                              ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _availableMaps.isEmpty ? null : _saveScenario,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.scenario == null
                            ? 'Créer le scénario'
                            : 'Mettre à jour le scénario',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _handleTreasureHuntTypeSelected() async {
    try {
      final scenarioService = context.read<ScenarioService>();
      final authService = GetIt.I<AuthService>();

      // Déterminer les données
      final newScenario = Scenario(
        id: widget.scenario?.id,
        name: _nameController.text.isNotEmpty
            ? _nameController.text
            : 'Scénario de chasse au trésor',
        description: _descriptionController.text,
        type: 'treasure_hunt',
        gameMapId: _selectedMap?.id,
        // Peut être null si pas sélectionné
        creator: authService.currentUser!,
        gameSessionId: null,
        active: widget.scenario?.active ?? false,
      );

      Scenario savedScenario;

      if (widget.scenario == null) {
        // Création directe
        savedScenario = await scenarioService.addScenario(newScenario);
      } else {
        // Mise à jour directe
        savedScenario = await scenarioService.updateScenario(newScenario);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TreasureHuntConfigScreen(
              scenarioId: savedScenario.id!,
              scenarioName: savedScenario.name,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du scénario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
