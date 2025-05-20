import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../models/game_map.dart';
import '../../../models/scenario/bomb_operation/bomb_operation_scenario.dart';
import '../../../models/scenario/bomb_operation/bomb_site.dart';
import '../../../services/game_map_service.dart';
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
  late GameMapService _gameMapService;
  final fm.MapController _mapController = fm.MapController();

  BombOperationScenario? _scenario;
  GameMap? _gameMap;
  List<BombSite>? _bombSites;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingMap = true;
  bool _mapLoadError = false;

  // Contrôleurs pour les champs de formulaire
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bombTimerController = TextEditingController();
  final _defuseTimeController = TextEditingController();
  final _activeSitesPerRoundController = TextEditingController();
  
  // Options d'affichage de la carte
  bool _showZones = true;
  bool _showPointsOfInterest = true;

  @override
  void initState() {
    super.initState();
    _bombOperationService = GetIt.I<BombOperationScenarioService>();
    _gameMapService = GetIt.I<GameMapService>();
    _loadScenario();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _bombTimerController.dispose();
    _defuseTimeController.dispose();
    _activeSitesPerRoundController.dispose();
    _mapController.dispose();
    super.dispose();
  }
  
  /// Charge les données du scénario depuis le backend
  Future<void> _loadScenario() async {
    setState(() {
      _isLoading = true;
      _mapLoadError = false;
    });
    
    try {
      // Assure que le scénario BombOperation existe pour cet ID
      final scenario = await _bombOperationService.ensureBombOperationScenario(widget.scenarioId);
      
      // Initialise les contrôleurs avec les valeurs du scénario
      _nameController.text = scenario.name;
      _descriptionController.text = scenario.description ?? '';
      _bombTimerController.text = scenario.bombTimer.toString();
      _defuseTimeController.text = scenario.defuseTime.toString();
      _activeSitesPerRoundController.text = scenario.activeSitesPerRound.toString();
      
      // Récupère les options d'affichage
      _showZones = scenario.showZones;
      _showPointsOfInterest = scenario.showPointsOfInterest;

      // Récupère les sites de bombe
      final sites = await _bombOperationService.getBombSites(widget.scenarioId);

      // Récupère le scénario principal pour obtenir l'ID de la carte
      final scenarioService = context.read<ScenarioService>();
      final mainScenario = await scenarioService.getScenarioDTOById(widget.scenarioId);

      if (mainScenario.scenario.gameMapId != null) {
        // Charge la carte associée au scénario
        await _loadGameMap(mainScenario.scenario.gameMapId!);
      }

      setState(() {
        _scenario = scenario;
        _bombSites = sites;
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
  
  /// Charge la carte associée au scénario
  Future<void> _loadGameMap(int gameMapId) async {
    setState(() {
      _isLoadingMap = true;
      _mapLoadError = false;
    });

    try {
      final gameMap = await _gameMapService.getGameMapById(gameMapId);

      // Vérifier si la carte a une configuration interactive valide
      if (!gameMap.hasInteractiveMapConfig) {
        setState(() {
          _mapLoadError = true;
          _isLoadingMap = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cette carte n\'a pas de configuration interactive. Veuillez sélectionner une autre carte ou configurer celle-ci dans l\'éditeur de carte.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() {
        _gameMap = gameMap;
        _isLoadingMap = false;
      });

      // Centre la carte sur les coordonnées de la carte
      if (_gameMap?.centerLatitude != null && _gameMap?.centerLongitude != null) {
        _mapController.move(
          LatLng(_gameMap!.centerLatitude!, _gameMap!.centerLongitude!),
          _gameMap?.initialZoom ?? 15.0,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement de la carte: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoadingMap = false;
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
        bombTimer: int.parse(_bombTimerController.text),
        defuseTime: int.parse(_defuseTimeController.text),
        activeSitesPerRound: int.parse(_activeSitesPerRoundController.text),
        active: _scenario!.active,
        bombSites: _scenario!.bombSites,
        showZones: _showZones,
        showPointsOfInterest: _showPointsOfInterest,
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
  /// Retourne l'icône associée à un identifiant donné pour un POI
  IconData _getIconDataFromIdentifier(String iconIdentifier) {
    switch (iconIdentifier) {
      case 'location':
        return Icons.location_on;
      case 'danger':
        return Icons.dangerous;
      case 'info':
        return Icons.info;
    // Ajoutez d'autres identifiants et icônes selon vos besoins
      default:
        return Icons.help_outline; // Icône par défaut si l'identifiant est inconnu
    }
  }
  /// Construit la carte interactive
  Widget _buildMap() {
    if (_gameMap == null) {
      return const Center(child: Text('Aucune carte disponible'));
    }

    return fm.FlutterMap(
      mapController: _mapController,
      options: fm.MapOptions(
        center: LatLng(_gameMap!.centerLatitude!, _gameMap!.centerLongitude!),
        zoom: _gameMap!.initialZoom ?? 15.0,
        maxZoom: 20.0,
        minZoom: 3.0,
      ),
      children: [
        fm.TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),

        // Limites du terrain (toujours affichées)
        if (_gameMap!.fieldBoundary != null)
          fm.PolygonLayer(
            polygons: [
              fm.Polygon(
                points: _gameMap!.fieldBoundary!
                    .map((coord) => LatLng(coord.latitude, coord.longitude))
                    .toList(),
                color: Colors.blue.withOpacity(0.3),
                borderColor: Colors.blue,
                borderStrokeWidth: 3.0,
              ),
            ],
          ),

        // Zones (conditionnellement affichées)
        if (_showZones && _gameMap!.mapZones != null)
          fm.PolygonLayer(
            polygons: _gameMap!.mapZones!.map((zone) {
              final color = Color(int.parse(zone.color.replaceAll('#', '0xFF')));
              return fm.Polygon(
                points: zone.coordinates
                    .map((coord) => LatLng(coord.latitude, coord.longitude))
                    .toList(),
                color: color.withOpacity(0.3),
                borderColor: color,
                borderStrokeWidth: 2.0,
              );
            }).toList(),
          ),

        // Points d'intérêt (conditionnellement affichés)
        if (_showPointsOfInterest && _gameMap!.mapPointsOfInterest != null)
          fm.MarkerLayer(
            markers: _gameMap!.mapPointsOfInterest!.where((poi) => poi.visible).map((poi) {
              return fm.Marker(
                width: 80.0, // Largeur de l'icône
                height: 80.0, // Hauteur de l'icône
                point: LatLng(poi.latitude, poi.longitude),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getIconDataFromIdentifier(poi.iconIdentifier), // Icone dynamique selon le POI
                      color: Color(int.parse(poi.color.replaceAll('#', '0xFF'))), // Couleur dynamique
                      size: 40, // Taille de l'icône
                    ),
                    // Vous pouvez ajouter plus de widgets ici si nécessaire, comme des labels ou des infos supplémentaires
                  ],
                ),
              );
            }).toList(),
          ),

        // Sites de bombe
        if (_bombSites != null)
          fm.MarkerLayer(
            markers: _bombSites!.map((site) {
              return fm.Marker(
                point: LatLng(site.latitude, site.longitude),
                width: 80.0, // Largeur de l'icône
                height: 80.0, // Hauteur de l'icône
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.dangerous, // Icône de danger pour les sites de bombe
                      color: Colors.red,
                      size: 50, // Taille de l'icône
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

      ],
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
                    
                    // Carte interactive
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Carte du terrain',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Visualisez la carte du terrain et les sites de bombe.',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),

                            // Options d'affichage
                            Row(
                              children: [
                                Expanded(
                                  child: SwitchListTile(
                                    title: const Text('Afficher les zones'),
                                    value: _showZones,
                                    onChanged: (value) {
                                      setState(() {
                                        _showZones = value;
                                      });
                                    },
                                    dense: true,
                                  ),
                                ),
                                Expanded(
                                  child: SwitchListTile(
                                    title: const Text('Afficher les POI'),
                                    value: _showPointsOfInterest,
                                    onChanged: (value) {
                                      setState(() {
                                        _showPointsOfInterest = value;
                                      });
                                    },
                                    dense: true,
                                  ),
                                ),
                              ],
                            ),

                            // Carte
                            const SizedBox(height: 8),
                            Container(
                              height: 300,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _isLoadingMap || _gameMap == null
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 16),
                                          Text('Chargement de la carte...'),
                                        ],
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _buildMap(),
                                    ),
                            ),
                          ],
                        ),
                      ),
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
                        const SizedBox(width: 16),
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

  /// Construit la carte interactive
  /*Widget _buildMap() {
    if (_gameMap == null) {
      return const Center(child: Text('Aucune carte disponible'));
    }

    return fm.FlutterMap(
      mapController: _mapController,
      options: fm.MapOptions(
        initialCenter: LatLng(
          _gameMap!.centerLatitude ?? 48.8566,
          _gameMap!.centerLongitude ?? 2.3522,
        ),
        initialZoom: _gameMap!.initialZoom ?? 15.0,
        interactionOptions: const fm.InteractionOptions(
          flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
        ),
      ),
      children: [
        // Fond de carte OpenStreetMap
        fm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.airsoft.gamemapmaster',
        ),

        // Limites du terrain (toujours affichées)
        if (_gameMap!.fieldBoundary != null)
          fm.PolygonLayer(
            polygons: [
              fm.Polygon(
                points: _gameMap!.fieldBoundary!
                    .map((coord) => LatLng(coord.latitude, coord.longitude))
                    .toList(),
                color: Colors.blue.withOpacity(0.2),
                borderColor: Colors.blue,
                borderStrokeWidth: 2.0,
              ),
            ],
          ),

        // Zones (affichées selon l'option)
        if (_showZones && _gameMap!.mapZones != null)
          fm.PolygonLayer(
            polygons: _gameMap!.mapZones!.map((zone) {
              // Convertit la couleur hexadécimale en Color
              Color zoneColor;
              try {
                zoneColor = Color(int.parse(zone.color.replaceAll('#', '0xFF')));
              } catch (e) {
                zoneColor = Colors.red; // Couleur par défaut
              }

              return fm.Polygon(
                points: zone.coordinates
                    .map((coord) => LatLng(coord.latitude, coord.longitude))
                    .toList(),
                color: zoneColor.withOpacity(0.3),
                borderColor: zoneColor,
                borderStrokeWidth: 2.0,
                label: zone.name,
              );
            }).toList(),
          ),

        // Points d'intérêt (affichés selon l'option)
        if (_showPointsOfInterest && _gameMap!.mapPointsOfInterest != null)
          fm.MarkerLayer(
            markers: _gameMap!.mapPointsOfInterest!.map((poi) {
              // Convertit la couleur hexadécimale en Color
              Color poiColor;
              try {
                poiColor = Color(int.parse(poi.color.replaceAll('#', '0xFF')));
              } catch (e) {
                poiColor = Colors.red; // Couleur par défaut
              }

              return fm.Marker(
                point: LatLng(poi.latitude, poi.longitude),
                width: 30,
                height: 30,
                child: Tooltip(
                  message: poi.name,
                  child: Icon(
                    Icons.location_on,
                    color: poiColor,
                    size: 30,
                  ),
                ),
              );
            }).toList(),
          ),

        // Sites de bombe
        if (_bombSites != null)
          fm.MarkerLayer(
            markers: _bombSites!.map((site) {
              // Convertit la couleur hexadécimale en Color
              Color siteColor;
              try {
                siteColor = Color(int.parse(site.color?.replaceAll('#', '0xFF') ?? '0xFFFF0000'));
              } catch (e) {
                siteColor = Colors.red; // Couleur par défaut
              }

              return fm.Marker(
                point: LatLng(site.latitude, site.longitude),
                width: 40,
                height: 40,
                child: Tooltip(
                  message: site.name,
                  child: Stack(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: siteColor,
                        size: 40,
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Icon(
                              Icons.warning,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }*/
}
