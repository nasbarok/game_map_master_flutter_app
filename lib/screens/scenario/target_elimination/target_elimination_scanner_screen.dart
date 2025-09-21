import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../services/scenario/target_elimination/target_elimination_service.dart';
import '../../../models/scenario/target_elimination/elimination.dart';
import '../../../models/scenario/target_elimination/player_target.dart';

class TargetEliminationScannerScreen extends StatefulWidget {
  final int scenarioId;
  final int gameSessionId;
  final int currentPlayerId;

  const TargetEliminationScannerScreen({
    Key? key,
    required this.scenarioId,
    required this.gameSessionId,
    required this.currentPlayerId,
  }) : super(key: key);

  @override
  State<TargetEliminationScannerScreen> createState() => _TargetEliminationScannerScreenState();
}

class _TargetEliminationScannerScreenState extends State<TargetEliminationScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;
  bool _flashOn = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.scanQRCode),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
            tooltip: _flashOn ? 'Éteindre le flash' : 'Allumer le flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner QR
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: theme.colorScheme.primary,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
          ),
          
          // Instructions en haut
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: _buildInstructions(context),
          ),
          
          // Actions en bas
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildBottomActions(context),
          ),
          
          // Overlay de traitement
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Traitement en cours...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      color: Colors.black.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Scanner pour éliminer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Pointez la caméra vers le QR code d\'un autre joueur',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Saisie manuelle
        FloatingActionButton.extended(
          onPressed: _isProcessing ? null : _showManualInput,
          backgroundColor: Colors.white.withOpacity(0.9),
          foregroundColor: Colors.black,
          icon: const Icon(Icons.keyboard),
          label: const Text('Saisie manuelle'),
        ),
        
        // Fermer
        FloatingActionButton(
          onPressed: () => Navigator.of(context).pop(),
          backgroundColor: Colors.red.withOpacity(0.9),
          foregroundColor: Colors.white,
          child: const Icon(Icons.close),
        ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && !_isProcessing) {
        _processQRCode(scanData.code!);
      }
    });
  }

  Future<void> _processQRCode(String qrCode) async {
    // Éviter les scans répétés du même code
    if (_lastScannedCode == qrCode && 
        _lastScanTime != null && 
        DateTime.now().difference(_lastScanTime!).inSeconds < 3) {
      return;
    }

    _lastScannedCode = qrCode;
    _lastScanTime = DateTime.now();

    setState(() => _isProcessing = true);

    try {
      // Vibration de feedback
      HapticFeedback.mediumImpact();

      final targetEliminationService = TargetEliminationService();
      
      final elimination = await targetEliminationService.processElimination(
        qrCode: qrCode,
        killerId: widget.currentPlayerId,
        gameSessionId: widget.gameSessionId,
      );

      // Succès - afficher le résultat
      await _showEliminationSuccess(elimination);
      
    } catch (e) {
      // Erreur - afficher le message
      await _showEliminationError(e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _showEliminationSuccess(Elimination elimination) async {
    final theme = Theme.of(context);
    
    // Vibration de succès
    HapticFeedback.heavyImpact();
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.primaryContainer,
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Élimination réussie !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous avez éliminé ${elimination.victimName ?? "Joueur ${elimination.victimId}"}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${elimination.points} points',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer le dialog
              Navigator.of(context).pop(); // Fermer le scanner
            },
            child: const Text('Terminer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(), // Continuer à scanner
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEliminationError(String error) async {
    final theme = Theme.of(context);
    
    // Vibration d'erreur
    HapticFeedback.lightImpact();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.errorContainer,
        title: Row(
          children: [
            Icon(
              Icons.error,
              color: theme.colorScheme.error,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Élimination impossible'),
          ],
        ),
        content: Text(
          error,
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showManualInput() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saisie manuelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez le code QR manuellement :'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Code QR',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      await _processQRCode(result);
    }
  }

  void _toggleFlash() {
    controller?.toggleFlash();
    setState(() => _flashOn = !_flashOn);
  }
}

