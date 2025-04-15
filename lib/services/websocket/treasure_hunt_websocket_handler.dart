import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/scenario/treasure_hunt/treasure_hunt_notification.dart';
import '../websocket_service.dart';

class TreasureHuntWebSocketHandler {
  final WebSocketService _webSocketService;

  final _treasureFoundController = StreamController<TreasureHuntNotification>.broadcast();
  final _scoreboardUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _gameEventController = StreamController<TreasureHuntNotification>.broadcast();

  Stream<TreasureHuntNotification> get treasureFoundStream => _treasureFoundController.stream;
  Stream<Map<String, dynamic>> get scoreboardUpdateStream => _scoreboardUpdateController.stream;
  Stream<TreasureHuntNotification> get gameEventStream => _gameEventController.stream;

  TreasureHuntWebSocketHandler(this._webSocketService);


  void _subscribeToWebSocketMessages() {
    _webSocketService.messageStream.listen((message) {
      try {
        final data = json.decode(message as String);
        final notification = TreasureHuntNotification.fromJson(data);

        if (notification.isTreasureFound) {
          _treasureFoundController.add(notification);
        } else if (notification.isScoreboardUpdate) {
          _scoreboardUpdateController.add(notification.data);
        } else if (notification.isGameStart || notification.isGameEnd) {
          _gameEventController.add(notification);
        }
      } catch (e) {
        debugPrint('[treasure_hunt_websocket_handler] Error processing WebSocket message: $e');
      }
    });
  }
  // ✅ Ajouter les événements (appelés par WebSocketMessageHandler)
  void addTreasureFoundEvent(TreasureFoundData event) {
    _treasureFoundController.add(event as TreasureHuntNotification);
  }

  void addScoreboardUpdate(Map<String, dynamic> data) {
    _scoreboardUpdateController.add(data);
  }

  void addGameEvent(TreasureHuntNotification event) {
    _gameEventController.add(event);
  }

  // ✅ Gestion abonnement WebSocket par scénario
  void subscribeToScenario(int scenarioId) {
    _webSocketService.subscribe('/topic/game/$scenarioId');
  }

  void unsubscribeFromScenario(int scenarioId) {
    _webSocketService.unsubscribe('/topic/game/$scenarioId');
  }

  void dispose() {
    _treasureFoundController.close();
    _scoreboardUpdateController.close();
    _gameEventController.close();
  }
}
