import 'package:flutter/material.dart';
import '../models/field.dart';
import '../models/game_session.dart';
import 'api_service.dart';
import 'package:airsoft_game_map/utils/logger.dart';

class HistoryService {
  final ApiService _apiService;

  HistoryService(this._apiService);

  // 🔁 Terrains pour l'hôte
  Future<List<Field>> getFields() async {
    logger.d('[HistoryService] 📤 Envoi de la requête GET vers /history/fields');

    try {
      final response = await _apiService.get('history/fields');

      if (response == null) {
        logger.d('[HistoryService] ⚠️ Réponse nulle reçue depuis /history/fields');
        return [];
      }

      if (response is! List) {
        logger.d('[HistoryService] ❌ Format inattendu : réponse de type ${response.runtimeType}, attendu List');
        return [];
      }

      logger.d('[HistoryService] ✅ Réponse reçue avec ${response.length} terrains');

      final fields = response.map((json) {
        try {
          final field = Field.fromJson(json);
          logger.d('[HistoryService] 🧩 Terrain chargé : ${field.name} (id: ${field.id})');
          return field;
        } catch (e) {
          logger.d('[HistoryService] ❌ Erreur lors du parsing d\'un terrain : $e');
          return null;
        }
      }).whereType<Field>().toList();

      logger.d('[HistoryService] 🎯 Total de terrains valides : ${fields.length}');
      return fields;
    } catch (e) {
      logger.d('[HistoryService] ❌ Exception lors de la récupération des terrains : $e');
      return [];
    }
  }


  Future<Field?> getFieldById(int id) async {
    logger.d('[HistoryService] 📤 Envoi de la requête GET vers /history/fields/$id');

    try {
      final response = await _apiService.get('history/fields/$id');

      if (response == null) {
        logger.d('[HistoryService] ⚠️ Réponse nulle reçue pour le terrain ID $id');
        return null;
      }

      logger.d('[HistoryService] ✅ Réponse reçue pour le terrain ID $id : $response');

      try {
        final field = Field.fromJson(response);
        logger.d('[HistoryService] 🧩 Terrain chargé : ${field.name} (id: ${field.id})');
        return field;
      } catch (e) {
        logger.d('[HistoryService] ❌ Erreur lors du parsing du terrain ID $id : $e');
        return null;
      }
    } catch (e) {
      logger.d('[HistoryService] ❌ Exception lors de la récupération du terrain ID $id : $e');
      return null;
    }
  }


  // 🔁 Sessions de jeu par terrain
  Future<List<GameSession>> getGameSessionsByFieldId(int fieldId) async {
    logger.d('[HistoryService] 📤 Requête GET vers /history/fields/$fieldId/sessions');

    try {
      final response = await _apiService.get('history/fields/$fieldId/sessions');

      if (response == null) {
        logger.d('[HistoryService] ⚠️ Réponse nulle pour les sessions du terrain $fieldId');
        return [];
      }

      if (response is! List) {
        logger.d('[HistoryService] ❌ Format inattendu pour les sessions du terrain $fieldId : $response');
        return [];
      }

      logger.d('[HistoryService] ✅ ${response.length} session(s) reçue(s) pour le terrain $fieldId');

      final sessions = response.map((json) {
        try {
          final session = GameSession.fromJson(json);
          logger.d('[HistoryService] 🧩 Session chargée : id=${session.id}, active=${session.active}');
          return session;
        } catch (e) {
          logger.d('[HistoryService] ❌ Erreur de parsing d\'une session : $e');
          return null;
        }
      }).whereType<GameSession>().toList();

      return sessions;
    } catch (e) {
      logger.d('[HistoryService] ❌ Exception lors du chargement des sessions du terrain $fieldId : $e');
      return [];
    }
  }


  // 🔁 Toutes les sessions (côté joueur)
  Future<List<GameSession>> getGameSessions() async {
    logger.d('[HistoryService] 📤 Requête GET vers /history/sessions');

    try {
      final response = await _apiService.get('history/sessions');

      if (response == null) {
        logger.d('[HistoryService] ⚠️ Réponse nulle pour la liste des sessions');
        return [];
      }

      if (response is! List) {
        logger.d('[HistoryService] ❌ Format inattendu pour la liste des sessions : $response');
        return [];
      }

      logger.d('[HistoryService] ✅ ${response.length} session(s) reçue(s)');

      final sessions = response.map((json) {
        try {
          final session = GameSession.fromJson(json);
          logger.d('[HistoryService] 🧩 Session chargée : id=${session.id}, active=${session.active}');
          return session;
        } catch (e) {
          logger.d('[HistoryService] ❌ Erreur de parsing d\'une session : $e');
          return null;
        }
      }).whereType<GameSession>().toList();

      return sessions;
    } catch (e) {
      logger.d('[HistoryService] ❌ Exception lors du chargement des sessions : $e');
      return [];
    }
  }


  Future<GameSession> getGameSessionById(int id) async {
    logger.d('[HistoryService] 📤 Requête GET vers /history/sessions/$id');

    try {
      final response = await _apiService.get('history/sessions/$id');

      if (response == null) {
        logger.d('[HistoryService] ⚠️ Aucune réponse reçue pour la session id=$id');
        throw Exception('Session introuvable');
      }

      final session = GameSession.fromJson(response);
      logger.d('[HistoryService] ✅ Session chargée : id=${session.id}, active=${session.active}');
      return session;
    } catch (e) {
      logger.d('[HistoryService] ❌ Erreur lors du chargement de la session id=$id : $e');
      throw Exception('Erreur lors du chargement de la session : $e');
    }
  }

  // ❌ Supprimer une session (réservé à l’hôte)
  Future<void> deleteGameSession(int id) async {
    logger.d('[HistoryService] 🗑 Suppression de la session id=$id...');

    try {
      await _apiService.delete('history/sessions/$id');
      logger.d('[HistoryService] ✅ Session id=$id supprimée avec succès');
    } catch (e) {
      logger.d('[HistoryService] ❌ Échec de la suppression de la session id=$id : $e');
      rethrow;
    }
  }

// 📊 Statistiques d’une session
  Future<Map<String, dynamic>> getGameSessionStatistics(int id) async {
    logger.d('[HistoryService] 📊 Récupération des statistiques pour la session id=$id...');

    try {
      final response = await _apiService.get('history/sessions/$id/statistics');

      if (response == null) {
        logger.d('[HistoryService] ⚠️ Aucune statistique trouvée pour la session id=$id');
        return {};
      }

      logger.d('[HistoryService] ✅ Statistiques brutes reçues : $response');
      final stats = response as Map<String, dynamic>;

      return stats;
    } catch (e) {
      logger.d('[HistoryService] ❌ Erreur lors de la récupération des statistiques pour la session id=$id : $e');
      rethrow;
    }
  }


  Future<void> deleteField(int id) async {
    logger.d('[HistoryService] 🗑️ Suppression du terrain id=$id...');

    try {
      await _apiService.delete('history/fields/$id');
      logger.d('[HistoryService] ✅ Terrain id=$id supprimé avec succès.');
    } catch (e) {
      logger.d('[HistoryService] ❌ Échec de la suppression du terrain id=$id : $e');
      rethrow;
    }
  }


}
