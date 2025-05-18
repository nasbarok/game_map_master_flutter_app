import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/scenario/bomb_operation/bomb_site.dart';
import '../../../services/scenario/bomb_operation/bomb_operation_scenario_service.dart';

/// Écran d'édition d'un site de bombe
class BombSiteEditScreen extends StatefulWidget {
  /// Identifiant du scénario
  final int scenarioId;
  
  /// Site à éditer (null pour création)
  final BombSite? site;

  /// Constructeur
  const BombSiteEditScreen({
    Key? key,
    required this.scenarioId,
    this.site,
  }) : super(key: key);

  @override
  State<BombSiteEditScreen> createState() => _BombSiteEditScreenState();
}

class _BombSiteEditScreenState extends State<BombSiteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late BombOperationScenarioService _bombOperationService;
  bool _isSaving = false;
  
  // Contrôleurs pour les champs de formulaire
  final _nameController = TextEditingController();
  final _radiusController = TextEditingController();
  
  // Valeurs pour la carte
  LatLng _position = const LatLng(48.8566, 2.3522); // Paris par défaut
  double _zoom = 15.0;
  final MapController _mapController = MapController();
  
  // Couleur du site
  Color _siteColor = Colors.red;
  final List<Color> _availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
  ];
  
  @override
  void initState() {
    super.initState();
    _bombOperationService = GetIt.I<BombOperationScenarioService>();
    
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
      _radiusController.text = '10.0';
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
      
      final site = BombSite(
        id: widget.site?.id,
        scenarioId: widget.scenarioId,
        name: _nameController.text,
        latitude: _position.latitude,
        longitude: _position.longitude,
        radius: double.parse(_radiusController.text),
        color: colorHex,
      );
      
      if (widget.site == null) {
        await _bombOperationService.createBombSite(site);
      } else {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
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
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.airsoft.gamemapmaster',
                            ),
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _position,
                                  radius: double.tryParse(_radiusController.text) ?? 10.0,
                                  color: _siteColor.withOpacity(0.3),
                                  borderColor: _siteColor,
                                  borderStrokeWidth: 2.0,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _position,
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.location_on,
                                    color: _siteColor,
                                    size: 40,
                                  ),
                                ),
                              ],
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
