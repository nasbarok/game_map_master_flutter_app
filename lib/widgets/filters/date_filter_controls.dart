import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../generated/l10n/app_localizations.dart';

class DateFilterControls extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const DateFilterControls({
    Key? key,
    this.startDate,
    this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onReset,
    required this.onApply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFED8936).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrer par dates', // tu peux remplacer par l10n.filterByDates si ajouté dans tes traductions
            style: const TextStyle(
              color: Color(0xFFED8936),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Date de début
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _selectStartDate(context),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    startDate != null
                        ? DateFormat('dd/MM/yyyy').format(startDate!)
                        : 'Date début',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A5568),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Date de fin
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _selectEndDate(context),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    endDate != null
                        ? DateFormat('dd/MM/yyyy').format(endDate!)
                        : 'Date fin',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A5568),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.clear, size: 18),
                  label: Text(l10n.resetButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF718096),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApply,
                  icon: const Icon(Icons.search, size: 18),
                  label: Text(l10n.apply),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED8936),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) onStartDateChanged(picked);
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) onEndDateChanged(picked);
  }
}
