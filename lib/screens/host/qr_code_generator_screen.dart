import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';

class QRCodeGeneratorScreen extends StatefulWidget {
  final String scenarioId;
  
  const QRCodeGeneratorScreen({
    Key? key, 
    required this.scenarioId,
  }) : super(key: key);

  @override
  State<QRCodeGeneratorScreen> createState() => _QRCodeGeneratorScreenState();
}

class _QRCodeGeneratorScreenState extends State<QRCodeGeneratorScreen> {
  bool _isLoading = true;
  String? _qrData;
  String? _errorMessage;
  String _scenarioName = '';

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  Future<void> _generateQRCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = GetIt.I<ApiService>();
      
      // Récupérer les détails du scénario
      final scenarioData = await apiService.get('scenarios/${widget.scenarioId}');
      _scenarioName = scenarioData['name'] ?? 'Scénario';
      
      // Générer un code d'invitation
      final response = await apiService.post('invitations/generate', {
        'scenarioId': widget.scenarioId,
        'expiresIn': 3600 // 1 heure en secondes
      });
      
      setState(() {
        _qrData = response['invitationCode'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la génération du QR code: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code pour $_scenarioName'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _generateQRCode,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Scannez ce QR code pour rejoindre la partie',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: QrImageView(
                          data: _qrData!,
                          version: QrVersions.auto,
                          size: 250,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Code d\'invitation: $_qrData',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ce code est valide pendant 1 heure',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _generateQRCode,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Générer un nouveau code'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
