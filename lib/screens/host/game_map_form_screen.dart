import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../models/game_map.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_map_service.dart';

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

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.gameMap != null) {
      _nameController.text = widget.gameMap!.name;
      _descriptionController.text = widget.gameMap!.description ?? '';
      _scaleController.text = widget.gameMap!.scale?.toString() ?? '1.0';
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
      setState(() {
        _isLoading = true;
      });

      try {
        final gameMap = GameMap(
          id: widget.gameMap?.id,
          name: _nameController.text,
          description: _descriptionController.text,
          scale: double.tryParse(_scaleController.text) ?? 1.0,
        );

        final gameMapService = context.read<GameMapService>();

        if (widget.gameMap == null) {
          // Créer une nouvelle carte
          await gameMapService.addGameMap(gameMap);
        } else {
          // Mettre à jour une carte existante
          await gameMapService.updateGameMap(gameMap);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Carte sauvegardée avec succès'),
              backgroundColor: Colors.green,
            ),
          );

          // Recharger les cartes depuis l'API après la création ou mise à jour
          await gameMapService.loadGameMaps();

          Navigator.of(context).pop(true);  // Ferme l'écran et revient à la liste
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
                onPressed: _saveGameMap,
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
