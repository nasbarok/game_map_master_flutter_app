import 'dart:convert';
import 'package:http/http.dart' as http;

class GameSessionService {
  final String baseUrl;
  final http.Client client;

  GameSessionService({required this.baseUrl, required this.client});

  // Démarrer une partie
  Future<void> startGame(int mapId, int scenarioId) async {
    final url = '$baseUrl/api/games/maps/$mapId/start';
    final queryParams = {'scenarioId': scenarioId.toString()};

    final response = await client.post(
      Uri.parse(url).replace(queryParameters: queryParams),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to start game: ${response.body}');
    }
  }

  // Terminer une partie
  Future<void> endGame(int mapId) async {
    final url = '$baseUrl/api/games/maps/$mapId/end';

    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to end game: ${response.body}');
    }
  }
}