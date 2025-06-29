// lib/config/app_config.dart
import 'dart:ui';

class AppConfig {
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // 🇬🇧 Anglais (défaut)
    Locale('fr', 'FR'), // 🇫🇷 Français
    Locale('es', 'ES'), // 🇪🇸 Espagnol
    Locale('it', 'IT'), // 🇮🇹 Italien
    Locale('pt', 'PT'), // 🇵🇹 Portugais
    Locale('de', 'DE'), // 🇩🇪 Allemand
    Locale('nl', 'NL'), // 🇳🇱 Néerlandais
    Locale('sv', 'SE'), // 🇸🇪 Suédois
    Locale('no', 'NO'), // 🇳🇴 Norvégien
    Locale('pl', 'PL'), // 🇵🇱 Polonais
    Locale('ja', 'JP'), // 🇯🇵 Japonais
  ];

  static const Locale fallbackLocale = Locale('en', 'US');

  static String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en': return 'English';
      case 'fr': return 'Français';
      case 'es': return 'Español';
      case 'it': return 'Italiano';
      case 'pt': return 'Português';
      case 'de': return 'Deutsch';
      case 'nl': return 'Nederlands';
      case 'sv': return 'Svenska';
      case 'no': return 'Norsk';
      case 'pl': return 'Polski';
      case 'ja': return '日本語';
      default: return 'English';
    }
  }

  static String getLanguageFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'en': return '🇬🇧';
      case 'fr': return '🇫🇷';
      case 'es': return '🇪🇸';
      case 'it': return '🇮🇹';
      case 'pt': return '🇵🇹';
      case 'de': return '🇩🇪';
      case 'nl': return '🇳🇱';
      case 'sv': return '🇸🇪';
      case 'no': return '🇳🇴';
      case 'pl': return '🇵🇱';
      case 'ja': return '🇯🇵';
      default: return '🇬🇧';
    }
  }
}