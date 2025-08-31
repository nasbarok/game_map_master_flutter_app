import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import '../screens/history/field_sessions_screen.dart';

class GamerHistoryButton extends StatelessWidget {
  final int fieldId;

  const GamerHistoryButton({Key? key, required this.fieldId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ElevatedButton.icon(
      icon: const Icon(Icons.history),
      label: Text(l10n.historyTab),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FieldSessionsScreen(
              fieldId: fieldId
            ),
          ),
        );
      },
    );
  }
}

