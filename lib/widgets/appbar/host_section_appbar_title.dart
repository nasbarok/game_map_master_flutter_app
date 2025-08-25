import 'package:flutter/material.dart';

typedef TitleOf = String Function(int index);
typedef IconOf  = IconData Function(int index);

/// Affiche dans l'AppBar : icône de l'onglet sélectionné (blanc + ombre) + titre.
/// - Écoute TabController via AnimatedBuilder (pas de setState)
/// - Crossfade fluide via AnimatedSwitcher
/// - Gère l'ellipsis du titre
class HostSectionAppBarTitle extends StatelessWidget {
  const HostSectionAppBarTitle({
    super.key,
    required this.controller,
    required this.titleOf,
    required this.iconOf,
    this.iconSize = 22,
    this.fadeDuration = const Duration(milliseconds: 200),
  });

  final TabController controller;
  final TitleOf titleOf;
  final IconOf iconOf;

  final double iconSize;
  final Duration fadeDuration;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final i     = controller.index;
        final title = titleOf(i);
        final icon  = iconOf(i);

        return AnimatedSwitcher(
          duration: fadeDuration,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: Row(
            key: ValueKey('appbar-title-$i'),
            mainAxisSize: MainAxisSize.min,
            children: [
              _ShadowedIcon(icon: icon, size: iconSize),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFFF7FAFC),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Icône rendue en blanc avec une ombre noire discrète.
/// (On passe par Text + shadows car Icon n'a pas de paramètre "shadows")
class _ShadowedIcon extends StatelessWidget {
  const _ShadowedIcon({
    required this.icon,
    required this.size,
    this.color = Colors.white,
    this.shadowColor = const Color(0x8A000000), // noir ~54%
    this.shadowOffset = const Offset(0, 2),
    this.shadowBlur = 6,
  });

  final IconData icon;
  final double size;
  final Color color;
  final Color shadowColor;
  final Offset shadowOffset;
  final double shadowBlur;

  @override
  Widget build(BuildContext context) {
    return Text(
      String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontSize: size,
        color: color,
        shadows: [
          Shadow(color: shadowColor, offset: shadowOffset, blurRadius: shadowBlur),
        ],
      ),
    );
  }
}
