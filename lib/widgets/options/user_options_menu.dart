import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/user.dart';
import '../../services/audio/simple_voice_service.dart';
import '../../services/auth_service.dart';
import '../../services/l10n/locale_service.dart';

/// Menu d'options générales utilisateur accessible via le logo croppé
class UserOptionsMenu extends StatefulWidget {
  @override
  _UserOptionsMenuState createState() => _UserOptionsMenuState();
}

class _UserOptionsMenuState extends State<UserOptionsMenu> {
  SimpleVoiceService? _voiceService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      _voiceService = GetIt.I<SimpleVoiceService>();
      await _voiceService!.initialize();
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('❌ Erreur initialisation UserOptionsMenu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.white),
            SizedBox(width: 8),
            Text(
              l10n.optionsTitle,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Carte utilisateur
            _buildUserCard(context, l10n),

            SizedBox(height: 20),

            // Section Langue de l'application
            _buildAppLanguageCard(context, l10n),

            SizedBox(height: 20),

            // Section Audio
            if (_isInitialized && _voiceService != null)
              _buildAudioCard(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AppLocalizations l10n) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;

        if (user == null) {
          return Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.account_circle, size: 50, color: Colors.grey),
                  SizedBox(width: 16),
                  Text(
                    l10n.userNotConnected,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        _getInitials(user),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (user.firstName != null || user.lastName != null)
                            Text(
                              '${user.firstName ?? ''} ${user.lastName ?? ''}'
                                  .trim(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (user.phoneNumber != null) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        user.phoneNumber!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
                if (user.roles.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: user.roles.map((role) {
                      return Chip(
                        label: Text(
                          _formatRole(role),
                          style: TextStyle(fontSize: 12),
                        ),
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.1),
                        side: BorderSide(color: Theme.of(context).primaryColor),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppLanguageCard(BuildContext context, AppLocalizations l10n) {
    return Consumer<LocaleService>(
      builder: (context, localeService, child) {
        return Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appLanguageTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<Locale>(
                  value: localeService.currentLocale,
                  decoration: InputDecoration(
                    labelText: l10n.interfaceLanguageLabel,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.language),
                  ),
                  items: AppConfig.supportedLocales.map((locale) {
                    return DropdownMenuItem(
                      value: locale,
                      child: Row(
                        children: [
                          Text(AppConfig.getLanguageFlag(locale)),
                          SizedBox(width: 8),
                          Text(AppConfig.getLanguageName(locale)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      await localeService.setLocale(value);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioCard(BuildContext context, AppLocalizations l10n) {
    return ChangeNotifierProvider.value(
      value: _voiceService!,
      child: Consumer<SimpleVoiceService>(
        builder: (context, voiceService, child) {
          return Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.audioNotificationsTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Activation/Désactivation
                  SwitchListTile(
                    title: Text(l10n.enableAudioNotifications),
                    value: voiceService.isEnabled,
                    onChanged: (value) async {
                      await voiceService.setEnabled(value);
                    },
                    activeColor: Theme.of(context).primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),

                  if (voiceService.isEnabled) ...[
                    SizedBox(height: 16),

                    // Volume
                    Text(
                      l10n.volumeLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.volume_down),
                        Expanded(
                          child: Slider(
                            value: voiceService.volume,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            label: '${(voiceService.volume * 100).round()}%',
                            onChanged: (value) async {
                              await voiceService.setVolume(value);
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ),
                        Icon(Icons.volume_up),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Langue des notifications
                    DropdownButtonFormField<String>(
                      value: voiceService.audioLanguage,
                      decoration: InputDecoration(
                        labelText: l10n.audioLanguageLabel,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.record_voice_over),
                      ),
                      items:
                          voiceService.getAvailableLanguages().map((language) {
                        return DropdownMenuItem(
                          value: language,
                          child: Row(
                            children: [
                              Text(_getLanguageFlag(language)),
                              SizedBox(width: 8),
                              Text(_getLanguageName(language)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        if (value != null) {
                          await voiceService.setAudioLanguage(value);
                        }
                      },
                    ),

                    SizedBox(height: 16),

                    // Titre des tests
                    Text(
                      l10n.audioTestsTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),

                    // Tests
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: !voiceService.isPlaying
                                ? () async {
                                    await voiceService
                                        .playMessage('audioGameStarted');
                                  }
                                : null,
                            icon: Icon(Icons.play_arrow),
                            label: Text(l10n.testStartButton),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: !voiceService.isPlaying
                                ? () async {
                                    await voiceService
                                        .playMessage('audioGameEnded');
                                  }
                                : null,
                            icon: Icon(Icons.stop),
                            label: Text(l10n.testEndButton),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (voiceService.isPlaying) ...[
                      SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(l10n.playingStatus),
                          Spacer(),
                          TextButton(
                            onPressed: () async {
                              await voiceService.stop();
                            },
                            child: Text(l10n.stopButton),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getInitials(User user) {
    String initials = '';
    if (user.firstName != null && user.firstName!.isNotEmpty) {
      initials += user.firstName![0].toUpperCase();
    }
    if (user.lastName != null && user.lastName!.isNotEmpty) {
      initials += user.lastName![0].toUpperCase();
    }
    if (initials.isEmpty) {
      initials = user.username[0].toUpperCase();
    }
    return initials;
  }

  String _formatRole(String role) {
    // Enlever le préfixe ROLE_ s'il existe
    String cleanRole = role.replaceFirst('ROLE_', '');
    // Capitaliser la première lettre
    return cleanRole[0].toUpperCase() + cleanRole.substring(1).toLowerCase();
  }

  String _getLanguageName(String languageCode) {
    const languageNames = {
      'fr': 'Français',
      'en': 'English',
      'de': 'Deutsch',
      'es': 'Español',
      'it': 'Italiano',
      'ja': '日本語',
      'nl': 'Nederlands',
      'no': 'Norsk',
      'pl': 'Polski',
      'pt': 'Português',
      'sv': 'Svenska',
    };
    return languageNames[languageCode] ?? languageCode.toUpperCase();
  }

  String _getLanguageFlag(String languageCode) {
    const languageFlags = {
      'fr': '🇫🇷',
      'en': '🇺🇸',
      'de': '🇩🇪',
      'es': '🇪🇸',
      'it': '🇮🇹',
      'ja': '🇯🇵',
      'nl': '🇳🇱',
      'no': '🇳🇴',
      'pl': '🇵🇱',
      'pt': '🇵🇹',
      'sv': '🇸🇪',
    };
    return languageFlags[languageCode] ?? '🌐';
  }
}
