import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../services/audio/simple_voice_service.dart';

/// Menu d'options audio accessible via le logo croppé
class AudioOptionsMenu extends StatefulWidget {
  @override
  _AudioOptionsMenuState createState() => _AudioOptionsMenuState();
}

class _AudioOptionsMenuState extends State<AudioOptionsMenu> {
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
      debugPrint('❌ Erreur initialisation AudioOptionsMenu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_isInitialized || _voiceService == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.sound),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider.value(
      value: _voiceService!,
      child: Consumer<SimpleVoiceService>(
        builder: (context, voiceService, child) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            appBar: AppBar(
              title: Row(
                children: [
                  Icon(Icons.volume_up, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    l10n.sound,
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
                  // Section État du service
                  _buildServiceStatusCard(voiceService, l10n),
                  
                  SizedBox(height: 20),
                  
                  // Section Paramètres généraux
                  _buildGeneralSettingsCard(voiceService, l10n),
                  
                  SizedBox(height: 20),
                  
                  // Section Langue audio
                  _buildLanguageSettingsCard(voiceService, l10n),
                  
                  SizedBox(height: 20),
                  
                  // Section Tests
                  _buildTestCard(voiceService, l10n),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceStatusCard(SimpleVoiceService voiceService, AppLocalizations l10n) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  voiceService.isEnabled ? Icons.check_circle : Icons.cancel,
                  color: voiceService.isEnabled ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  'État du Service Audio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildStatusRow('Statut', voiceService.isEnabled ? 'Activé' : 'Désactivé'),
            _buildStatusRow('Langue audio', _getLanguageName(voiceService.audioLanguage)),
            _buildStatusRow('Volume', '${(voiceService.volume * 100).round()}%'),
            _buildStatusRow('En lecture', voiceService.isPlaying ? 'Oui' : 'Non'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettingsCard(SimpleVoiceService voiceService, AppLocalizations l10n) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres Généraux',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Activation/Désactivation
            SwitchListTile(
              title: Text('Activer les notifications audio'),
              subtitle: Text('Active ou désactive toutes les notifications vocales'),
              value: voiceService.isEnabled,
              onChanged: (value) async {
                await voiceService.setEnabled(value);
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            
            Divider(),
            
            // Volume
            ListTile(
              title: Text('Volume'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ajustez le volume des notifications audio'),
                  SizedBox(height: 8),
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
                          onChanged: voiceService.isEnabled ? (value) async {
                            await voiceService.setVolume(value);
                          } : null,
                          activeColor: Theme.of(context).primaryColor,
                        ),
                      ),
                      Icon(Icons.volume_up),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSettingsCard(SimpleVoiceService voiceService, AppLocalizations l10n) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Langue Audio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Choisissez la langue des notifications audio (indépendante de la langue de l\'application)',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: voiceService.audioLanguage,
              decoration: InputDecoration(
                labelText: 'Langue des notifications',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
              items: voiceService.getAvailableLanguages().map((language) {
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
              onChanged: voiceService.isEnabled ? (value) async {
                if (value != null) {
                  await voiceService.setAudioLanguage(value);
                }
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(SimpleVoiceService voiceService, AppLocalizations l10n) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tests Audio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Testez les différents types de notifications audio',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: voiceService.isEnabled && !voiceService.isPlaying ? () async {
                      await voiceService.playMessage('game_started');
                    } : null,
                    icon: Icon(Icons.play_arrow),
                    label: Text('Début de Partie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: voiceService.isEnabled && !voiceService.isPlaying ? () async {
                      await voiceService.playMessage('game_ended');
                    } : null,
                    icon: Icon(Icons.stop),
                    label: Text('Fin de Partie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            if (voiceService.isPlaying)
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Lecture en cours...'),
                  Spacer(),
                  TextButton(
                    onPressed: () async {
                      await voiceService.stop();
                    },
                    child: Text('Arrêter'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
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

