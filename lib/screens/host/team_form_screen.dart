import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team.dart';
import '../../services/api_service.dart';

class TeamFormScreen extends StatefulWidget {
  final Team? team;
  
  const TeamFormScreen({Key? key, this.team}) : super(key: key);

  @override
  State<TeamFormScreen> createState() => _TeamFormScreenState();
}

class _TeamFormScreenState extends State<TeamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedColor;
  
  bool _isLoading = false;
  
  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Rouge', 'value': '#FF0000'},
    {'name': 'Bleu', 'value': '#0000FF'},
    {'name': 'Vert', 'value': '#00FF00'},
    {'name': 'Jaune', 'value': '#FFFF00'},
    {'name': 'Orange', 'value': '#FFA500'},
    {'name': 'Violet', 'value': '#800080'},
    {'name': 'Noir', 'value': '#000000'},
    {'name': 'Blanc', 'value': '#FFFFFF'},
  ];
  
  @override
  void initState() {
    super.initState();
    if (widget.team != null) {
      _nameController.text = widget.team!.name;
      _descriptionController.text = widget.team!.description ?? '';
      _selectedColor = widget.team!.color;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _saveTeam() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        
        final team = Team(
          id: widget.team?.id,
          name: _nameController.text,
          description: _descriptionController.text,
          color: _selectedColor,
        );
        
        if (widget.team == null) {
          // Créer une nouvelle équipe
          await apiService.post('teams', team.toJson());
        } else {
          // Mettre à jour une équipe existante
          await apiService.put('teams/${widget.team!.id}', team.toJson());
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Équipe sauvegardée avec succès'),
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
        title: Text(widget.team == null ? 'Nouvelle équipe' : 'Modifier l\'équipe'),
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
                        labelText: 'Nom de l\'équipe *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom pour l\'équipe';
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
                      value: _selectedColor,
                      decoration: const InputDecoration(
                        labelText: 'Couleur de l\'équipe',
                        border: OutlineInputBorder(),
                      ),
                      items: _colorOptions.map((color) {
                        return DropdownMenuItem<String>(
                          value: color['value'],
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _hexToColor(color['value']),
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(color['name']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedColor = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveTeam,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.team == null ? 'Créer l\'équipe' : 'Mettre à jour l\'équipe',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
