import 'package:airsoft_game_map/models/game_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/scenario/bomb_operation/bomb_site.dart';
import '../../../services/scenario/bomb_operation/bomb_operation_scenario_service.dart';
import 'dart:math';

/// Écran d'édition d'un site de bombe
class BombSiteEditScreen extends StatefulWidget {
  /// Identifiant du scénario
  final int scenarioId;
  final int bombOperationScenarioId;
  /// Site à éditer (null pour création)
  final BombSite? site;
  final List<BombSite> otherSites;
  final GameMap gameMap;

  /// Constructeur
  const BombSiteEditScreen({
    Key? key,
    required this.scenarioId,
    required this.bombOperationScenarioId,
    this.site,
    required this.gameMap,
    required this.otherSites,
  }) : super(key: key);

  @override
  State<BombSiteEditScreen> createState() => _BombSiteEditScreenState();
}

class _BombSiteEditScreenState extends State<BombSiteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late BombOperationScenarioService _bombOperationService;
  bool _isSaving = false;
  bool _satelliteView = false;
  // Contrôleurs pour les champs de formulaire
  final _nameController = TextEditingController();
  final _radiusController = TextEditingController();

  // Valeurs pour la carte
  LatLng _position = const LatLng(48.8566, 2.3522); // Paris par défaut
  double _zoom = 15.0;
  final MapController _mapController = MapController();
  String get _tileUrl => _satelliteView
      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  // Couleur du site
  Color _siteColor = Colors.red;
  final List<Color> _availableColors = [
    Colors.red,
    Colors.orange,
    Colors.amber,
  ];
  final String _emojiMarker = '💣';


  @override
  void initState() {
    super.initState();
    _bombOperationService = GetIt.I<BombOperationScenarioService>();
    _position = widget.site != null
        ? LatLng(widget.site!.latitude, widget.site!.longitude)
        : LatLng(widget.gameMap.centerLatitude!, widget.gameMap.centerLongitude!);
    _zoom = widget.gameMap.initialZoom ?? 15.0;
    // Initialise les valeurs si on édite un site existant
    if (widget.site != null) {
      _nameController.text = widget.site!.name;
      _radiusController.text = widget.site!.radius.toString();
      _position = LatLng(widget.site!.latitude, widget.site!.longitude);

      if (widget.site!.color != null && widget.site!.color!.isNotEmpty) {
        try {
          final colorValue = int.parse(widget.site!.color!.replaceAll('#', '0xFF'));
          _siteColor = Color(colorValue);
        } catch (e) {
          // Utilise la couleur par défaut
        }
      }
    } else {
      _nameController.text = 'Site ${String.fromCharCode(65 + DateTime.now().microsecond % 26)}'; // A, B, C, etc.
      _radiusController.text = '5.0';
    }

  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _radiusController.dispose();
    _mapController.dispose();
    super.dispose();
  }
  
  /// Sauvegarde le site de bombe
  Future<void> _saveSite() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final colorHex = '#${_siteColor.value.toRadixString(16).substring(2)}';
      print('📌 Valeurs avant instanciation du BombSite:');
      print('- id: ${widget.site?.id}');
      print('- scenarioId: ${widget.scenarioId}');
      print('- bombOperationScenarioId: ${widget.bombOperationScenarioId}');
      print('- name: ${_nameController.text}');
      print('- latitude: ${_position.latitude}');
      print('- longitude: ${_position.longitude}');
      print('- radius: ${_radiusController.text}');
      print('- color: $_siteColor');

      final site = BombSite(
        id: widget.site?.id,
        scenarioId: widget.scenarioId,
        bombOperationScenarioId: widget.bombOperationScenarioId,
        name: _nameController.text,
        latitude: _position.latitude,
        longitude: _position.longitude,
        radius: double.parse(_radiusController.text),
        color: colorHex,
      );
      
      if (widget.site == null) {
        print('[BombSiteEditScreen] Création d\'un nouveau site: ${site.toJson()}');
        await _bombOperationService.createBombSite(site);
      } else {
        print('[BombSiteEditScreen] Mise à jour du site existant: ${site.toJson()}');
        await _bombOperationService.updateBombSite(site);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Site sauvegardé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        print('[BombSiteEditScreen] Erreur lors de la sauvegarde du site: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
        Navigator.pop(context, true);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final distanceInMeters = double.tryParse(_radiusController.text) ?? 5.0;
    final zoom = _zoom;
    final metersPerPixel = 156543.03392 * cos(_position.latitude * pi / 180) / pow(2, zoom);
    final radiusInPixels = distanceInMeters / metersPerPixel;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.site == null ? 'Nouveau site' : 'Modifier le site'),
        actions: [
          if (!_isSaving)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSite,
              tooltip: 'Sauvegarder',
            ),
          IconButton(
            icon: Icon(_satelliteView ? Icons.map : Icons.satellite_alt),
            tooltip: _satelliteView ? 'Vue Standard' : 'Vue Satellite',
            onPressed: () {
              setState(() {
                _satelliteView = !_satelliteView;
              });
            },
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  // Carte pour sélectionner la position
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _position,
                            initialZoom: _zoom,
                            onTap: (tapPosition, point) {
                              setState(() {
                                _position = point;
                              });
                            },
                            onPositionChanged: (MapPosition pos, bool hasGesture) {
                              if (pos.zoom != null && pos.zoom != _zoom) {
                                setState(() {
                                  _zoom = pos.zoom!;
                                });
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: _tileUrl,
                              userAgentPackageName: 'com.airsoft.gamemapmaster',
                            ),
                            // ✅ Contours du terrain
                            if (widget.gameMap.fieldBoundary != null)
                              PolygonLayer(
                                polygons: [
                                  Polygon(
                                    points: widget.gameMap.fieldBoundary!
                                        .map((coord) => LatLng(coord.latitude, coord.longitude))
                                        .toList(),
                                    color: Colors.blue.withOpacity(0.3),
                                    borderColor: Colors.blue,
                                    borderStrokeWidth: 2.0,
                                  ),
                                ],
                              ),

                            // ✅ Zones
                            if (widget.gameMap.mapZones != null)
                              PolygonLayer(
                                polygons: widget.gameMap.mapZones!.map((zone) {
                                  final color = Color(int.parse(zone.color.replaceAll('#', '0xFF')));
                                  return Polygon(
                                    points: zone.coordinates
                                        .map((coord) => LatLng(coord.latitude, coord.longitude))
                                        .toList(),
                                    color: color.withOpacity(0.3),
                                    borderColor: color,
                                    borderStrokeWidth: 2.0,
                                  );
                                }).toList(),
                              ),

                            // ✅ POI visibles
                            if (widget.gameMap.mapPointsOfInterest != null)
                              MarkerLayer(
                                markers: widget.gameMap.mapPointsOfInterest!
                                    .where((poi) => poi.visible)
                                    .map((poi) => Marker(
                                  point: LatLng(poi.latitude, poi.longitude),
                                  width: 60,
                                  height: 60,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getPOIIcon(poi.iconIdentifier),
                                        color: Color(int.parse(poi.color.replaceAll('#', '0xFF'))),
                                        size: 32,
                                      ),
                                    ],
                                  ),
                                ))
                                    .toList(),
                              ),

                            // ✅ Cercle du site en édition
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _position,
                                  radius: radiusInPixels,
                                  color: _siteColor.withOpacity(0.3),
                                  borderColor: _siteColor,
                                  borderStrokeWidth: 2.0,
                                ),
                              ],
                            ),
                            // 🔘 Autres sites en lecture seule
                            if (widget.otherSites.isNotEmpty)
                              CircleLayer(
                                circles: widget.otherSites.map((site) {
                                  final grayColor = Colors.grey;
                                  return CircleMarker(
                                    point: LatLng(site.latitude, site.longitude),
                                    radius: radiusInPixels,
                                    color: grayColor.withOpacity(0.3),
                                    borderColor: grayColor,
                                    borderStrokeWidth: 1.5,
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: Column(
                            children: [
                              FloatingActionButton(
                                heroTag: 'zoom_in',
                                mini: true,
                                onPressed: () {
                                  _mapController.move(
                                    _position,
                                    _mapController.camera.zoom + 1,
                                  );
                                },
                                child: const Icon(Icons.add),
                              ),
                              const SizedBox(height: 8),
                              FloatingActionButton(
                                heroTag: 'zoom_out',
                                mini: true,
                                onPressed: () {
                                  _mapController.move(
                                    _position,
                                    _mapController.camera.zoom - 1,
                                  );
                                },
                                child: const Icon(Icons.remove),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: 16,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Appuyez sur la carte pour définir la position',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Formulaire pour les détails du site
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom du site *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.label),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un nom pour le site';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _radiusController,
                            decoration: const InputDecoration(
                              labelText: 'Rayon (mètres) *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.radio_button_checked),
                              helperText: 'Rayon de la zone où la bombe peut être posée/désamorcée',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un rayon';
                              }
                              final radius = double.tryParse(value);
                              if (radius == null || radius <= 0) {
                                return 'Rayon invalide';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                // Mise à jour du cercle sur la carte
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Couleur du site:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableColors.map((color) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _siteColor = color;
                                  });
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _siteColor == color
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      if (_siteColor == color)
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Position: ${_position.latitude.toStringAsFixed(6)}, ${_position.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _saveSite,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator()
                                : Text(
                                    widget.site == null
                                        ? 'Créer le site'
                                        : 'Mettre à jour le site',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

IconData _getPOIIcon(String identifier) {
  switch (identifier) {
    case 'danger':
      return Icons.dangerous;
    case 'info':
      return Icons.info;
    case 'location':
      return Icons.location_on;
    default:
      return Icons.help_outline;
  }
}
