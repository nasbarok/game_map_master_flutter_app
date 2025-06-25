// lib/config/environment_config.dart
class EnvironmentConfig {
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const Map<String, Map<String, String>> _configs = {
    'development': {
      'apiBaseUrl': 'http://10.0.2.2:8080/api',// URL pour l'émulateur Android
      'wsBaseUrl': 'ws://10.0.2.2:8080/ws',
      'environment': 'development',
    },
    'preprod': {
      'apiBaseUrl': 'http://95.216.156.57:8080/api',
      'wsBaseUrl': 'ws://95.216.156.57:8080/ws',
      'environment': 'preprod',
    },
    'production': {
      'apiBaseUrl': 'https://votre-domaine.com/api',
      'wsBaseUrl': 'wss://votre-domaine.com/ws',
      'environment': 'production',
    },
  };

  static Map<String, String> get currentConfig {
    return _configs[_environment] ?? _configs['development']!;
  }

  static String get apiBaseUrl => currentConfig['apiBaseUrl']!;
  static String get wsBaseUrl => currentConfig['wsBaseUrl']!;
  static String get environment => currentConfig['environment']!;

  static bool get isDevelopment => _environment == 'development';
  static bool get isPreprod => _environment == 'preprod';
  static bool get isProduction => _environment == 'production';
}