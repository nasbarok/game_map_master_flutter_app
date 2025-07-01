import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final apiService = GetIt.I<ApiService>();
        
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
            SnackBar(
              content: Text(l10n.fieldSavedSuccess),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.error + e.toString()),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.field == null ? l10n.newFieldTitle : l10n.editFieldTitle),
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
                      decoration: InputDecoration(
                        labelText: l10n.fieldNameLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.fieldRequiredError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.fieldDescriptionLabel,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: l10n.fieldAddressLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            decoration: InputDecoration(
                              labelText: l10n.latitudeLabel,
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            decoration: InputDecoration(
                              labelText: l10n.longitudeLabel,
                              border: const OutlineInputBorder(),
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
                            decoration: InputDecoration(
                              labelText: l10n.widthLabel,
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _sizeYController,
                            decoration: InputDecoration(
                              labelText: l10n.lengthLabel,
                              border: const OutlineInputBorder(),
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
                        widget.field == null ? l10n.createFieldButton : l10n.updateFieldButton,
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
