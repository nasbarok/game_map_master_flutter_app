// lib/services/favorites_service.dart
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

class FavoritesService extends ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;

  FavoritesService(this._apiService,this._authService);


  final Set<int> _favoritePlayerIds = <int>{};

  Set<int> get favoritePlayerIds => Set.unmodifiable(_favoritePlayerIds);

  bool isFavorite(int playerId) {
    return _favoritePlayerIds.contains(playerId);
  }

  Future<void> addToFavorites(int playerId) async {
    try {
      logger.d('🌟 Ajout du joueur $playerId aux favoris');

      await _apiService.post('favorites/add', {
        'playerId': playerId,
      });

      _favoritePlayerIds.add(playerId);
      notifyListeners();

      logger.d('✅ Joueur $playerId ajouté aux favoris');
    } catch (e) {
      logger.d('❌ Erreur lors de l\'ajout aux favoris: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorites(int playerId) async {
    try {
      logger.d('🗑️ Suppression du joueur $playerId des favoris');

      await _apiService.delete('favorites/remove/$playerId');

      _favoritePlayerIds.remove(playerId);
      notifyListeners();

      logger.d('✅ Joueur $playerId retiré des favoris');
    } catch (e) {
      logger.d('❌ Erreur lors de la suppression des favoris: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(int playerId) async {
    if (isFavorite(playerId)) {
      await removeFromFavorites(playerId);
    } else {
      await addToFavorites(playerId);
    }
  }

  Future<void> loadFavorites() async {
    try {
      logger.d('📥 Chargement des favoris depuis le backend');

      final response = await _apiService.get('favorites');
      final List<dynamic> favoritesData = response['favorites'] ?? [];

      _favoritePlayerIds.clear();
      for (var favoriteData in favoritesData) {
        final playerId = favoriteData['playerId'] as int?;
        if (playerId != null) {
          _favoritePlayerIds.add(playerId);
        }
      }

      notifyListeners();
      logger.d('✅ ${_favoritePlayerIds.length} favoris chargés');
    } catch (e) {
      logger.d('❌ Erreur lors du chargement des favoris: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFavoritePlayersDetails() async {
    try {
      logger.d('📋 Récupération des détails des joueurs favoris');

      if (_favoritePlayerIds.isEmpty) {
        return [];
      }

      final response = await _apiService.get('favorites/details');
      final List<dynamic> playersData = response['players'] ?? [];

      logger.d('✅ Détails de ${playersData.length} joueurs favoris récupérés');
      return List<Map<String, dynamic>>.from(playersData);
    } catch (e) {
      logger.d('❌ Erreur lors de la récupération des détails des favoris: $e');
      return [];
    }
  }

  void clearFavorites() {
    _favoritePlayerIds.clear();
    notifyListeners();
    logger.d('🧹 Favoris nettoyés');
  }
}