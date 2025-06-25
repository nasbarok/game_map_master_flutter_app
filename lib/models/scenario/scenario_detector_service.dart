import 'package:game_map_master_flutter_app/models/scenario/scenario_replay_extension.dart';
import 'package:get_it/get_it.dart';

import '../../screens/scenario/bomb_operation/bomb_operation_replay_extension.dart';
import '../../services/api_service.dart';

/// Service de détection automatique des scénarios pour le replay
/// 
/// Ce service analyse une session de jeu et détermine automatiquement
/// quels scénarios étaient actifs, puis charge les extensions appropriées.
class ScenarioDetectorService {
  
  final ApiService _apiService;
  
  ScenarioDetectorService() : _apiService = GetIt.I<ApiService>();
  
  /// Détecte et charge automatiquement les extensions de scénarios pour une session
  /// 
  /// [gameSessionId] : ID de la session de jeu à analyser
  /// 
  /// Retourne une liste des extensions de scénarios détectées et chargées avec succès.
  /// La liste peut être vide si aucun scénario n'est détecté ou si le chargement échoue.
  Future<List<ScenarioReplayExtension>> detectAndLoadScenarios(int gameSessionId) async {
    final List<ScenarioReplayExtension> loadedExtensions = [];
    
    try {
      // Récupérer les informations de la session
      final sessionInfo = await _getSessionInfo(gameSessionId);
      
      if (sessionInfo == null) {
        print('ℹ️ Aucune information de session trouvée pour ID: $gameSessionId');
        return loadedExtensions;
      }
      
      // Détecter et charger chaque type de scénario
      await _detectBombOperation(gameSessionId, loadedExtensions);
      await _detectTreasureHunt(gameSessionId, loadedExtensions);
      // Ajouter ici d'autres détections de scénarios futurs
      
      print('✅ Détection terminée: ${loadedExtensions.length} scénario(s) chargé(s)');
      
    } catch (e) {
      print('❌ Erreur lors de la détection des scénarios: $e');
    }
    
    return loadedExtensions;
  }
  
  /// Récupère les informations générales de la session
  Future<Map<String, dynamic>?> _getSessionInfo(int gameSessionId) async {
    try {
      final response = await _apiService.get('game-sessions/$gameSessionId');
      return response;
    } catch (e) {
      print('❌ Erreur lors de la récupération des infos de session: $e');
      return null;
    }
  }
  
  /// Détecte et charge l'extension Bomb Operation
  Future<void> _detectBombOperation(int gameSessionId, List<ScenarioReplayExtension> extensions) async {
    try {
      // Tenter de charger les données Bomb Operation
      final bombExtension = BombOperationReplayExtension();
      await bombExtension.loadData(gameSessionId);
      
      if (bombExtension.hasData) {
        extensions.add(bombExtension);
        print('✅ Scénario Bomb Operation détecté et chargé');
      } else {
        print('ℹ️ Aucune donnée Bomb Operation trouvée');
        bombExtension.dispose(); // Nettoyer si pas de données
      }
    } catch (e) {
      print('❌ Erreur lors de la détection Bomb Operation: $e');
    }
  }
  
  /// Détecte et charge l'extension Treasure Hunt (à implémenter)
  Future<void> _detectTreasureHunt(int gameSessionId, List<ScenarioReplayExtension> extensions) async {
    try {
      // TODO: Implémenter la détection de Treasure Hunt
      // final treasureExtension = TreasureHuntReplayExtension();
      // await treasureExtension.loadData(gameSessionId);
      // 
      // if (treasureExtension.hasData) {
      //   extensions.add(treasureExtension);
      //   print('✅ Scénario Treasure Hunt détecté et chargé');
      // }
      
      print('ℹ️ Détection Treasure Hunt pas encore implémentée');
    } catch (e) {
      print('❌ Erreur lors de la détection Treasure Hunt: $e');
    }
  }
  
  /// Détecte automatiquement le scénario principal d'une session
  /// 
  /// Retourne la première extension trouvée, ou null si aucune.
  /// Utile pour les cas où une seule extension est attendue.
  Future<ScenarioReplayExtension?> detectPrimaryScenario(int gameSessionId) async {
    final extensions = await detectAndLoadScenarios(gameSessionId);
    return extensions.isNotEmpty ? extensions.first : null;
  }
  
  /// Libère toutes les extensions d'une liste
  void disposeExtensions(List<ScenarioReplayExtension> extensions) {
    for (final extension in extensions) {
      extension.dispose();
    }
    extensions.clear();
  }
}

