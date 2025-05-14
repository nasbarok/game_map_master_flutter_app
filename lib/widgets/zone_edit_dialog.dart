import "package:flutter/material.dart";
import "package:flutter_colorpicker/flutter_colorpicker.dart";

class ZoneEditDialog extends StatefulWidget {
  final String? initialName;
  final Color? initialColor;

  const ZoneEditDialog({
    Key? key,
    this.initialName,
    this.initialColor,
  }) : super(key: key);

  @override
  _ZoneEditDialogState createState() => _ZoneEditDialogState();
}

class _ZoneEditDialogState extends State<ZoneEditDialog> {
  late TextEditingController _nameController;
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? "Nouvelle Zone");
    _currentColor = widget.initialColor ?? Colors.blue; // Default color
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _changeColor(Color color) {
    setState(() => _currentColor = color);
  }

  String _colorToHex(Color color) {
    return '#${color.alpha.toRadixString(16).padLeft(2, '0')}${color.red.toRadixString(16).padLeft(2, '0')}${color.green.toRadixString(16).padLeft(2, '0')}${color.blue.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? "Créer une Zone" : "Éditer la Zone"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Nom de la zone"),
              autofocus: true,
            ),
            SizedBox(height: 20),
            Text("Couleur de la zone :"),
            SizedBox(height: 10),
            BlockPicker(
              pickerColor: _currentColor,
              onColorChanged: _changeColor,
              availableColors: const [
                Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
                Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
                Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
                Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
                Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
              ],
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
        TextButton(
          child: Text("Sauvegarder"),
          onPressed: () {
            if (_nameController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Le nom de la zone ne peut pas être vide.")),
              );
              return;
            }
            Navigator.of(context).pop({
              "name": _nameController.text,
              "color": _colorToHex(_currentColor),
            });
          },
        ),
      ],
    );
  }
}

