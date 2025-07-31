import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../utils/logger.dart';

/// Service audio simple avec génération à la première ouverture
class SimpleVoiceService extends ChangeNotifier {
  static const String _volumeKey = 'audio_volume';
  static const String _enabledKey = 'audio_enabled';
  static const String _audioLanguageKey = 'audio_language';
  static const String _generatedLanguagesKey = 'generated_languages';

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isPlaying = false;

  // Paramètres utilisateur
  double _volume = 0.8;
  bool _isEnabled = true;
  String _audioLanguage = ''; // Langue audio séparée de la langue de l'app
  Set<String> _generatedLanguages = {}; // Langues pour lesquelles les fichiers sont générés

  // Cache des messages audio par langue
  final Map<String, Map<String, String>> _audioCache = {};

  // Getters
  double get volume => _volume;
  bool get isEnabled => _isEnabled;
  String get audioLanguage => _audioLanguage;
  bool get isPlaying => _isPlaying;
  Set<String> get generatedLanguages => Set.unmodifiable(_generatedLanguages);

  /// Initialise le service audio
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      logger.d('🔊 [SimpleVoiceService] Initialisation du service audio');

      // Configuration TTS
      await _configureTTS();

      // Charger les préférences
      await _loadPreferences();

      // Détecter la langue du téléphone si première utilisation
      if (_audioLanguage.isEmpty) {
        _audioLanguage = _detectPhoneLanguage();
        await _savePreferences();
      }

      // Vérifier si les fichiers audio existent pour la langue actuelle
      await _ensureAudioFilesGenerated(_audioLanguage);

      _isInitialized = true;
      logger.d('✅ [SimpleVoiceService] Service initialisé - Langue: $_audioLanguage');
    } catch (e) {
      logger.e('❌ [SimpleVoiceService] Erreur initialisation: $e');
    }
  }

  /// Configure le moteur TTS
  Future<void> _configureTTS() async {
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    // Configuration spécifique par plateforme
    if (Platform.isAndroid) {
      await _flutterTts.setEngine('com.google.android.tts');
    } else if (Platform.isIOS) {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.spokenAudio,
      );
    }

    // Callbacks
    _flutterTts.setStartHandler(() {
      _isPlaying = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      _isPlaying = false;
      notifyListeners();
      logger.e('❌ [SimpleVoiceService] Erreur TTS: $msg');
    });
  }

  /// Charge les préférences utilisateur
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _volume = prefs.getDouble(_volumeKey) ?? 0.8;
      _isEnabled = prefs.getBool(_enabledKey) ?? true;
      _audioLanguage = prefs.getString(_audioLanguageKey) ?? '';
      
      final generatedList = prefs.getStringList(_generatedLanguagesKey) ?? [];
      _generatedLanguages = generatedList.toSet();

      await _flutterTts.setVolume(_volume);
      logger.d('🔊 [SimpleVoiceService] Préférences chargées');
    } catch (e) {
      logger.e('❌ [SimpleVoiceService] Erreur chargement préférences: $e');
    }
  }

  /// Sauvegarde les préférences utilisateur
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_volumeKey, _volume);
      await prefs.setBool(_enabledKey, _isEnabled);
      await prefs.setString(_audioLanguageKey, _audioLanguage);
      await prefs.setStringList(_generatedLanguagesKey, _generatedLanguages.toList());
      logger.d('💾 [SimpleVoiceService] Préférences sauvegardées');
    } catch (e) {
      logger.e('❌ [SimpleVoiceService] Erreur sauvegarde préférences: $e');
    }
  }

  /// Détecte la langue du téléphone
  String _detectPhoneLanguage() {
    final locale = Platform.localeName;
    final languageCode = locale.split('_')[0].toLowerCase();
    
    // Mapper vers les langues supportées
    const supportedLanguages = {
      'fr': 'fr',
      'en': 'en', 
      'de': 'de',
      'es': 'es',
      'it': 'it',
      'ja': 'ja',
      'nl': 'nl',
      'no': 'no',
      'pl': 'pl',
      'pt': 'pt',
      'sv': 'sv',
    };

    final detectedLanguage = supportedLanguages[languageCode] ?? 'en';
    logger.d('🌍 [SimpleVoiceService] Langue détectée: $detectedLanguage (locale: $locale)');
    return detectedLanguage;
  }

  /// S'assure que les fichiers audio sont générés pour une langue
  Future<void> _ensureAudioFilesGenerated(String language) async {
    final messages = await _getAudioMessages(language);
    _audioCache[language] = Map<String, String>.from(messages);

    // Si les fichiers audio ont déjà été générés, on n’a pas besoin
    // de les régénérer, mais on remplit le cache.
    if (_generatedLanguages.contains(language)) {
      logger.d('[SimpleVoiceService] 🔊 Messages chargés depuis les .arb pour $language');
      return;
    }

    logger.d('[SimpleVoiceService] 🔊 Génération des fichiers audio pour: $language');
    await _generateAudioFiles(language);
    _generatedLanguages.add(language);
    await _savePreferences();
  }

  /// Génère tous les fichiers audio pour une langue
  Future<void> _generateAudioFiles(String language) async {
    try {
      // … configuration TTS …
      // Définir la langue TTS
      final ttsLanguage = _getTTSLanguageCode(language);
      await _flutterTts.setLanguage(ttsLanguage);

      // 🔄 Charger dynamiquement les textes depuis les fichiers .arb
      final messages = await _getAudioMessages(language);

      _audioCache[language] = {};

      for (final entry in messages.entries) {
        final messageKey = entry.key;
        final messageText = entry.value;

        _audioCache[language]![messageKey] = messageText;
        logger.d('🎵 [SimpleVoiceService] Message généré: $messageKey -> $messageText');
      }

      logger.d('✅ [SimpleVoiceService] ${messages.length} messages générés pour $language');
    } catch (e) {
      logger.e('❌ [SimpleVoiceService] Erreur génération audio pour $language: $e');
    }
  }


  /// Obtient le code langue pour TTS
  String _getTTSLanguageCode(String language) {
    const languageMap = {
      'fr': 'fr-FR',
      'en': 'en-US',
      'de': 'de-DE',
      'es': 'es-ES',
      'it': 'it-IT',
      'ja': 'ja-JP',
      'nl': 'nl-NL',
      'no': 'no-NO',
      'pl': 'pl-PL',
      'pt': 'pt-PT',
      'sv': 'sv-SE',
    };
    return languageMap[language] ?? 'en-US';
  }

  /// Obtient les messages audio pour une langue
  Future<Map<String, String>> _getAudioMessages(String language) async {
    // Créer un objet Locale à partir du code langue (ex. 'fr' → Locale('fr'))
    final locale = Locale(language);

    // Charger la localisation correspondante sans passer par un BuildContext
    final l10n = await AppLocalizations.delegate.load(locale);

    // Retourner un dictionnaire où les clés sont vos identifiants de messages
    // et les valeurs les textes localisés provenant des .arb
    return {
      'audioGameStarted': l10n.audioGameStarted,
      'audioGameEnded': l10n.audioGameEnded,
      // Ajoutez ici d'autres entrées si vous étendez l'audio à d'autres événements.
    };
  }

  /// Joue un message audio
  Future<void> playMessage(String messageKey, {Map<String, String>? parameters}) async {
    if (!_isInitialized) await initialize();
    if (!_isEnabled) return;

    try {
      // Obtenir le texte du message
      final messageText = _getMessageText(messageKey, parameters);
      if (messageText == null) {
        logger.w('⚠️ [SimpleVoiceService] Message non trouvé: $messageKey');
        return;
      }

      // Configurer la langue TTS
      final ttsLanguage = _getTTSLanguageCode(_audioLanguage);
      await _flutterTts.setLanguage(ttsLanguage);

      // Jouer le message
      logger.d('🔊 [SimpleVoiceService] Lecture: $messageText');
      await _flutterTts.speak(messageText);
    } catch (e) {
      logger.e('❌ [SimpleVoiceService] Erreur lecture message $messageKey: $e');
    }
  }

  /// Obtient le texte d'un message avec paramètres
  String? _getMessageText(String messageKey, Map<String, String>? parameters) {
    final languageCache = _audioCache[_audioLanguage];
    if (languageCache == null) return null;

    String? messageText = languageCache[messageKey];
    if (messageText == null) return null;

    // Remplacer les paramètres
    if (parameters != null) {
      for (final entry in parameters.entries) {
        messageText = messageText!.replaceAll('{${entry.key}}', entry.value);
      }
    }

    return messageText;
  }

  /// Définit le volume audio
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) return;

    _volume = volume;
    await _flutterTts.setVolume(_volume);
    await _savePreferences();
    notifyListeners();
    logger.d('🔊 [SimpleVoiceService] Volume: $_volume');
  }

  /// Active/désactive le service audio
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _savePreferences();
    notifyListeners();

    if (!enabled && _isPlaying) {
      await _flutterTts.stop();
    }

    logger.d('🔊 [SimpleVoiceService] Service ${enabled ? 'activé' : 'désactivé'}');
  }

  /// Définit la langue audio
  Future<void> setAudioLanguage(String language) async {
    if (_audioLanguage == language) return;

    _audioLanguage = language;
    await _savePreferences();
    
    // S'assurer que les fichiers sont générés pour cette langue
    await _ensureAudioFilesGenerated(language);
    
    notifyListeners();
    logger.d('🌍 [SimpleVoiceService] Langue audio: $language');
  }

  /// Arrête la lecture en cours
  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
    notifyListeners();
  }

  /// Obtient les langues disponibles
  List<String> getAvailableLanguages() {
    return ['fr', 'en', 'de', 'es', 'it', 'ja', 'nl', 'no', 'pl', 'pt', 'sv'];
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}

