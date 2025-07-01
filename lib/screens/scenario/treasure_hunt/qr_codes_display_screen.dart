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

import '../../../generated/l10n/app_localizations.dart';

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

      final l10n = AppLocalizations.of(context)!;
      if (filePaths.isNotEmpty) {
        await Share.shareFiles(
          filePaths,
          text: l10n.qrCodesForScenarioShareText(widget.scenarioName),
        );
      } else {
        _showMessage(l10n.noQRCodesToShareError);
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      _showMessage(l10n.sharingError(e.toString()));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<Uint8List> _generatePdfBytes() async {
    final l10n = AppLocalizations.of(context)!;
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
                        qrCode['name'] ?? l10n.defaultTreasureName,
                        style: pw.TextStyle(fontSize: 14, font: boldTtf),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Image(image, width: 120, height: 120),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        l10n.pointsSuffix((qrCode['points'] ?? 0).toString()) + " " + symbol,
                        style: pw.TextStyle(
                          fontSize: 12,
                          font: ttf,
                          color: PdfColors.green900,
                          fontFallback: [emojiFont],
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
    final l10n = AppLocalizations.of(context)!;
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

      await Share.shareXFiles([XFile(zipPath)], text: l10n.qrCodesForScenarioShareText(widget.scenarioName));
    } catch (e) {
      _showMessage(l10n.zipCreationError(e.toString()));
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.qrCodesScreenTitle(widget.scenarioName)),
        actions: [
          IconButton(
            icon: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.picture_as_pdf),
            onPressed: _isProcessing
                ? null
                : () async {
              if (Platform.isAndroid || Platform.isIOS) {
                await _printQRCodesPreview();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.printingNotAvailableError)),
                );
              }
            },
            tooltip: l10n.printButton,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _isProcessing ? null : _printDirectly,
            tooltip: l10n.directPrintButton,
          ),
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: _isProcessing ? null : _downloadAllAsZip,
            tooltip: l10n.downloadZipButton,
          ),
          IconButton(
            icon: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.share),
            onPressed: _isProcessing ? null : _shareQRCodes,
            tooltip: l10n.shareButton,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.qrCodesForScenarioShareText(widget.scenarioName),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.qrCodesDisplayInstructions,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(
                          qrCode['name'] ?? l10n.defaultTreasureNameIndexed((index + 1).toString()),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (qrCode['points'] ?? 0).toString(),
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              qrCode['symbol'] ?? '💰',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: qrCode['qrCodeImage'] != null
                              ? Image.memory(
                            base64Decode(qrCode['qrCodeImage']),
                            fit: BoxFit.contain,
                          )
                              : const Center(
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
