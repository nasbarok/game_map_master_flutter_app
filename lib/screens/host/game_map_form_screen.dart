import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../models/game_map.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class GameMapFormScreen extends StatefulWidget {
  final GameMap? gameMap;
  
  const GameMapFormScreen({Key? key, this.gameMap}) : super(key: key);

  @override
  State<GameMapFormScreen> createState() => _GameMapFormScreenState();
}

class _GameMapFormScreenState extends State<GameMapFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scaleController = TextEditingController();
  int? _selectedFieldId;
  List<dynamic> _availableFields = [];
  
  bool _isLoading = false;
  bool _isLoadingFields = true;
  
  @override
  void initState() {
    super.initState();
    if (widget.gameMap != null) {
      _nameController.text = widget.gameMap!.name;
      _descriptionController.text = widget.gameMap!.description ?? '';
      _scaleController.text = widget.gameMap!.scale?.toString() ?? '1.0';
      _selectedFieldId = widget.gameMap!.fieldId;
    }
    
    _loadFields();
  }
  
  Future<void> _loadFields() async {
    setState(() {
      _isLoadingFields = true;
    });
    
    try {
      final apiService = GetIt.I<ApiService>();
     final authService = GetIt.I<AuthService>();
      final userId = authService.currentUser?.id;

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final fieldsData = await apiService.get('fields/owner/self');
      
      setState(() {
        _availableFields = fieldsData;
        
        if (widget.gameMap != null) {
          _selectedFieldId = widget.gameMap!.fieldId;
        } else if (_availableFields.isNotEmpty) {
          _selectedFieldId = _availableFields.first['id'];
        }
        
        _isLoadingFields = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFields = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des terrains: ${e.toString()}'),
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
    _scaleController.dispose();
    super.dispose();
  }
  
  Future<void> _saveGameMap() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedFieldId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un terrain'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        final apiService = GetIt.I<ApiService>();
        
        final gameMap = GameMap(
          id: widget.gameMap?.id,
          name: _nameController.text,
          description: _descriptionController.text,
          fieldId: _selectedFieldId!,
          scale: double.tryParse(_scaleController.text) ?? 1.0,
        );
        
        if (widget.gameMap == null) {
          // Créer une nouvelle carte
          await apiService.post('maps', gameMap.toJson());
        } else {
          // Mettre à jour une carte existante
          await apiService.put('maps/${widget.gameMap!.id}', gameMap.toJson());
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Carte sauvegardée avec succès'),
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
        title: Text(widget.gameMap == null ? 'Nouvelle carte' : 'Modifier la carte'),
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
                        labelText: 'Nom de la carte *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom pour la carte';
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
                    _isLoadingFields
                        ? const Center(child: CircularProgressIndicator())
                        : _availableFields.isEmpty
                            ? const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Aucun terrain disponible. Veuillez d\'abord créer un terrain.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              )
                            : DropdownButtonFormField<int>(
                                value: _selectedFieldId,
                                decoration: const InputDecoration(
                                  labelText: 'Terrain *',
                                  border: OutlineInputBorder(),
                                ),
                                items: _availableFields.map((field) {
                                  return DropdownMenuItem<int>(
                                    value: field['id'],
                                    child: Text(field['name']),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedFieldId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Veuillez sélectionner un terrain';
                                  }
                                  return null;
                                },
                              ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _scaleController,
                      decoration: const InputDecoration(
                        labelText: 'Échelle (m/pixel)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final scale = double.tryParse(value);
                          if (scale == null || scale <= 0) {
                            return 'Veuillez entrer une échelle valide';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _availableFields.isEmpty ? null : _saveGameMap,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.gameMap == null ? 'Créer la carte' : 'Mettre à jour la carte',
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
