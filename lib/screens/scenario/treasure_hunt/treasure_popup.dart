import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';

void showTreasurePopup({
  required BuildContext context,
  required String symbol,
  required String treasureName,
  required int points,
}) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Center(
      child: AnimatedTreasurePopup(
        symbol: symbol,
        treasureName: treasureName,
        points: points,
      ),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(Duration(seconds: 2), () {
    overlayEntry.remove();
  });
}

class AnimatedTreasurePopup extends StatefulWidget {
  final String symbol;
  final String treasureName;
  final int points;

  const AnimatedTreasurePopup({
    Key? key,
    required this.symbol,
    required this.treasureName,
    required this.points,
  }) : super(key: key);

  @override
  State<AnimatedTreasurePopup> createState() => _AnimatedTreasurePopupState();
}

class _AnimatedTreasurePopupState extends State<AnimatedTreasurePopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.symbol, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(widget.treasureName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 4),
              Text(l10n.pointsAwarded(widget.points.toString()), style: TextStyle(color: Colors.green.shade800)),
            ],
          ),
        ),
      ),
    );
  }
}
