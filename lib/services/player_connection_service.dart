import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/connected_player.dart';

class PlayerConnectionService {
  final String baseUrl;
  final http.Client client;

  PlayerConnectionService({required this.baseUrl, required this.client});

  // Rejoindre une carte
  Future<ConnectedPlayer> joinMap(int fieldId, {int? teamId}) async {
    final url = '$baseUrl/api/fields/$fieldId/join';
    final queryParams = <String, dynamic>{};
    if (teamId != null) {
      queryParams['teamId'] = teamId.toString();
    }

    final response = await client.post(
      Uri.parse(url).replace(queryParameters: queryParams),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201) {
      return ConnectedPlayer.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to join map: ${response.body}');
    }
  }

  // Quitter une carte
  Future<void> leaveField(int fieldId) async {
    final url = '$baseUrl/api/fields/$fieldId/leave';

    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to leave map: ${response.body}');
    }
  }

  // Obtenir la liste des joueurs connectés
  Future<List<ConnectedPlayer>> getConnectedPlayers(int fieldId) async {
    final url = '$baseUrl/api/fields/$fieldId/players';

    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> playersJson = jsonDecode(response.body);
      return playersJson.map((json) => ConnectedPlayer.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get connected players: ${response.body}');
    }
  }
}
