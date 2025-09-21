import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/scenario.dart';
import '../../../models/scenario/target_elimination/target_elimination_scenario.dart';
import '../../../services/scenario/target_elimination/target_elimination_service.dart';
import '../treasure_hunt/qr_codes_display_screen.dart';

class TargetEliminationConfigScreen extends StatefulWidget {
  final Scenario scenario;

  const TargetEliminationConfigScreen({Key? key, required this.scenario})
      : super(key: key);

  @override
  _TargetEliminationConfigScreenState createState() =>
      _TargetEliminationConfigScreenState();
}

class _TargetEliminationConfigScreenState
    extends State<TargetEliminationConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  GameMode _selectedMode = GameMode.solo;
  bool _friendlyFire = false;
  int _pointsPerElimination = 1;
  int _cooldownMinutes = 5;
  int _maxTargets = 50;
  String _announcementTemplate = '{killer} a sorti {victim}';
  List<String> _generatedQRCodes = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.targetEliminationConfig),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveConfiguration,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildRulesCard(),
            SizedBox(height: 16),
            _buildParametersCard(),
            SizedBox(height: 16),
            _buildQRGenerationCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesCard() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.gameRules,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),

            // Mode de jeu
            Text(l10n.gameMode, style: Theme.of(context).textTheme.titleMedium),
            RadioListTile<GameMode>(
              title: Text(l10n.soloMode),
              value: GameMode.solo,
              groupValue: _selectedMode,
              onChanged: (value) => setState(() => _selectedMode = value!),
            ),
            RadioListTile<GameMode>(
              title: Text(l10n.teamMode),
              value: GameMode.team,
              groupValue: _selectedMode,
              onChanged: (value) => setState(() => _selectedMode = value!),
            ),

            // Friendly Fire
            SwitchListTile(
              title: Text(l10n.friendlyFire),
              subtitle: Text(l10n.friendlyFireDescription),
              value: _friendlyFire,
              onChanged: (value) => setState(() => _friendlyFire = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersCard() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.parameters,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),

            // Points par élimination
            TextFormField(
              initialValue: _pointsPerElimination.toString(),
              decoration: InputDecoration(
                labelText: l10n.pointsPerElimination,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return l10n.fieldRequired;
                final points = int.tryParse(value);
                if (points == null || points < 1) return l10n.invalidPoints;
                return null;
              },
              onSaved: (value) => _pointsPerElimination = int.parse(value!),
            ),
            SizedBox(height: 16),

            // Cooldown d'immunité
            TextFormField(
              initialValue: _cooldownMinutes.toString(),
              decoration: InputDecoration(
                labelText: l10n.immunityCooldownMinutes,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return l10n.fieldRequired;
                final minutes = int.tryParse(value);
                if (minutes == null || minutes < 0) return l10n.invalidCooldown;
                return null;
              },
              onSaved: (value) => _cooldownMinutes = int.parse(value!),
            ),
            SizedBox(height: 16),

            // Nombre de QR à générer
            DropdownButtonFormField<int>(
              value: _maxTargets,
              decoration: InputDecoration(
                labelText: l10n.numberOfQRCodes,
                border: OutlineInputBorder(),
              ),
              items: [10, 20, 30, 50, 100].map((count) {
                return DropdownMenuItem(
                  value: count,
                  child: Text('$count QR codes'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _maxTargets = value!),
            ),
            SizedBox(height: 16),

            // Template d'annonce
            TextFormField(
              initialValue: _announcementTemplate,
              decoration: InputDecoration(
                labelText: l10n.announcementTemplate,
                border: OutlineInputBorder(),
                helperText: l10n.announcementTemplateHelp(
                  l10n.killer,
                  l10n.killerTeam,
                  l10n.victim,
                  l10n.victimTeam,
                ),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) return l10n.fieldRequired;
                return null;
              },
              onSaved: (value) => _announcementTemplate = value!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRGenerationCard() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.qrCodeGeneration,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.qr_code),
                    label: Text(l10n.generateQRCodes),
                    onPressed: _generateQRCodes,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.download),
                    label: Text(l10n.downloadPDF),
                    onPressed: _downloadPDF,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveConfiguration() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final scenario = TargetEliminationScenario(
        scenario: widget.scenario,
        mode: _selectedMode,
        friendlyFire: _friendlyFire,
        pointsPerElimination: _pointsPerElimination,
        cooldownMinutes: _cooldownMinutes,
        maxTargets: _maxTargets,
        announcementTemplate: _announcementTemplate,
      );
      final l10n = AppLocalizations.of(context)!;
      try {
        final service = context.watch<TargetEliminationService>();
        final scenario = await service.createScenario(
          gameSessionId: widget.scenario.gameSessionId!,
          isTeamMode: _selectedMode == GameMode.team,
          friendlyFire: _friendlyFire,
          pointsPerElimination: _pointsPerElimination,
          cooldownMinutes: _cooldownMinutes,
          numberOfQRCodes: _maxTargets,
          announcementTemplate: _announcementTemplate,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.configurationSaved)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSavingConfiguration)),
        );
      }
    }
  }

  void _generateQRCodes() {
    final l10n = AppLocalizations.of(context)!;
    // Navigation vers l'écran de génération des QR codes
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodesDisplayScreen(
          qrCodes: _generatedQRCodes.map((code) => {'code': code}).toList(),
          scenarioName: l10n.targetEliminationConfig,
        ),
      ),
    );
  }

  void _downloadPDF() {
    final l10n = AppLocalizations.of(context)!;

    if (_generatedQRCodes.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRCodesDisplayScreen(
            qrCodes: _generatedQRCodes.map((code) => {'code': code}).toList(),
            scenarioName: l10n.targetEliminationConfig,
          ),
        ),
      );
    }
  }
}
