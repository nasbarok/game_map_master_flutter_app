import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
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

  List<Map<String, dynamic>> _getColorOptions(AppLocalizations l10n) {
    return [
      {'name': l10n.colorRed, 'value': '#FF0000'},
      {'name': l10n.colorBlue, 'value': '#0000FF'},
      {'name': l10n.colorGreen, 'value': '#00FF00'},
      {'name': l10n.colorYellow, 'value': '#FFFF00'},
      {'name': l10n.colorOrange, 'value': '#FFA500'},
      {'name': l10n.colorPurple, 'value': '#800080'},
      {'name': l10n.colorBlack, 'value': '#000000'},
      {'name': l10n.colorWhite, 'value': '#FFFFFF'},
    ];
  }

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
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final apiService = GetIt.I<ApiService>();

        final team = Team(
          id: widget.team!.id,
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
            SnackBar(
              content: Text(l10n.teamSavedSuccess),
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
    final colorOptions = _getColorOptions(l10n);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team == null ? l10n.newTeamScreenTitle : l10n.editTeamTitle),
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
                        labelText: l10n.teamName,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.teamNameRequiredError;
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
                    DropdownButtonFormField<String>(
                      value: _selectedColor,
                      decoration: InputDecoration(
                        labelText: l10n.teamColorLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: colorOptions.map((color) {
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
                        widget.team == null ? l10n.createTeam : l10n.updateTeamButton,
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
