import 'package:shared_preferences/shared_preferences.dart';

class InfoPanelPreferencesService {
  static const String _keyPrefix = 'info_panel_seen_';

  // English tab keys
  static const String fieldTab = 'field';
  static const String mapsTab = 'maps';
  static const String scenariosTab = 'scenarios';
  static const String playersTab = 'players';
  static const String historyTab = 'history';

  /// Vérifier si le panneau d'un onglet a déjà été vu
  static Future<bool> hasSeenInfoPanel(String tabKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyPrefix$tabKey') ?? false;
  }

  /// Marquer le panneau d'un onglet comme vu
  static Future<void> markInfoPanelAsSeen(String tabKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix$tabKey', true);
  }

  /// Obtenir la clé d'onglet selon l'index
  static String getTabKeyFromIndex(int index) {
    switch (index) {
      case 0: return fieldTab;
      case 1: return mapsTab;
      case 2: return scenariosTab;
      case 3: return playersTab;
      case 4: return historyTab;
      default: return fieldTab;
    }
  }
}
