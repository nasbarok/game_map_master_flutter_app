import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/field.dart';
import '../../services/api_service.dart';

class FieldFormScreen extends StatefulWidget {
  final Field? field;
  
  const FieldFormScreen({Key? key, this.field}) : super(key: key);

  @override
  State<FieldFormScreen> createState() => _FieldFormScreenState();
}

class _FieldFormScreenState extends State<FieldFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _sizeXController = TextEditingController();
  final _sizeYController = TextEditingController();
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.field != null) {
      _nameController.text = widget.field!.name;
      _descriptionController.text = widget.field!.description ?? '';
      _addressController.text = widget.field!.address ?? '';
      _latitudeController.text = widget.field!.latitude?.toString() ?? '';
      _longitudeController.text = widget.field!.longitude?.toString() ?? '';
      _sizeXController.text = widget.field!.sizeX?.toString() ?? '';
      _sizeYController.text = widget.field!.sizeY?.toString() ?? '';
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _sizeXController.dispose();
    _sizeYController.dispose();
    super.dispose();
  }
  
  Future<void> _saveField() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        
        final field = Field(
          id: widget.field?.id,
          name: _nameController.text,
          description: _descriptionController.text,
          address: _addressController.text,
          latitude: _latitudeController.text.isNotEmpty ? double.parse(_latitudeController.text) : null,
          longitude: _longitudeController.text.isNotEmpty ? double.parse(_longitudeController.text) : null,
          sizeX: _sizeXController.text.isNotEmpty ? double.parse(_sizeXController.text) : null,
          sizeY: _sizeYController.text.isNotEmpty ? double.parse(_sizeYController.text) : null,
        );
        
        if (widget.field == null) {
          // Créer un nouveau terrain
          await apiService.post('fields', field.toJson());
        } else {
          // Mettre à jour un terrain existant
          await apiService.put('fields/${widget.field!.id}', field.toJson());
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terrain sauvegardé avec succès'),
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
        title: Text(widget.field == null ? 'Nouveau terrain' : 'Modifier le terrain'),
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
                        labelText: 'Nom du terrain *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom pour le terrain';
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
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sizeXController,
                            decoration: const InputDecoration(
                              labelText: 'Largeur (m)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _sizeYController,
                            decoration: const InputDecoration(
                              labelText: 'Longueur (m)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveField,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.field == null ? 'Créer le terrain' : 'Mettre à jour le terrain',
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
