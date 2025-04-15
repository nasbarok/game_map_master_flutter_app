import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../models/scenario/treasure_hunt/treasure.dart';
import '../../../models/scenario/treasure_hunt/treasure_hunt_notification.dart';
import '../../../models/scenario/treasure_hunt/treasure_hunt_scenario.dart';
import '../../../models/scenario/treasure_hunt/treasure_hunt_score.dart';
import '../../api_service.dart';
class TreasureHuntService {
  final ApiService _apiService;

  TreasureHuntService(this._apiService) ;

  final _treasureFoundController = StreamController<TreasureFoundData>.broadcast();
  Stream<TreasureFoundData> get treasureFoundStream => _treasureFoundController.stream;

  void addTreasureFoundEvent(TreasureFoundData event) {
    _treasureFoundController.add(event);
  }

  void dispose() {
    _treasureFoundController.close();
  }

  // Méthodes pour TreasureHuntScenario
  Future<TreasureHuntScenario> getTreasureHuntScenario(int scenarioId) async {
    final response = await _apiService.get('scenarios/treasure-hunt/$scenarioId');
    return TreasureHuntScenario.fromJson(response);
  }

  Future<void> lockScores(int treasureHuntId, bool locked) async {
    await _apiService.post('scenarios/treasure-hunt/$treasureHuntId/lock-scores', {
      'locked': locked,
    });
  }

  Future<void> resetScores(int treasureHuntId) async {
    await _apiService.post('scenarios/treasure-hunt/$treasureHuntId/reset-scores', {});
  }

  Future<void> activateScenario(int treasureHuntId, bool active) async {
    await _apiService.post('scenarios/treasure-hunt/$treasureHuntId/activate', {
      'active': active,
    });
  }

  // Méthodes pour Treasure
  Future<List<Treasure>> getTreasures(int treasureHuntId) async {
    final response = await _apiService.get('scenarios/treasure-hunt/$treasureHuntId/treasures');
    return (response as List).map((item) => Treasure.fromJson(item)).toList();
  }

  Future<Treasure> updateTreasure(int treasureId, String name, int points, String symbol) async {
    final response = await _apiService.put('scenarios/treasure-hunt/treasures/$treasureId', {
      'name': name,
      'points': points,
      'symbol': symbol,
    });
    return Treasure.fromJson(response);
  }

  Future<List<Treasure>> createTreasuresBatch(int treasureHuntId, int count, int defaultValue, String defaultSymbol) async {
    final response = await _apiService.post('scenarios/treasure-hunt/$treasureHuntId/treasures/batch', {
      'count': count,
      'defaultValue': defaultValue,
      'defaultSymbol': defaultSymbol,
    });
    return (response as List).map((item) => Treasure.fromJson(item)).toList();
  }

  // Méthodes pour QR Codes
  Future<List<Map<String, dynamic>>> generateQRCodes(int treasureHuntId) async {
    final response = await _apiService.get('scenarios/treasure-hunt/$treasureHuntId/qrcodes');
    return List<Map<String, dynamic>>.from(response);
  }

  String getTreasureQRCodeImageUrl(int treasureId) {
    return '${ApiService.baseUrl}/scenarios/treasure-hunt/treasures/$treasureId/qrcode-image';
  }

  // Méthodes pour le scan de QR codes
  Future<Map<String, dynamic>> scanQRCode(String qrCode, int? teamId) async {
    final response = await _apiService.post('scenarios/treasure-hunt/scan', {
      'qrCode': qrCode,
      'teamId': teamId,
    });
    return response;
  }

  // Méthodes pour les scores
  Future<Map<String, dynamic>> getScoreboard(int treasureHuntId) async {
    final response = await _apiService.get('scenarios/treasure-hunt/$treasureHuntId/scores');
    return response;
  }

  List<TreasureHuntScore> parseIndividualScores(Map<String, dynamic> scoreboard) {
    final List<dynamic> scores = scoreboard['individualScores'];
    return scores.map((score) => TreasureHuntScore.fromJson(score)).toList();
  }

  List<TreasureHuntScore> parseTeamScores(Map<String, dynamic> scoreboard) {
    if (!scoreboard.containsKey('teamScores')) return [];
    final List<dynamic> scores = scoreboard['teamScores'];
    return scores.map((score) => TreasureHuntScore.fromJson(score)).toList();
  }

  Future<TreasureHuntScenario> ensureTreasureHuntScenario(int scenarioId) async {
    final response = await _apiService.post('scenarios/treasure-hunt/$scenarioId/ensure', {});
    return TreasureHuntScenario.fromJson(response);
  }

  Future<void> deleteTreasure(int treasureId) async {
    await _apiService.delete('scenarios/treasure-hunt/treasures/$treasureId');
  }

}
