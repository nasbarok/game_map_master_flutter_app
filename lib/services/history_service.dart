import 'package:flutter/material.dart';
import '../models/field.dart';
import '../models/game_session.dart';
import 'api_service.dart';

class HistoryService {
  final ApiService _apiService;

  HistoryService(this._apiService);

  // 🔁 Terrains pour l'hôte
  Future<List<Field>> getFields() async {
    debugPrint('[HistoryService] 📤 Envoi de la requête GET vers /history/fields');

    try {
      final response = await _apiService.get('history/fields');

      if (response == null) {
        debugPrint('[HistoryService] ⚠️ Réponse nulle reçue depuis /history/fields');
        return [];
      }

      if (response is! List) {
        debugPrint('[HistoryService] ❌ Format inattendu : réponse de type ${response.runtimeType}, attendu List');
        return [];
      }

      debugPrint('[HistoryService] ✅ Réponse reçue avec ${response.length} terrains');

      final fields = response.map((json) {
        try {
          final field = Field.fromJson(json);
          debugPrint('[HistoryService] 🧩 Terrain chargé : ${field.name} (id: ${field.id})');
          return field;
        } catch (e) {
          debugPrint('[HistoryService] ❌ Erreur lors du parsing d\'un terrain : $e');
          return null;
        }
      }).whereType<Field>().toList();

      debugPrint('[HistoryService] 🎯 Total de terrains valides : ${fields.length}');
      return fields;
    } catch (e) {
      debugPrint('[HistoryService] ❌ Exception lors de la récupération des terrains : $e');
      return [];
    }
  }


  Future<Field?> getFieldById(int id) async {
    debugPrint('[HistoryService] 📤 Envoi de la requête GET vers /history/fields/$id');

    try {
      final response = await _apiService.get('history/fields/$id');

      if (response == null) {
        debugPrint('[HistoryService] ⚠️ Réponse nulle reçue pour le terrain ID $id');
        return null;
      }

      debugPrint('[HistoryService] ✅ Réponse reçue pour le terrain ID $id : $response');

      try {
        final field = Field.fromJson(response);
        debugPrint('[HistoryService] 🧩 Terrain chargé : ${field.name} (id: ${field.id})');
        return field;
      } catch (e) {
        debugPrint('[HistoryService] ❌ Erreur lors du parsing du terrain ID $id : $e');
        return null;
      }
    } catch (e) {
      debugPrint('[HistoryService] ❌ Exception lors de la récupération du terrain ID $id : $e');
      return null;
    }
  }


  // 🔁 Sessions de jeu par terrain
  Future<List<GameSession>> getGameSessionsByFieldId(int fieldId) async {
    debugPrint('[HistoryService] 📤 Requête GET vers /history/fields/$fieldId/sessions');

    try {
      final response = await _apiService.get('history/fields/$fieldId/sessions');

      if (response == null) {
        debugPrint('[HistoryService] ⚠️ Réponse nulle pour les sessions du terrain $fieldId');
        return [];
      }

      if (response is! List) {
        debugPrint('[HistoryService] ❌ Format inattendu pour les sessions du terrain $fieldId : $response');
        return [];
      }

      debugPrint('[HistoryService] ✅ ${response.length} session(s) reçue(s) pour le terrain $fieldId');

      final sessions = response.map((json) {
        try {
          final session = GameSession.fromJson(json);
          debugPrint('[HistoryService] 🧩 Session chargée : id=${session.id}, active=${session.active}');
          return session;
        } catch (e) {
          debugPrint('[HistoryService] ❌ Erreur de parsing d\'une session : $e');
          return null;
        }
      }).whereType<GameSession>().toList();

      return sessions;
    } catch (e) {
      debugPrint('[HistoryService] ❌ Exception lors du chargement des sessions du terrain $fieldId : $e');
      return [];
    }
  }


  // 🔁 Toutes les sessions (côté joueur)
  Future<List<GameSession>> getGameSessions() async {
    debugPrint('[HistoryService] 📤 Requête GET vers /history/sessions');

    try {
      final response = await _apiService.get('history/sessions');

      if (response == null) {
        debugPrint('[HistoryService] ⚠️ Réponse nulle pour la liste des sessions');
        return [];
      }

      if (response is! List) {
        debugPrint('[HistoryService] ❌ Format inattendu pour la liste des sessions : $response');
        return [];
      }

      debugPrint('[HistoryService] ✅ ${response.length} session(s) reçue(s)');

      final sessions = response.map((json) {
        try {
          final session = GameSession.fromJson(json);
          debugPrint('[HistoryService] 🧩 Session chargée : id=${session.id}, active=${session.active}');
          return session;
        } catch (e) {
          debugPrint('[HistoryService] ❌ Erreur de parsing d\'une session : $e');
          return null;
        }
      }).whereType<GameSession>().toList();

      return sessions;
    } catch (e) {
      debugPrint('[HistoryService] ❌ Exception lors du chargement des sessions : $e');
      return [];
    }
  }


  Future<GameSession> getGameSessionById(int id) async {
    debugPrint('[HistoryService] 📤 Requête GET vers /history/sessions/$id');

    try {
      final response = await _apiService.get('history/sessions/$id');

      if (response == null) {
        debugPrint('[HistoryService] ⚠️ Aucune réponse reçue pour la session id=$id');
        throw Exception('Session introuvable');
      }

      final session = GameSession.fromJson(response);
      debugPrint('[HistoryService] ✅ Session chargée : id=${session.id}, active=${session.active}');
      return session;
    } catch (e) {
      debugPrint('[HistoryService] ❌ Erreur lors du chargement de la session id=$id : $e');
      throw Exception('Erreur lors du chargement de la session : $e');
    }
  }

  // ❌ Supprimer une session (réservé à l’hôte)
  Future<void> deleteGameSession(int id) async {
    debugPrint('[HistoryService] 🗑 Suppression de la session id=$id...');

    try {
      await _apiService.delete('history/sessions/$id');
      debugPrint('[HistoryService] ✅ Session id=$id supprimée avec succès');
    } catch (e) {
      debugPrint('[HistoryService] ❌ Échec de la suppression de la session id=$id : $e');
      rethrow;
    }
  }

// 📊 Statistiques d’une session
  Future<Map<String, dynamic>> getGameSessionStatistics(int id) async {
    debugPrint('[HistoryService] 📊 Récupération des statistiques pour la session id=$id...');

    try {
      final response = await _apiService.get('history/sessions/$id/statistics');

      if (response == null) {
        debugPrint('[HistoryService] ⚠️ Aucune statistique trouvée pour la session id=$id');
        return {};
      }

      debugPrint('[HistoryService] ✅ Statistiques brutes reçues : $response');
      final stats = response as Map<String, dynamic>;

      return stats;
    } catch (e) {
      debugPrint('[HistoryService] ❌ Erreur lors de la récupération des statistiques pour la session id=$id : $e');
      rethrow;
    }
  }


  Future<void> deleteField(int id) async {
    debugPrint('[HistoryService] 🗑️ Suppression du terrain id=$id...');

    try {
      await _apiService.delete('history/fields/$id');
      debugPrint('[HistoryService] ✅ Terrain id=$id supprimé avec succès.');
    } catch (e) {
      debugPrint('[HistoryService] ❌ Échec de la suppression du terrain id=$id : $e');
      rethrow;
    }
  }


}
