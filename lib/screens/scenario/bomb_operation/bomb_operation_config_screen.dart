import 'package:game_map_master_flutter_app/models/scenario.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../models/coordinate.dart';
import '../../../models/game_map.dart';
import '../../../models/scenario/bomb_operation/bomb_operation_scenario.dart';
import '../../../models/scenario/bomb_operation/bomb_site.dart';
import '../../../services/auth_service.dart';
import '../../../services/game_map_service.dart';
import '../../../services/scenario/bomb_operation/bomb_operation_scenario_service.dart';
import '../../../services/scenario_service.dart';
import '../../../utils/app_utils.dart';
import '../../../widgets/adaptive_background.dart';
import 'bomb_site_list_screen.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

/// Écran de configuration d'un scénario Opération Bombe
class BombOperationConfigScreen extends StatefulWidget {
  /// Identifiant du scénario
  final int scenarioId;
  final int gameMapId;

  /// Nom du scénario
  final String scenarioName;

  /// Constructeur
  const BombOperationConfigScreen({
    Key? key,
    required this.scenarioId,
    required this.scenarioName,
    required this.gameMapId,
  }) : super(key: key);

  @override
  State<BombOperationConfigScreen> createState() =>
      _BombOperationConfigScreenState();
}

class _BombOperationConfigScreenState extends State<BombOperationConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  late BombOperationScenarioService _bombOperationService;
  late GameMapService _gameMapService;
  late ScenarioService _scenarioService;

  late final fm.MapController _mapController;

  BombOperationScenario? _scenarioBombOperation;
  late GameMap _gameMap;
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
  final _armingTimeController = TextEditingController();
  final _activeSitesPerRoundController = TextEditingController();

  // Options d'affichage de la carte
  bool _showZones = true;
  bool _showPointsOfInterest = true;
  bool _didLoadScenario = false; // Pour éviter plusieurs chargements

  @override
  void initState() {
    super.initState();
    _bombOperationService = GetIt.I<BombOperationScenarioService>();
    _gameMapService = GetIt.I<GameMapService>();
    _scenarioService = GetIt.I<ScenarioService>();
    _mapController = fm.MapController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadScenario) {
      _didLoadScenario = true;
      _loadScenario(); // On appelle ici, contexte garanti prêt
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _bombTimerController.dispose();
    _defuseTimeController.dispose();
    _armingTimeController.dispose();
    _activeSitesPerRoundController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Charge les données du scénario depuis le backend
  Future<void> _loadScenario() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _mapLoadError = false;
    });

    try {
      // Assure que le scénario BombOperation existe pour cet ID
      final scenarioBombOperation = await _bombOperationService
          .ensureBombOperationScenario(widget.scenarioId);
      var scenario;
      if (scenarioBombOperation.scenarioId != null) {
        scenario = await _scenarioService
            .getScenarioDTOById(scenarioBombOperation.scenarioId!);
        _nameController.text = scenario.scenario.name;
        _descriptionController.text = scenario.scenario.description ?? '';
      } else {
        logger.d(
            '❌ [BombOperationConfigScreen] scenarioId null dans scenarioBombOperation');
      }
      // Initialise les contrôleurs avec les valeurs du scénario
      _nameController.text = scenario.scenario.name;
      _descriptionController.text = scenario.scenario.description ?? '';
      _bombTimerController.text = scenarioBombOperation.bombTimer.toString();
      _defuseTimeController.text = scenarioBombOperation.defuseTime.toString();
      _armingTimeController.text = scenarioBombOperation.armingTime.toString();

      _activeSitesPerRoundController.text =
          scenarioBombOperation.activeSites.toString();

      // Récupère les options d'affichage
      _showZones = scenarioBombOperation.showZones;
      _showPointsOfInterest = scenarioBombOperation.showPointsOfInterest;

      // Récupère les sites de bombe
      final sites =
          await _bombOperationService.getBombSites(scenarioBombOperation.id!);
      logger.d('📦 [_loadScenario] Sites récupérés depuis backend :');
      for (var site in sites) {
        logger.d(
            '   🔸 ${site.name} - (${site.latitude}, ${site.longitude}) - Rayon: ${site.radius}m');
      }
      // Récupère le scénario principal pour obtenir l'ID de la carte
      final scenarioService = context.read<ScenarioService>();
      final mainScenario =
          await scenarioService.getScenarioDTOById(widget.scenarioId);

      if (widget.gameMapId != null) {
        // Charge la carte associée au scénario
        await _loadGameMap(widget.gameMapId!);
      } else {
        logger.d(
            '❌ [BombOperationConfigScreen] [_loadScenario] Aucune carte associée au scénario principal');
      }

      setState(() {
        _bombSites?.clear();
        _scenarioBombOperation = scenarioBombOperation;
        _bombSites = sites;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        // Affiche un message d'erreur si le chargement échoue
        logger.d(
            '[BombOperationConfigScreen] ${l10n.errorLoadingData(e.toString())}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLoadingData(e.toString())),
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
    final l10n = AppLocalizations.of(context)!;
    logger.d(
        '📡 [BombOperationConfigScreen] [_loadGameMap] Chargement gameMapId=$gameMapId');
    setState(() {
      _isLoadingMap = true;
      _mapLoadError = false;
    });

    try {
      final gameMap = await _gameMapService.getGameMapById(gameMapId);
      logger.d(
          '✅ [BombOperationConfigScreen] [_loadGameMap] Reçu: ${gameMap.name}, interactive: ${gameMap.hasInteractiveMapConfig}');
      logger.d(
          '🎯 [BombOperationConfigScreen] [_loadGameMap] gameMap JSON brut: ${gameMap.toJson()}');

      // Vérifier si la carte a une configuration interactive valide
      if (!gameMap.hasInteractiveMapConfig) {
        logger.d(
            '⚠️ [BombOperationConfigScreen] [_loadGameMap] Carte non interactive, affichage bloqué');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.interactiveMapRequiredError),
              backgroundColor: Colors.orange,
            ),
          );
        }

        setState(() {
          _mapLoadError = true;
          _isLoadingMap = false;
        });

        return;
      }

      setState(() {
        _gameMap = gameMap;
        _isLoadingMap = false;
      });
      logger.d(
          '🗺️ [BombOperationConfigScreen] [_loadGameMap] Affichage carte préparé');

      // Centre la carte sur les coordonnées de la carte
      if (_gameMap.centerLatitude != null && _gameMap.centerLongitude != null) {
        logger.d(
            '📍 [BombOperationConfigScreen] [_loadGameMap] Centre: ${_gameMap!.centerLatitude}, ${_gameMap!.centerLongitude}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(
            LatLng(_gameMap.centerLatitude!, _gameMap.centerLongitude!),
            _gameMap.initialZoom ?? 15.0,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        logger.d(
            '❌ [BombOperationConfigScreen] [_loadGameMap] Erreur lors du chargement de la carte: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLoadingData(e.toString())),
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
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedScenarioBombOperation = BombOperationScenario(
        id: _scenarioBombOperation!.id,
        bombTimer: int.parse(_bombTimerController.text),
        defuseTime: int.parse(_defuseTimeController.text),
        armingTime: int.parse(_armingTimeController.text),
        activeSites: int.parse(_activeSitesPerRoundController.text),
        attackTeamName: _scenarioBombOperation!.attackTeamName,
        defenseTeamName: _scenarioBombOperation!.defenseTeamName,
        scenarioId: widget.scenarioId,
        bombSites: _scenarioBombOperation!.bombSites,
        showZones: _showZones,
        showPointsOfInterest: _showPointsOfInterest,
      );

      final scenarioService = context.read<ScenarioService>();
      final authService = GetIt.I<AuthService>();
      final updatedScenario = Scenario(
        id: widget.scenarioId,
        name: _nameController.text,
        description: _descriptionController.text,
        gameMapId: _gameMap?.id,
        type: 'bomb_operation',
        active: true,
        creator: authService.currentUser,
      );
      scenarioService.updateScenario(updatedScenario);

      await _bombOperationService
          .updateBombOperationScenario(updatedScenarioBombOperation);

      // Met à jour le scénario principal si le nom a changé
      if (_nameController.text != widget.scenarioName) {
        final scenarioService = context.read<ScenarioService>();
        final mainScenario =
            await scenarioService.getScenarioDTOById(widget.scenarioId);
        if (mainScenario.scenario.name != _nameController.text) {
          // TODO: Mettre à jour le nom du scénario principal si nécessaire
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.scenarioSavedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        logger.d(l10n.errorSavingScenario(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorSavingScenario(e.toString())),
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
  Future<void> _navigateToBombSites() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BombSiteListScreen(
          scenarioId: widget.scenarioId,
          bombOperationScenarioId: _scenarioBombOperation?.id ?? 0,
          scenarioName: _nameController.text,
          gampMap: _gameMap,
          gameMap: _gameMap,
        ),
      ),
    );

    // ✅ Recharge les bomb sites si on revient avec un changement
    if (result == true) {
      final sites =
          await _bombOperationService.getBombSites(_scenarioBombOperation!.id!);

      logger.d(
          '🔄 [BombOperationConfigScreen] Mise à jour des sites après retour depuis BombSiteListScreen :');
      for (var site in sites) {
        logger.d(
            '   ✅ ${site.name} - (${site.latitude}, ${site.longitude}) - Rayon: ${site.radius}m');
      }

      setState(() {
        _bombSites?.clear();
        _bombSites = sites;
      });
    }
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
        return Icons
            .help_outline; // Icône par défaut si l'identifiant est inconnu
    }
  }

  /// Construit la carte interactive
  Widget _buildMap() {
    if (_gameMap == null) {
      return const Center(child: Text('Aucune carte disponible'));
    }
    logger.d(
        '🗺️ [BombOperationConfigScreen] [_buildMap] Affichage de la carte avec ${_bombSites?.length ?? 0} sites.');

    final List<Coordinate>? fieldBoundaryCoords = _gameMap.fieldBoundary;
    if (fieldBoundaryCoords == null) {
      logger.w(
          '[BombOperationConfigScreen] fieldBoundaryCoords est null : aucun polygone affiché.');
    } else if (fieldBoundaryCoords.isEmpty) {
      logger.w(
          '[BombOperationConfigScreen] fieldBoundaryCoords vide : polygone non dessiné.');
    }
    logger.d(
        '[BombOperationConfigScreen] Zones disponibles: ${_gameMap.mapZones?.length}');
    _gameMap.mapZones?.forEach((z) {
      logger.d('🔍 Zone "${z.name}" → coordinates: ${z.coordinates}');
    });
    return fm.FlutterMap(
      mapController: _mapController,
      options: fm.MapOptions(
        center: LatLng(_gameMap!.centerLatitude!, _gameMap!.centerLongitude!),
        zoom: _gameMap.initialZoom ?? 15.0,
        maxZoom: 20.0,
        minZoom: 3.0,
      ),
      children: [
        fm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.airsoft.gamemapmaster',
        ),
        // Limites du terrain (toujours affichées)
        if (fieldBoundaryCoords != null)
          fm.PolygonLayer(
            polygons: [
              fm.Polygon(
                points: fieldBoundaryCoords
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
            polygons: _gameMap!.mapZones!
                .where((zone) => zone.coordinates != null) // ← AJOUT ici
                .map((zone) {
              final color =
                  Color(int.parse(zone.color.replaceAll('#', '0xFF')));
              return fm.Polygon(
                points: zone.coordinates!
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
            markers: _gameMap!.mapPointsOfInterest!
                .where((poi) => poi.visible)
                .map((poi) {
              return fm.Marker(
                width: 80.0, // Largeur de l'icône
                height: 80.0, // Hauteur de l'icône
                point: LatLng(poi.latitude, poi.longitude),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getIconDataFromIdentifier(poi.iconIdentifier),
                      // Icone dynamique selon le POI
                      color: AppUtils.parsePoiColor(poi.color), // Couleur dynamique
                      size: 40, // Taille de l'icône
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

        // Sites de bombe
        if (_bombSites != null)
          fm.MarkerLayer(
            key: UniqueKey(),
            // ✅ force la reconstruction dès qu’un site est ajouté/supprimé
            markers: _bombSites!.map((site) {
              return fm.Marker(
                point: LatLng(site.latitude, site.longitude),
                width: 80.0,
                height: 80.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.dangerous,
                      color: Colors.red,
                      size: 50,
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
    final l10n = AppLocalizations.of(context)!;
    return AdaptiveScaffold(
      gameBackgroundType: GameBackgroundType.menu,
      backgroundOpacity: 0.9,
      appBar: AppBar(
        title: Text(l10n.bombConfigScreenTitle(widget.scenarioName)),
        actions:  [
          if (!_isLoading && !_isSaving)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveScenario,
              tooltip: l10n.save,
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
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.generalInformationLabel,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.bombConfigGeneralInfoSubtitle,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.scenarioName,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.label),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.scenarioNameRequiredError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.scenarioDescription,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 5,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(500), // bloque au-delà de 500 caractères
                      ],
                    ),

                    // Carte interactive
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.fieldMapLabel,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.fieldMapSubtitle,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),

                            // Options d'affichage
                            Row(
                              children: [
                                Expanded(
                                  child: SwitchListTile(
                                    title: Text(l10n.showZonesLabel),
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
                                    title: Text(l10n.showPOIsLabel),
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
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const CircularProgressIndicator(),
                                          const SizedBox(height: 16),
                                          Text(l10n.loadingMap),
                                        ],
                                      ),
                                    )
                                  : _mapLoadError
                                      ? Center(child: Text(l10n.interactiveMapRequiredError, textAlign: TextAlign.center, style: TextStyle(color: Colors.red)))
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
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.gameSettingsLabel,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.bombConfigSettingsSubtitle,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _bombTimerController,
                      decoration: InputDecoration(
                        labelText: l10n.bombTimerLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.alarm),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.valueRequiredError;
                        }
                        final timer = int.tryParse(value);
                        if (timer == null || timer < 10) {
                          return l10n.minSecondsError("10");
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _defuseTimeController,
                      decoration: InputDecoration(
                        labelText: l10n.defuseTimeLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.security),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.valueRequiredError;
                        }
                        final defuseTime = int.tryParse(value);
                        if (defuseTime == null || defuseTime < 3) {
                          return l10n.minSecondsError("3");
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _armingTimeController,
                      decoration: InputDecoration(
                        labelText: l10n.armingTimeLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.timer),
                        helperText: l10n.armingTimeHelperText,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.valueRequiredError;
                        }
                        final time = int.tryParse(value);
                        if (time == null || time < 3) {
                          return l10n.minSecondsError("3");
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _activeSitesPerRoundController,
                      decoration: InputDecoration(
                        labelText: l10n.activeSitesPerRoundLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.place),
                        helperText: l10n.activeSitesHelperText,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.valueRequiredError;
                        }
                        final sites = int.tryParse(value);
                        if (sites == null || sites < 1) {
                          return l10n.minCountError("1");
                        }
                        return null;
                      },
                    ),

                    // Sites de bombe
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.bombSitesSectionTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.bombSitesSectionSubtitle,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _navigateToBombSites,
                      icon: const Icon(Icons.map),
                      label: Text(l10n.manageBombSitesButton),
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
                          : Text(
                              l10n.saveSettingsButton,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
