import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scenario/treasure_hunt/treasure_hunt_notification.dart';
import '../screens/scenario/treasure_hunt/scoreboard_screen.dart';
import '../services/scenario/treasure_hunt/treasure_hunt_service.dart';
import '../services/websocket/treasure_hunt_websocket_handler.dart';

class TreasureHuntNotificationWidget extends StatelessWidget {
  final int scenarioId;
  final String scenarioName;

  const TreasureHuntNotificationWidget({
    Key? key,
    required this.scenarioId,
    required this.scenarioName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final treasureHuntService = Provider.of<TreasureHuntService>(context, listen: false);

    return StreamBuilder<TreasureFoundData>(
      stream: treasureHuntService.treasureFoundStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final treasureData = snapshot.data!;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${treasureData.username} a trouvé "${treasureData.treasureName}" !'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Voir scores',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScoreboardScreen(
                        treasureHuntId: scenarioId,
                        scenarioName: scenarioName,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        });

        return const SizedBox.shrink();
      },
    );
  }
}

