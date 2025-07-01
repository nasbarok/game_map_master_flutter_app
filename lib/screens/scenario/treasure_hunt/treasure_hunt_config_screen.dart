import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../models/scenario/treasure_hunt/treasure_hunt_scenario.dart';
import '../../../services/scenario/treasure_hunt/treasure_hunt_service.dart';
import 'treasure_list_screen.dart';

class TreasureHuntConfigScreen extends StatefulWidget {
  final int scenarioId;
  final String scenarioName;

  const TreasureHuntConfigScreen({
    Key? key,
    required this.scenarioId,
    required this.scenarioName,
  }) : super(key: key);

  @override
  _TreasureHuntConfigScreenState createState() => _TreasureHuntConfigScreenState();
}

class _TreasureHuntConfigScreenState extends State<TreasureHuntConfigScreen> {
  bool _isLoading = true;
  bool _isCreating = false;
  String? _errorMessage;
  TreasureHuntScenario? _scenario;

  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController(text: '10');
  final _valueController = TextEditingController(text: '50');

  String _selectedSymbol = '💰';
  final List<String> _availableSymbols = [
    "💰", "💎", "🏆", "🔑", "📦", "💲",
    "💣", "🎯", "🧨", "🚩", "🔫", "🥇",
    "🥈", "🥉", "🏅", "🎖️", "🎁", "⭐", "🌟", "💵",
  ];

  String _size = 'SMALL';

  @override
  void initState() {
    super.initState();
    _loadScenario();
  }

  @override
  void dispose() {
    _countController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _loadScenario() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final treasureHuntService = Provider.of<TreasureHuntService>(context, listen: false);

      // 👉 On utilise maintenant "ensureTreasureHuntScenario"
      final scenario = await treasureHuntService.ensureTreasureHuntScenario(widget.scenarioId);

      setState(() {
        _scenario = scenario;
        _isLoading = false;

        // Pré-remplir les champs même si c'est un nouveau vide
        _countController.text = scenario.totalTreasures > 0 ? scenario.totalTreasures.toString() : '10';
        _valueController.text = scenario.defaultValue.toString();
        _selectedSymbol = scenario.defaultSymbol;
        _size = scenario.size;
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.errorLoadingTreasureHuntScenario(e.toString());
        _isLoading = false;
      });
    }
  }


  Future<void> _createTreasures() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final treasureHuntService = Provider.of<TreasureHuntService>(context, listen: false);

      final count = int.parse(_countController.text);
      final value = int.parse(_valueController.text);

      await treasureHuntService.createTreasuresBatch(
        _scenario!.id,
        count,
        value,
        _selectedSymbol,
      );

      setState(() {
        _isCreating = false;
      });

      // On attend que l'utilisateur revienne de TreasureListScreen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TreasureListScreen(
            treasureHuntId: _scenario!.id,
            scenarioName: widget.scenarioName,
          ),
        ),
      );

      // 🔄 Et après son retour : recharger le scénario
      if (result == true) {
        _loadScenario();
      }
    } catch (e) {
      setState(() {
        _errorMessage = l10n.errorCreatingTreasures(e.toString());
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.treasureHuntConfigTitle(widget.scenarioName)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadScenario,
              child: Text(l10n.retryButton),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.treasureHuntSetupTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _countController,
                        decoration: InputDecoration(
                          labelText: l10n.numberOfQRCodesLabel,
                          border: const OutlineInputBorder(),
                          helperText: l10n.qrCodeCountHelperText,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.numberRequiredError;
                          }
                          final count = int.tryParse(value);
                          if (count == null) {
                            return l10n.invalidNumberError;
                          }
                          if (count < 1 || count > 50) {
                            return l10n.qrCodeCountRangeError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _valueController,
                        decoration: InputDecoration(
                          labelText: l10n.defaultValuePointsLabel,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.valueRequiredError;
                          }
                          if (int.tryParse(value) == null) {
                            return l10n.invalidNumberError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.defaultSymbolLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _availableSymbols.map((symbol) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedSymbol = symbol;
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _selectedSymbol == symbol
                                    ? Colors.blue[100]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedSymbol == symbol
                                      ? Colors.blue
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  symbol,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isCreating ? null : _createTreasures,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCreating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  l10n.generateQRCodesButton,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              if (_scenario != null && _scenario!.totalTreasures > 0) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TreasureListScreen(
                          treasureHuntId: _scenario!.id,
                          scenarioName: widget.scenarioName,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    l10n.viewExistingTreasuresButton(_scenario!.totalTreasures.toString()),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
