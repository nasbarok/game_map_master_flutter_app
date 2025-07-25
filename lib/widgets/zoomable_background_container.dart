import 'package:flutter/material.dart';

class ZoomableBackgroundContainer extends StatelessWidget {
  final String imageAssetPath;
  final double zoom;
  final Widget child;
  final BorderRadius? borderRadius;
  final List<Color>? gradientColors;
  final BoxBorder? border;

  const ZoomableBackgroundContainer({
    Key? key,
    required this.imageAssetPath,
    this.zoom = 2.5,
    required this.child,
    this.borderRadius,
    this.gradientColors,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final effectiveZoom = isLandscape ? zoom * 0.6 : zoom;

        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Stack(
            children: [
              // ✅ Image zoomée dynamiquement avec OverflowBox
              Positioned.fill(
                child: OverflowBox(
                  minWidth: constraints.maxWidth * effectiveZoom,
                  maxWidth: constraints.maxWidth * effectiveZoom,
                  alignment: Alignment.center,
                  child: Image.asset(
                    imageAssetPath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // ✅ Overlay (gradient + border)
              Container(
                decoration: BoxDecoration(
                  border: border,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradientColors ??
                        [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.4),
                        ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ],
          ),
        );
      },
    );
  }
}
