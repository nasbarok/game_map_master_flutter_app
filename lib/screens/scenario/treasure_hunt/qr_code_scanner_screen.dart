import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../../../services/game_state_service.dart';
import '../../../services/scenario/treasure_hunt/treasure_hunt_service.dart';

class QRCodeScannerScreen extends StatefulWidget {
  final int scenarioId;
  final int? teamId;

  const QRCodeScannerScreen({
    Key? key,
    required this.scenarioId,
    this.teamId,
  }) : super(key: key);

  @override
  _QRCodeScannerScreenState createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;
  bool _scanSuccess = false;
  String? _errorMessage;
  Map<String, dynamic>? _scanResult;

  // Pour éviter de scanner plusieurs fois le même QR code
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_isProcessing) return;

      // Vérifier si c'est le même QR code que celui scanné récemment
      if (_lastScannedCode == scanData.code && _lastScanTime != null) {
        final now = DateTime.now();
        final difference = now.difference(_lastScanTime!);
        if (difference.inSeconds < 3) {
          // Ignorer les scans répétés dans un court laps de temps
          return;
        }
      }

      _lastScannedCode = scanData.code;
      _lastScanTime = DateTime.now();

      _processQRCode(scanData.code);
    });
  }

  Future<void> _processQRCode(String? qrCode) async {
    if (qrCode == null || qrCode.isEmpty) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _scanSuccess = false;
      _errorMessage = null;
      _scanResult = null;
    });

    try {
      final gameStateService = Provider.of<GameStateService>(context, listen: false);

      // Vérifier si la partie est active
      if (!await gameStateService.isGameActive(widget.scenarioId)) {
        setState(() {
          _isProcessing = false;
          _scanSuccess = false;
          _errorMessage = 'La partie n\'est pas active';
        });
        return;
      }

      final treasureHuntService = Provider.of<TreasureHuntService>(context, listen: false);
      final result = await treasureHuntService.scanQRCode(qrCode, widget.teamId);

      setState(() {
        _isProcessing = false;
        _scanSuccess = result['success'] == true;
        _errorMessage = result['success'] == true ? null : result['error'];
        _scanResult = result;
      });

      // Pause brève pour montrer le résultat
      await Future.delayed(Duration(seconds: 2));

      if (_scanSuccess) {
        // Reprendre le scan après un succès
        setState(() {
          _scanSuccess = false;
          _scanResult = null;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _scanSuccess = false;
        _errorMessage = 'Erreur lors du scan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner un QR code'),
      ),
      body: Stack(
        children: [
          // Scanner QR
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.blue,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
          ),

          // Indicateur de traitement
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Résultat du scan
          if (_scanSuccess && _scanResult != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: EdgeInsets.all(32),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Trésor trouvé !',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _scanResult!['treasureName'] ?? 'Trésor',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '+${_scanResult!['points']} points',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              _scanResult!['symbol'] ?? '💰',
                              style: TextStyle(fontSize: 24),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Score total: ${_scanResult!['currentScore']} points',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Message d'erreur
          if (_errorMessage != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: EdgeInsets.all(32),
                  color: Colors.red[100],
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Erreur',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                            });
                          },
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
