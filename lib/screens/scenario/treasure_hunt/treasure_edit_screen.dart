import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../models/scenario/treasure_hunt/treasure.dart';
import '../../../services/scenario/treasure_hunt/treasure_hunt_service.dart';

class TreasureEditScreen extends StatefulWidget {
  final Treasure treasure;

  const TreasureEditScreen({
    Key? key,
    required this.treasure,
  }) : super(key: key);

  @override
  _TreasureEditScreenState createState() => _TreasureEditScreenState();
}

class _TreasureEditScreenState extends State<TreasureEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _valueController;
  late String _selectedSymbol;

  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _availableSymbols = [
    "💰", "💎", "🏆", "🔑", "📦", "🎁", "⭐", "🌟", "💵", "💲"
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.treasure.name);
    _valueController = TextEditingController(text: widget.treasure.points.toString());
    _selectedSymbol = widget.treasure.symbol;

    // Ajouter le symbole actuel s'il n'est pas dans la liste
    if (!_availableSymbols.contains(_selectedSymbol)) {
      _availableSymbols.add(_selectedSymbol);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _saveTreasure() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final treasureHuntService = Provider.of<TreasureHuntService>(context, listen: false);

      final updatedTreasure = await treasureHuntService.updateTreasure(
        widget.treasure.id,
        _nameController.text,
        int.parse(_valueController.text),
        _selectedSymbol,
      );

      if (mounted) {
        Navigator.pop(context, updatedTreasure);
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.errorUpdatingTreasure(e.toString());
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editTreasureTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[900]),
                  ),
                ),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.treasureNameLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.nameRequiredError;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: l10n.valuePointsLabel,
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
                l10n.symbolLabel,
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

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveTreasure,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  l10n.saveChangesButton,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
