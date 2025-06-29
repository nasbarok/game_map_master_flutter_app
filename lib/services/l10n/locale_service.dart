// lib/services/locale_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_config.dart';

class LocaleService extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';

  Locale _currentLocale = AppConfig.fallbackLocale;

  Locale get currentLocale => _currentLocale;

  LocaleService() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_localeKey);

    if (savedLanguageCode != null) {
      // Chercher la locale correspondante
      for (var locale in AppConfig.supportedLocales) {
        if (locale.languageCode == savedLanguageCode) {
          _currentLocale = locale;
          notifyListeners();
          break;
        }
      }
    } else {
      // Utiliser la langue du système si supportée
      _setSystemLocale();
    }
  }

  void _setSystemLocale() {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;

    for (var locale in AppConfig.supportedLocales) {
      if (locale.languageCode == systemLocale.languageCode) {
        _currentLocale = locale;
        notifyListeners();
        return;
      }
    }

    // Garder la langue par défaut si système non supporté
  }

  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;

    _currentLocale = locale;
    notifyListeners();

    // Sauvegarder la préférence
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> resetToSystemLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localeKey);
    _setSystemLocale();
  }
}