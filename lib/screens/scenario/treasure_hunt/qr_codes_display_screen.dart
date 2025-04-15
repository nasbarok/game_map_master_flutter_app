import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:archive/archive_io.dart';

class QRCodesDisplayScreen extends StatefulWidget {
  final List<Map<String, dynamic>> qrCodes;
  final String scenarioName;

  const QRCodesDisplayScreen({
    Key? key,
    required this.qrCodes,
    required this.scenarioName,
  }) : super(key: key);

  @override
  _QRCodesDisplayScreenState createState() => _QRCodesDisplayScreenState();
}

class _QRCodesDisplayScreenState extends State<QRCodesDisplayScreen> {
  bool _isProcessing = false;


  Future<void> _shareQRCodes() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final directory = await getTemporaryDirectory();
      final qrCodesDir = await Directory('${directory.path}/qrcodes').create(recursive: true);

      List<String> filePaths = [];

      for (int i = 0; i < widget.qrCodes.length; i++) {
        final qrCode = widget.qrCodes[i];
        if (qrCode['qrCodeImage'] != null) {
          final bytes = base64Decode(qrCode['qrCodeImage']);
          final file = File('${qrCodesDir.path}/qrcode_${i + 1}.png');
          await file.writeAsBytes(bytes);
          filePaths.add(file.path);
        }
      }

      if (filePaths.isNotEmpty) {
        await Share.shareFiles(
          filePaths,
          text: 'QR Codes pour ${widget.scenarioName}',
        );
      } else {
        _showMessage('Aucun QR code à partager');
      }
    } catch (e) {
      _showMessage('Erreur lors du partage: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<Uint8List> _generatePdfBytes() async {
    final pdf = pw.Document();
    final emojiFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansSymbols2-Regular.ttf'));
    final ttf = await PdfGoogleFonts.notoSansRegular();
    final boldTtf = await PdfGoogleFonts.notoSansBold();

    const int columns = 2;
    const int rows = 3;
    const int qrCodesPerPage = columns * rows;

    for (int pageStart = 0; pageStart < widget.qrCodes.length; pageStart += qrCodesPerPage) {
      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.GridView(
              crossAxisCount: columns,
              childAspectRatio: 0.8,
              children: List.generate(
                (pageStart + qrCodesPerPage > widget.qrCodes.length)
                    ? widget.qrCodes.length - pageStart
                    : qrCodesPerPage,
                    (index) {
                  final qrCode = widget.qrCodes[pageStart + index];
                  final imageBytes = base64Decode(qrCode['qrCodeImage']);
                  final image = pw.MemoryImage(imageBytes);

                  final symbol = qrCode['symbol'] ?? '💰';

                  return pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        qrCode['name'] ?? 'Trésor',
                        style: pw.TextStyle(fontSize: 14, font: boldTtf),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Image(image, width: 120, height: 120),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        '${qrCode['points']} ${symbol}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          font: ttf,
                          color: PdfColors.green900,
                          fontFallback: [emojiFont], // Ici on fallback sur la font locale
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }



  Future<void> _printQRCodesPreview() async {
    final pdfBytes = await _generatePdfBytes();

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  Future<void> _printDirectly() async {
    final printer = await Printing.pickPrinter(context: context);
    if (printer == null) {
      // L'utilisateur a annulé la sélection d'imprimante
      return;
    }

    final pdfBytes = await _generatePdfBytes();

    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }


  Future<void> _downloadAllAsZip() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final encoder = ZipFileEncoder();
      final directory = await getTemporaryDirectory();
      final zipPath = '${directory.path}/qrcodes.zip';
      encoder.create(zipPath);

      for (int i = 0; i < widget.qrCodes.length; i++) {
        final qrCode = widget.qrCodes[i];
        if (qrCode['qrCodeImage'] != null) {
          final bytes = base64Decode(qrCode['qrCodeImage']);
          final tempFile = File('${directory.path}/qrcode_${i + 1}.png');
          await tempFile.writeAsBytes(bytes);
          encoder.addFile(tempFile);
        }
      }

      encoder.close();

      await Share.shareXFiles([XFile(zipPath)], text: 'QR Codes (zip) pour ${widget.scenarioName}');
    } catch (e) {
      _showMessage('Erreur lors de la création du ZIP: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Codes - ${widget.scenarioName}'),
        actions: [
          IconButton(
            icon: _isProcessing
                ? CircularProgressIndicator(color: Colors.white)
                : Icon(Icons.picture_as_pdf),
            onPressed: _isProcessing
                ? null
                : () async {
              if (Platform.isAndroid || Platform.isIOS) {
                await _printQRCodesPreview();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Impression non disponible sur cette plateforme')),
                );
              }
            },
            tooltip: 'Imprimer',
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: _isProcessing ? null : _printDirectly,
            tooltip: 'Impression directe',
          ),
          IconButton(
            icon: Icon(Icons.archive),
            onPressed: _isProcessing ? null : _downloadAllAsZip,
            tooltip: 'Télécharger ZIP',
          ),
          IconButton(
            icon: _isProcessing
                ? CircularProgressIndicator(color: Colors.white)
                : Icon(Icons.share),
            onPressed: _isProcessing ? null : _shareQRCodes,
            tooltip: 'Partager',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QR Codes pour ${widget.scenarioName}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Imprimez, téléchargez ou partagez ces QR codes pour votre chasse au trésor.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: widget.qrCodes.length,
              itemBuilder: (context, index) {
                final qrCode = widget.qrCodes[index];
                return Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(
                          qrCode['name'] ?? 'Trésor ${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${qrCode['points']}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              qrCode['symbol'] ?? '💰',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: qrCode['qrCodeImage'] != null
                              ? Image.memory(
                            base64Decode(qrCode['qrCodeImage']),
                            fit: BoxFit.contain,
                          )
                              : Center(
                            child: Icon(
                              Icons.qr_code,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
