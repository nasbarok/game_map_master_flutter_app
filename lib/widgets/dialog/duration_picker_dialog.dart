import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';

class DurationPickerDialog extends StatefulWidget {
  final int? initialDuration; // en minutes
  final Function(int?) onDurationSelected;

  const DurationPickerDialog({
    Key? key,
    this.initialDuration,
    required this.onDurationSelected,
  }) : super(key: key);

  @override
  _DurationPickerDialogState createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  int? selectedDuration;
  final TextEditingController _customController = TextEditingController();

  // Durées prédéfinies populaires
  final List<int?> presetDurations = [
    null,    // Illimité
    15,      // 15 min
    30,      // 30 min
    45,      // 45 min
    60,      // 1h
    90,      // 1h30
    120,     // 2h
    180,     // 3h
  ];

  @override
  void initState() {
    super.initState();
    selectedDuration = widget.initialDuration;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titre
            Row(
              children: [
                Icon(Icons.timer, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  l10n.selectGameDuration,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Durées prédéfinies
            Text(
              l10n.popularDurations,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presetDurations.map((duration) {
                final isSelected = selectedDuration == duration;
                final displayText = duration == null
                    ? "∞"
                    : duration < 60
                    ? "${duration} ${l10n.min}"
                    : "${duration ~/ 60}${l10n.h}${duration % 60 > 0 ? '${duration % 60} ${l10n.min}' : ''}";

                return FilterChip(
                  label: Text(displayText),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedDuration = duration;
                      _customController.clear();
                    });
                  },
                  selectedColor: Colors.green.withOpacity(0.3),
                  checkmarkColor: Colors.green,
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Durée personnalisée
            Text(
              l10n.customDuration,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: l10n.enterMinutes,
                suffixText: l10n.min,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                final minutes = int.tryParse(value);
                if (minutes != null && minutes > 0) {
                  setState(() {
                    selectedDuration = minutes;
                  });
                }
              },
            ),

            SizedBox(height: 24),

            // Boutons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onDurationSelected(selectedDuration);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.accept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}