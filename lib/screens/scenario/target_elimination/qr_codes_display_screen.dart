import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../models/scenario/target_elimination/player_target.dart';

class QRCodesDisplayScreen extends StatefulWidget {
  final List<PlayerTarget> playerTargets;
  final String scenarioTitle;

  const QRCodesDisplayScreen({
    Key? key,
    required this.playerTargets,
    required this.scenarioTitle,
  }) : super(key: key);

  @override
  State<QRCodesDisplayScreen> createState() => _QRCodesDisplayScreenState();
}

class _QRCodesDisplayScreenState extends State<QRCodesDisplayScreen> {
  bool _isGeneratingPDF = false;
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('QR Codes - ${widget.scenarioTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _isGeneratingPDF ? null : _generatePDF,
            tooltip: l10n.downloadPDF,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareQRCodes,
            tooltip: l10n.shareQRCodes,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _isGeneratingPDF ? null : _printQRCodes,
            tooltip: l10n.printQRCodes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Informations générales
          _buildHeader(context),
          
          // Liste des QR codes
          Expanded(
            child: _buildQRCodesList(context),
          ),
          
          // Actions en bas
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.qr_code,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'QR Codes générés',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.playerTargets.length} codes générés pour le scénario "${widget.scenarioTitle}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatChip(context, 'Total', widget.playerTargets.length.toString()),
                const SizedBox(width: 8),
                _buildStatChip(context, 'Actifs', 
                  widget.playerTargets.where((t) => t.active).length.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildQRCodesList(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: widget.playerTargets.length,
      itemBuilder: (context, index) {
        final target = widget.playerTargets[index];
        return _buildQRCodeCard(context, target, index);
      },
    );
  }

  Widget _buildQRCodeCard(BuildContext context, PlayerTarget target, int index) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedIndex = isSelected ? -1 : index;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // En-tête avec numéro
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        target.targetNumber.toString(),
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () => _copyQRCode(target.qrCode),
                    tooltip: 'Copier',
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // QR Code
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: target.qrCode,
                    version: QrVersions.auto,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Informations du joueur
              if (target.playerName != null) ...[
                Text(
                  target.playerName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              if (target.teamName != null) ...[
                Text(
                  target.teamName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Code court
              Text(
                'ID: ${target.qrCode.split('_').last.substring(0, 6)}...',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isGeneratingPDF ? null : _generatePDF,
              icon: _isGeneratingPDF 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
              label: Text(_isGeneratingPDF ? 'Génération...' : l10n.downloadPDF),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isGeneratingPDF ? null : _printQRCodes,
              icon: const Icon(Icons.print),
              label: Text(l10n.printQRCodes),
            ),
          ),
        ],
      ),
    );
  }

  void _copyQRCode(String qrCode) {
    Clipboard.setData(ClipboardData(text: qrCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code QR copié'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _generatePDF() async {
    setState(() => _isGeneratingPDF = true);
    
    try {
      final pdf = pw.Document();
      
      // Créer les pages avec grille de QR codes
      const qrPerPage = 12; // 3x4 grille
      final pageCount = (widget.playerTargets.length / qrPerPage).ceil();
      
      for (int page = 0; page < pageCount; page++) {
        final startIndex = page * qrPerPage;
        final endIndex = (startIndex + qrPerPage).clamp(0, widget.playerTargets.length);
        final pageTargets = widget.playerTargets.sublist(startIndex, endIndex);
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                children: [
                  // En-tête
                  pw.Header(
                    level: 0,
                    child: pw.Text(
                      '${widget.scenarioTitle} - QR Codes (Page ${page + 1}/$pageCount)',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  
                  pw.SizedBox(height: 20),
                  
                  // Grille de QR codes
                  pw.Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: pageTargets.map((target) {
                      return pw.Container(
                        width: 180,
                        height: 200,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          children: [
                            // Numéro
                            pw.Container(
                              width: 30,
                              height: 30,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.red,
                                borderRadius: pw.BorderRadius.circular(15),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  target.targetNumber.toString(),
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            
                            pw.SizedBox(height: 8),
                            
                            // QR Code
                            pw.Expanded(
                              child: pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: target.qrCode,
                              ),
                            ),
                            
                            pw.SizedBox(height: 8),
                            
                            // Nom du joueur
                            if (target.playerName != null)
                              pw.Text(
                                target.playerName!,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            
                            // Code court
                            pw.Text(
                              'ID: ${target.qrCode.split('_').last.substring(0, 8)}',
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        );
      }
      
      // Sauvegarder et partager
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'qr_codes_${widget.scenarioTitle.replaceAll(' ', '_')}.pdf',
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la génération du PDF: $e')),
      );
    } finally {
      setState(() => _isGeneratingPDF = false);
    }
  }

  Future<void> _printQRCodes() async {
    await _generatePDF(); // Utilise la même logique que le PDF
  }

  void _shareQRCodes() {
    final qrCodes = widget.playerTargets
        .map((t) => 'Cible #${t.targetNumber}: ${t.qrCode}')
        .join('\n');
    
    Share.share(
      'QR Codes - ${widget.scenarioTitle}\n\n$qrCodes',
      subject: 'QR Codes ${widget.scenarioTitle}',
    );
  }
}

