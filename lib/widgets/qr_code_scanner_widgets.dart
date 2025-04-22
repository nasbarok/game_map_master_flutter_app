import 'package:flutter/material.dart';

class QRCodeScannerButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;

  const QRCodeScannerButton({
    Key? key,
    required this.onPressed,
    this.isActive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: isActive ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, size: 28),
            SizedBox(width: 12),
            Text(
              'Scanner un QR code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double cornerRadius;
  final double cornerLength;

  ScannerOverlayPainter({
    this.borderColor = Colors.green,
    this.borderWidth = 4.0,
    this.cornerRadius = 20.0,
    this.cornerLength = 30.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.width * 0.7,
    );

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Dessiner le fond semi-transparent
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final transparentPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;

    // Dessiner le fond semi-transparent avec un trou pour la zone de scan
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect);

    canvas.drawPath(path, backgroundPaint);
    canvas.drawRect(rect, transparentPaint);

    // Dessiner les coins
    // Coin supérieur gauche
    canvas.drawLine(
      rect.topLeft.translate(0, cornerRadius),
      rect.topLeft.translate(0, cornerRadius + cornerLength),
      paint,
    );
    canvas.drawLine(
      rect.topLeft.translate(cornerRadius, 0),
      rect.topLeft.translate(cornerRadius + cornerLength, 0),
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: rect.topLeft.translate(cornerRadius, cornerRadius), radius: cornerRadius),
      -Math.pi,
      -Math.pi / 2,
      false,
      paint,
    );

    // Coin supérieur droit
    canvas.drawLine(
      rect.topRight.translate(0, cornerRadius),
      rect.topRight.translate(0, cornerRadius + cornerLength),
      paint,
    );
    canvas.drawLine(
      rect.topRight.translate(-cornerRadius, 0),
      rect.topRight.translate(-cornerRadius - cornerLength, 0),
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: rect.topRight.translate(-cornerRadius, cornerRadius), radius: cornerRadius),
      -Math.pi / 2,
      -Math.pi / 2,
      false,
      paint,
    );

    // Coin inférieur gauche
    canvas.drawLine(
      rect.bottomLeft.translate(0, -cornerRadius),
      rect.bottomLeft.translate(0, -cornerRadius - cornerLength),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft.translate(cornerRadius, 0),
      rect.bottomLeft.translate(cornerRadius + cornerLength, 0),
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: rect.bottomLeft.translate(cornerRadius, -cornerRadius), radius: cornerRadius),
      Math.pi / 2,
      -Math.pi / 2,
      false,
      paint,
    );

    // Coin inférieur droit
    canvas.drawLine(
      rect.bottomRight.translate(0, -cornerRadius),
      rect.bottomRight.translate(0, -cornerRadius - cornerLength),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight.translate(-cornerRadius, 0),
      rect.bottomRight.translate(-cornerRadius - cornerLength, 0),
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: rect.bottomRight.translate(-cornerRadius, -cornerRadius), radius: cornerRadius),
      0,
      -Math.pi / 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class Math {
  static const double pi = 3.1415926535897932;
}
