import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;   // 0-based
  final int totalPages;    // >= 0
  final int totalElements; // conservé pour compat, non affiché
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PaginationControls({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.isFirst,
    required this.isLast,
    this.onPrevious,
    this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // rien à afficher s'il n'y a qu'une page
    if (totalPages <= 1) return const SizedBox.shrink();

    final bool disablePrev = isFirst || totalPages == 0;
    final bool disableNext = isLast  || totalPages == 0;

    // fenêtre de pastilles (max 7)
    const int maxDots = 7;
    int start = 0;
    int end = totalPages;
    if (totalPages > maxDots) {
      start = (currentPage - (maxDots ~/ 2)).clamp(0, totalPages - maxDots);
      end = start + maxDots;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF48BB78).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Précédent',
            onPressed: disablePrev ? null : onPrevious,
            icon: const Icon(Icons.chevron_left),
            color: Colors.white,
          ),
          const SizedBox(width: 6),

          // pastilles centrées
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(end - start, (i) {
              final idx = start + i;
              final active = idx == currentPage;
              final dist = (idx - currentPage).abs();
              final double opacity = active ? 1.0 : (dist <= 1 ? 0.7 : 0.35);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 10 : 8,
                height: active ? 10 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(opacity),
                ),
              );
            }),
          ),

          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Suivant',
            onPressed: disableNext ? null : onNext,
            icon: const Icon(Icons.chevron_right),
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}