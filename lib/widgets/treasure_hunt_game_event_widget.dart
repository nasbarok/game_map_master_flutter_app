import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/scenario/treasure_hunt/treasure_hunt_notification.dart';
import '../services/websocket/treasure_hunt_websocket_handler.dart';

class TreasureHuntGameEventWidget extends StatelessWidget {
  final int scenarioId;

  const TreasureHuntGameEventWidget({
    Key? key,
    required this.scenarioId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final treasureHuntWebSocketHandler = Provider.of<TreasureHuntWebSocketHandler>(context, listen: false);

    return StreamBuilder<TreasureHuntNotification>(
      stream: treasureHuntWebSocketHandler.gameEventStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();

        final notification = snapshot.data!;

        // Afficher une notification temporaire
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notification.message),
              duration: Duration(seconds: 5),
              backgroundColor: notification.isGameStart ? Colors.green : Colors.orange,
            ),
          );
        });

        return SizedBox.shrink();
      },
    );
  }
}
