import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import ' treasure_popup.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../services/api_service.dart';
import '../../../services/game_state_service.dart';

class TreasureHuntScannerScreen extends StatefulWidget {
  final int userId;
  final int? teamId;
  final int treasureHuntId;
  final int gameSessionId;

  const TreasureHuntScannerScreen({
    Key? key,
    required this.userId,
    this.teamId,
    required this.treasureHuntId,
    required this.gameSessionId,
  }) : super(key: key);

  @override
  State<TreasureHuntScannerScreen> createState() => _TreasureHuntScannerScreenState();
}

class _TreasureHuntScannerScreenState extends State<TreasureHuntScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _controller?.pauseCamera();
    }
    _controller?.resumeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      final code = scanData.code;
      if (code == null || _isProcessing) return;

      final now = DateTime.now();
      if (_lastScannedCode == code &&
          _lastScanTime != null &&
          now.difference(_lastScanTime!).inSeconds < 3) {
        return;
      }

      _lastScannedCode = code;
      _lastScanTime = now;

      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      _controller?.pauseCamera();

      try {
        final apiService = GetIt.I<ApiService>();
        final response = await apiService.post('scenarios/treasure-hunt/scan', {
          'qrCode': code,
          'teamId': widget.teamId,
          'gameSessionId':  widget.gameSessionId,//
        });
        final success = response['success'] == true;

        if (success) {
          final points = response['points'] ?? 0;
          final symbol = response['symbol'] ?? '🏆';
          final treasureName = response['treasureName'] ?? 'Trésor';

          if (mounted) {
            // 🎉 Affichage de l'animation personnalisée
            showTreasurePopup(
              context: context,
              symbol: symbol,
              treasureName: treasureName,
              points: points,
            );

            // Attendre que l'animation soit visible 2 secondes avant de quitter l'écran
            await Future.delayed(Duration(seconds: 2));
            Navigator.of(context).pop(true);
          }
        } else {
          final error = response['error'] ?? 'Erreur inconnue';
          if (mounted) {
            setState(() {
              _errorMessage = error;
              _isProcessing = false;
            });
            _controller?.resumeCamera();
          }
        }
      } catch (e) {
          final l10n = AppLocalizations.of(context)!;
        if (mounted) {
          setState(() {
              _errorMessage = l10n.scanError(e.toString()); // Assumes a generic scan error or connection error
            _isProcessing = false;
          });
          _controller?.resumeCamera();
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
          title: Text(l10n.scanQRCodeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
              tooltip: l10n.toggleFlash, // Assuming 'toggleFlash' key exists
            onPressed: () async {
              await _controller?.toggleFlash();
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
              tooltip: l10n.switchCamera, // Assuming 'switchCamera' key exists
            onPressed: () async {
              await _controller?.flipCamera();
            },
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.green,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 250,
            ),
          ),
          if (_isProcessing)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (_errorMessage != null)
            Positioned(
              bottom: 50,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isProcessing = false;
                          _lastScannedCode = null;
                          _lastScanTime = null;
                        });
                        _controller?.resumeCamera();
                      },
                        child: Text(l10n.retryButton),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
