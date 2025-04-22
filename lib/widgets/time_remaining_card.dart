import 'package:flutter/material.dart';

class TimeRemainingCard extends StatelessWidget {
  final int remainingTimeInSeconds;
  final bool isActive;
  final bool isCountdown;

  const TimeRemainingCard({
    Key? key,
    required this.remainingTimeInSeconds,
    required this.isActive,
    required this.isCountdown,
  }) : super(key: key);

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer,
                  color: isActive ? Colors.green : Colors.red,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  isCountdown ? 'Temps restant' : 'Temps écoulé',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'En cours' : 'Terminé',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                _formatTime(remainingTimeInSeconds),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.green : Colors.red,
                ),
              ),
            ),
            if (isActive && isCountdown)
              LinearProgressIndicator(
                value: _calculateProgressValue(remainingTimeInSeconds),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  String _formatRemainingTime(int seconds) {
    if (seconds <= 0) {
      return '00:00';
    }

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  double _calculateProgressValue(int seconds) {
    // Supposons que la durée maximale est de 2 heures (7200 secondes)
    // Ajustez cette valeur selon vos besoins
    const maxDuration = 7200;
    return seconds / maxDuration;
  }
}
