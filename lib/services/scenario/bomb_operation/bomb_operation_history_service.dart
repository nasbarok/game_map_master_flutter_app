import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import '../../../models/scenario/bomb_operation/bomb_operation_history.dart';
import '../../../models/scenario/bomb_operation/bomb_site_history.dart';
import '../../../utils/app_utils.dart';
import '../../api_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

/// Service pour gérer l'historique et le replay des sessions Bomb Operation
class BombOperationHistoryService {
  late final ApiService _apiService;

  BombOperationHistoryService() {
    _apiService = GetIt.I<ApiService>();
  }

  /// Obtient l'historique complet d'une session pour le replay
  Future<BombOperationHistory?> getSessionHistory(int gameSessionId) async {
    try {
      final response = await _apiService.get('bomb-operation/history/$gameSessionId');
      logger.d('[BombOperationHistoryService] [getSessionHistory] $gameSessionId : $response');
      if (response != null) {
        return BombOperationHistory.fromJson(response);
      } else {
        logger.d('❌[BombOperationHistoryService] [getSessionHistory] Erreur lors de la récupération de l\'historique');
        return null;
      }
    } catch (e) {
      logger.d('❌[BombOperationHistoryService] [getSessionHistory] Exception lors de la récupération de l\'historique: $e');
      return null;
    }
  }

  /// Obtient l'historique de tous les sites d'une session
  Future<List<BombSiteHistory>> getBombSitesHistory(int gameSessionId) async {
    try {
      final response = await _apiService.get('bomb-operation/history/$gameSessionId/sites');
      logger.d('[BombOperationHistoryService] [getBombSitesHistory] $gameSessionId : $response');
      if (response != null && response is List) {
        return response.map((e) => BombSiteHistory.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        logger.d('❌ Erreur lors de la récupération de l\'historique des sites');
        return [];
      }
    } catch (e) {
      logger.d('❌ Exception lors de la récupération de l\'historique des sites: $e');
      return [];
    }
  }

  /// Obtient la timeline des événements d'une session
  Future<List<BombEvent>> getSessionTimeline(int gameSessionId) async {
    try {
      final response = await _apiService.get('bomb-operation/history/$gameSessionId/timeline');

      if (response != null && response is List) {
        return response.map((e) => BombEvent.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        logger.d('❌ Erreur lors de la récupération de la timeline');
        return [];
      }
    } catch (e) {
      logger.d('❌ Exception lors de la récupération de la timeline: $e');
      return [];
    }
  }

  /// Obtient l'état des sites à un moment donné (pour le replay)
  Future<List<BombSiteHistory>> getSitesStateAtTime(int gameSessionId, DateTime timestamp) async {
    try {
      final response = await _apiService.get('bomb-operation/history/$gameSessionId/state-at-time?timestamp=${timestamp.toIso8601String()}');

      if (response != null && response is List) {
        return response.map((e) => BombSiteHistory.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        logger.d('❌ Erreur lors de la récupération de l\'état des sites');
        return [];
      }
    } catch (e) {
      logger.d('❌ Exception lors de la récupération de l\'état des sites: $e');
      return [];
    }
  }
}

