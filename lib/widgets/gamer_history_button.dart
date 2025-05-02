import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/history/history_screen.dart';
import '../services/history_service.dart';

class GamerHistoryButton extends StatelessWidget {
  final int fieldId;
  const GamerHistoryButton({Key? key, required this.fieldId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.history),
      label: const Text('Historique'),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryScreen(fieldId: fieldId),
          ),
        );
      },
    );
  }
}

