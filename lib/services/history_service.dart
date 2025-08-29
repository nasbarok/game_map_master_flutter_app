import 'package:flutter/material.dart';
import '../models/field.dart';
import '../models/game_session.dart';
import '../models/pagination/paginated_response.dart';
import 'api_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

class HistoryService {
  final ApiService _apiService;

  HistoryService(this._apiService);

  // -----------------------------
  // 🔢 Helpers
  // -----------------------------
  String _buildQuery(Map<String, String> params) {
    if (params.isEmpty) return '';
    final q = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '?$q';
  }
  // -----------------------------
  // ✅ NOUVELLES MÉTHODES PAGINÉES
  // -----------------------------

  /// Terrains (paginé)
  Future<PaginatedResponse<Field>> getFieldsPaginated({
    int page = 0,
    int size = 15,
  }) async {
    logger.d('[HistoryService] 📤 GET /history/fields (page=$page, size=$size) [paginated]');
    try {
      final query = _buildQuery({
        'page': '$page',
        'size': '$size',
      });

      final response = await _apiService.get('history/fields$query');

      if (response == null) {
        logger.d('[HistoryService] ⚠️ Réponse nulle reçue');
        return const PaginatedResponse<Field>(
          content: [],
          totalElements: 0,
          totalPages: 0,
          number: 0,
          size: 0,
          first: true,
          last: true,
          numberOfElements: 0,
        );
      }

      logger.d('[HistoryService] ✅ totalElements=${response['totalElements']}');
      return PaginatedResponse<Field>.fromJson(
        response as Map<String, dynamic>,
            (json) => Field.fromJson(json),
      );
    } catch (e) {
      logger.d('[HistoryService] ❌ Exception (fields paginés) : $e');
      rethrow;
    }
  }

  /// Sessions d’un terrain (paginé + filtres)
  /// startDate/endDate : ISO-8601 (OffsetDateTime côté backend)
  Future<PaginatedResponse<GameSession>> getGameSessionsByFieldIdPaginated(
      int fieldId, {
        int page = 0,
        int size = 10,
        DateTime? startDate,
        DateTime? endDate,
      }) async {
    logger.d('[HistoryService] 📤 GET /history/fields/$fieldId/sessions [paginated]');
    try {
      final params = <String, String>{
        'page': '$page',
        'size': '$size',
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };
      final query = _buildQuery(params);

      final response = await _apiService.get('history/fields/$fieldId/sessions$query');

      if (response == null) {
        logger.d('[HistoryService] ⚠️ Réponse nulle (sessions par terrain)');
        return const PaginatedResponse<GameSession>(
          content: [],
          totalElements: 0,
          totalPages: 0,
          number: 0,
          size: 0,
          first: true,
          last: true,
          numberOfElements: 0,
        );
      }

      logger.d('[HistoryService] ✅ totalElements=${response['totalElements']} (fieldId=$fieldId)');
      return PaginatedResponse<GameSession>.fromJson(
        response as Map<String, dynamic>,
            (json) => GameSession.fromJson(json),
      );
    } catch (e) {
      logger.d('[HistoryService] ❌ Exception (sessions par terrain paginées) : $e');
      rethrow;
    }
  }

  /// Toutes les sessions (paginé + filtres)
  /// startDate/endDate : ISO-8601 (OffsetDateTime côté backend)
  Future<PaginatedResponse<GameSession>> getGameSessionsPaginated({
    int page = 0,
    int size = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    logger.d('[HistoryService] 📤 GET /history/sessions [paginated]');
    try {
      final params = <String, String>{
        'page': '$page',
        'size': '$size',
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };
      final query = _buildQuery(params);

      final response = await _apiService.get('history/sessions$query');

      if (response == null) {
        logger.d('[HistoryService] ⚠️ Réponse nulle (sessions)');
        return const PaginatedResponse<GameSession>(
          content: [],
          totalElements: 0,
          totalPages: 0,
          number: 0,
          size: 0,
          first: true,
          last: true,
          numberOfElements: 0,
        );
      }

      logger.d('[HistoryService] ✅ totalElements=${response['totalElements']}');
      return PaginatedResponse<GameSession>.fromJson(
        response as Map<String, dynamic>,
            (json) => GameSession.fromJson(json),
      );
    } catch (e) {
      logger.d('[HistoryService] ❌ Exception (sessions paginées) : $e');
      rethrow;
    }
  }

  // -----------------------------
  // ✅ MÉTHODES EXISTANTES (inchangées)
  // -----------------------------

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
        logger.d('[HistoryService] ❌ Format inattendu : ${response.runtimeType}, attendu List');
        return [];
      }

      logger.d('[HistoryService] ✅ Réponse reçue avec ${response.length} terrains');

      final fields = response.map((json) {
        try {
          final field = Field.fromJson(json);
          logger.d('[HistoryService] 🧩 Terrain chargé : ${field.name} (id: ${field.id})');
          return field;
        } catch (e) {
          logger.d('[HistoryService] ❌ Erreur parsing terrain : $e');
          return null;
        }
      }).whereType<Field>().toList();

      logger.d('[HistoryService] 🎯 Total de terrains valides : ${fields.length}');
      return fields;
    } catch (e) {
      logger.d('[HistoryService] ❌ Exception (terrains) : $e');
      return [];
    }
  }

  Future<Field?> getFieldById(int id) async {
    logger.d('[HistoryService] 📤 Envoi de la requête GET vers /history/fields/$id');

    try {
      final response = await _apiService.get('history/fields/$id');

      if (response == null) {
        logger.d('[HistoryService] ⚠️ Réponse nulle pour le terrain ID $id');
        return null;
      }

      logger.d('[HistoryService] ✅ Réponse reçue pour le terrain ID $id : $response');

      try {
        final field = Field.fromJson(response);
        logger.d('[HistoryService] 🧩 Terrain chargé : ${field.name} (id: ${field.id})');
        return field;
      } catch (e) {
        logger.d('[HistoryService] ❌ Erreur parsing terrain ID $id : $e');
        return null;
      }
    } catch (e) {
      logger.d('[HistoryService] ❌ Exception (terrain ID $id) : $e');
      return null;
    }
  }

  // 🔁 Sessions de jeu par terrain
  Future<List<GameSession>> getGameSessionsByFieldId(
      int fieldId, {
        int page = 0,
        int size = 10,
        DateTime? startDate,
        DateTime? endDate,
      }) async {
    logger.d('[HistoryService] 📤 GET /history/fields/$fieldId/sessions (page=$page, size=$size)');

    try {
      // ⚠️ back attend startDate / endDate (OffsetDateTime ISO)
      final params = <String, String>{
        'page': '$page',
        'size': '$size',
        if (startDate != null) 'startDate': startDate.toUtc().toIso8601String(),
        if (endDate   != null) 'endDate'  : endDate.toUtc().toIso8601String(),
      };
      final query = _buildQuery(params);

      final response = await _apiService.get('history/fields/$fieldId/sessions$query');

      if (response == null) {
        logger.d('[HistoryService] ⚠️ Réponse nulle pour fieldId=$fieldId');
        return [];
      }

      // ✅ Nouveau format paginé
      if (response is Map<String, dynamic>) {
        final pageObj = PaginatedResponse<GameSession>.fromJson(
          response,
              (json) => GameSession.fromJson(json),
        );
        logger.d('[HistoryService] ✅ ${pageObj.numberOfElements} élément(s) (page ${pageObj.number}/${pageObj.totalPages})');
        return pageObj.content;
      }

      // ♻️ Rétro-compat (ancien format: List)
      if (response is List) {
        final list = response.map((json) {
          try { return GameSession.fromJson(json); } catch (_) { return null; }
        }).whereType<GameSession>().toList();
        logger.d('[HistoryService] ♻️ Ancien format détecté: ${list.length} élément(s)');
        return list;
      }

      logger.d('[HistoryService] ❌ Format inattendu: ${response.runtimeType}');
      return [];
    } catch (e) {
      logger.d('[HistoryService] ❌ Exception (sessions par terrain) : $e');
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
          logger.d('[HistoryService] ❌ Erreur parsing session : $e');
          return null;
        }
      }).whereType<GameSession>().toList();

      return sessions;
    } catch (e) {
      logger.d('[HistoryService] ❌ Exception (sessions) : $e');
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
      logger.d('[HistoryService] ❌ Erreur (session id=$id) : $e');
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
      logger.d('[HistoryService] ❌ Échec suppression session id=$id : $e');
      rethrow;
    }
  }

  // 📊 Statistiques d’une session
  Future<Map<String, dynamic>> getGameSessionStatistics(int id) async {
    logger.d('[HistoryService] 📊 Stats pour la session id=$id...');
    try {
      final response = await _apiService.get('history/sessions/$id/statistics');

      if (response == null) {
        logger.d('[HistoryService] ⚠️ Aucune statistique trouvée pour la session id=$id');
        return {};
      }

      logger.d('[HistoryService] ✅ Statistiques brutes reçues : $response');
      return response as Map<String, dynamic>;
    } catch (e) {
      logger.d('[HistoryService] ❌ Erreur stats session id=$id : $e');
      rethrow;
    }
  }

  Future<void> deleteField(int id) async {
    logger.d('[HistoryService] 🗑️ Suppression du terrain id=$id...');
    try {
      await _apiService.delete('history/fields/$id');
      logger.d('[HistoryService] ✅ Terrain id=$id supprimé avec succès.');
    } catch (e) {
      logger.d('[HistoryService] ❌ Échec suppression terrain id=$id : $e');
      rethrow;
    }
  }


}
