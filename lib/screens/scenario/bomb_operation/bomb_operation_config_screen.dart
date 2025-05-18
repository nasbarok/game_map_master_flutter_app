import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../../models/scenario/bomb_operation/bomb_operation_scenario.dart';
import '../../../services/scenario/bomb_operation/bomb_operation_scenario_service.dart';
import '../../../services/scenario_service.dart';
import 'bomb_site_list_screen.dart';

/// Écran de configuration d'un scénario Opération Bombe
class BombOperationConfigScreen extends StatefulWidget {
  /// Identifiant du scénario
  final int scenarioId;
  
  /// Nom du scénario
  final String scenarioName;

  /// Constructeur
  const BombOperationConfigScreen({
    Key? key,
    required this.scenarioId,
    required this.scenarioName,
  }) : super(key: key);

  @override
  State<BombOperationConfigScreen> createState() => _BombOperationConfigScreenState();
}

class _BombOperationConfigScreenState extends State<BombOperationConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late BombOperationScenarioService _bombOperationService;
  BombOperationScenario? _scenario;
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Contrôleurs pour les champs de formulaire
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _roundDurationController = TextEditingController();
  final _bombTimerController = TextEditingController();
  final _defuseTimeController = TextEditingController();
  final _roundsToPlayController = TextEditingController();
  final _activeSitesPerRoundController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _bombOperationService = GetIt.I<BombOperationScenarioService>();
    _loadScenario();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _roundDurationController.dispose();
    _bombTimerController.dispose();
    _defuseTimeController.dispose();
    _roundsToPlayController.dispose();
    _activeSitesPerRoundController.dispose();
    super.dispose();
  }
  
  /// Charge les données du scénario depuis le backend
  Future<void> _loadScenario() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Assure que le scénario BombOperation existe pour cet ID
      final scenario = await _bombOperationService.ensureBombOperationScenario(widget.scenarioId);
      
      // Initialise les contrôleurs avec les valeurs du scénario
      _nameController.text = scenario.name;
      _descriptionController.text = scenario.description ?? '';
      _roundDurationController.text = scenario.roundDuration.toString();
      _bombTimerController.text = scenario.bombTimer.toString();
      _defuseTimeController.text = scenario.defuseTime.toString();
      _roundsToPlayController.text = scenario.roundsToPlay.toString();
      _activeSitesPerRoundController.text = scenario.activeSitesPerRound.toString();
      
      setState(() {
        _scenario = scenario;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement du scénario: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// Sauvegarde les modifications du scénario
  Future<void> _saveScenario() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final updatedScenario = BombOperationScenario(
        id: _scenario!.id,
        name: _nameController.text,
        description: _descriptionController.text,
        roundDuration: int.parse(_roundDurationController.text),
        bombTimer: int.parse(_bombTimerController.text),
        defuseTime: int.parse(_defuseTimeController.text),
        roundsToPlay: int.parse(_roundsToPlayController.text),
        activeSitesPerRound: int.parse(_activeSitesPerRoundController.text),
        active: _scenario!.active,
        bombSites: _scenario!.bombSites,
      );
      
      await _bombOperationService.updateBombOperationScenario(updatedScenario);
      
      // Met à jour le scénario principal si le nom a changé
      if (_nameController.text != widget.scenarioName) {
        final scenarioService = context.read<ScenarioService>();
        final mainScenario = await scenarioService.getScenarioDTOById(widget.scenarioId);
        if (mainScenario.scenario.name != _nameController.text) {
          // TODO: Mettre à jour le nom du scénario principal si nécessaire
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scénario sauvegardé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  /// Navigue vers l'écran de gestion des sites de bombe
  void _navigateToBombSites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BombSiteListScreen(
          scenarioId: widget.scenarioId,
          scenarioName: _nameController.text,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuration: ${widget.scenarioName}'),
        actions: [
          if (!_isLoading && !_isSaving)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveScenario,
              tooltip: 'Sauvegarder',
            ),
        ],
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
                    // Informations générales
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informations générales',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Configurez les informations de base du scénario Opération Bombe.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du scénario *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
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
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    
                    // Paramètres de jeu
                    const SizedBox(height: 24),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paramètres de jeu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Configurez les règles et paramètres du scénario Opération Bombe.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _roundDurationController,
                            decoration: const InputDecoration(
                              labelText: 'Durée d\'un round (secondes) *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.timer),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requis';
                              }
                              final duration = int.tryParse(value);
                              if (duration == null || duration < 30) {
                                return 'Min 30s';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _bombTimerController,
                            decoration: const InputDecoration(
                              labelText: 'Timer de la bombe (secondes) *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.alarm),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requis';
                              }
                              final timer = int.tryParse(value);
                              if (timer == null || timer < 10) {
                                return 'Min 10s';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _defuseTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Temps de désamorçage (secondes) *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.security),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requis';
                              }
                              final defuseTime = int.tryParse(value);
                              if (defuseTime == null || defuseTime < 3) {
                                return 'Min 3s';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _roundsToPlayController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de rounds *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.repeat),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requis';
                              }
                              final rounds = int.tryParse(value);
                              if (rounds == null || rounds < 1) {
                                return 'Min 1';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _activeSitesPerRoundController,
                      decoration: const InputDecoration(
                        labelText: 'Sites actifs par round *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.place),
                        helperText: 'Nombre de sites de bombe actifs aléatoirement par round',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requis';
                        }
                        final sites = int.tryParse(value);
                        if (sites == null || sites < 1) {
                          return 'Min 1';
                        }
                        return null;
                      },
                    ),
                    
                    // Sites de bombe
                    const SizedBox(height: 24),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sites de bombe',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Gérez les sites où les bombes peuvent être posées et désamorcées.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _navigateToBombSites,
                      icon: const Icon(Icons.map),
                      label: const Text('Gérer les sites de bombe'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueGrey,
                      ),
                    ),
                    
                    // Bouton de sauvegarde
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveScenario,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Sauvegarder les paramètres',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
