import "package:flutter/material.dart";

class PoiEditDialog extends StatefulWidget {
  final String? initialName;
  final String? initialIconIdentifier;

  const PoiEditDialog({
    Key? key,
    this.initialName,
    this.initialIconIdentifier,
  }) : super(key: key);

  @override
  _PoiEditDialogState createState() => _PoiEditDialogState();
}

class _PoiEditDialogState extends State<PoiEditDialog> {
  late TextEditingController _nameController;
  String? _selectedIconIdentifier;

  // Liste d'icônes Material Design pertinentes pour le thème
  // Chaque entrée est un Map avec 'identifier' (String) et 'icon' (IconData)
  final List<Map<String, dynamic>> _availableIcons = [
    {"identifier": "flag", "icon": Icons.flag, "label": "Drapeau"},
    {"identifier": "bomb", "icon": Icons.dangerous, "label": "Bombe"}, // Placeholder, 'dangerous' est proche
    {"identifier": "star", "icon": Icons.star, "label": "Étoile"},
    {"identifier": "place", "icon": Icons.place, "label": "Lieu"},
    {"identifier": "pin_drop", "icon": Icons.pin_drop, "label": "Repère"},
    {"identifier": "house", "icon": Icons.house, "label": "Maison"},
    {"identifier": "cabin", "icon": Icons.cabin, "label": "Cabane"},
    {"identifier": "door", "icon": Icons.meeting_room, "label": "Porte"}, // Placeholder
    {"identifier": "skull", "icon": Icons.warning_amber_rounded, "label": "Tête de Mort"}, // Placeholder, 'warning' est proche
    {"identifier": "navigation", "icon": Icons.navigation, "label": "Navigation"},
    {"identifier": "target", "icon": Icons.gps_fixed, "label": "Cible"},
    {"identifier": "ammo", "icon": Icons.local_mall, "label": "Munitions"}, // Placeholder
    {"identifier": "medical", "icon": Icons.medical_services, "label": "Médical"},
    {"identifier": "radio", "icon": Icons.radio, "label": "Radio"},
    {"identifier": "default_poi_icon", "icon": Icons.location_pin, "label": "Par Défaut"},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? "Point Stratégique");
    _selectedIconIdentifier = widget.initialIconIdentifier ?? "default_poi_icon";
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? "Créer Point Stratégique" : "Éditer Point Stratégique"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Nom du point"),
              autofocus: true,
            ),
            SizedBox(height: 20),
            Text("Choisir une icône:", style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _availableIcons.map((iconData) {
                bool isSelected = _selectedIconIdentifier == iconData["identifier"];
                return ChoiceChip(
                  avatar: Icon(iconData["icon"], color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
                  label: Text(iconData["label"]),
                  selected: isSelected,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedIconIdentifier = iconData["identifier"];
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text("Annuler"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text("Sauvegarder"),
          onPressed: () {
            if (_nameController.text.isNotEmpty && _selectedIconIdentifier != null) {
              Navigator.of(context).pop({
                "name": _nameController.text,
                "iconIdentifier": _selectedIconIdentifier,
              });
            } else {
              // Optionnel: afficher un message d'erreur si le nom est vide ou aucune icône n'est sélectionnée
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Veuillez entrer un nom et sélectionner une icône.")),
              );
            }
          },
        ),
      ],
    );
  }
}

