import 'package:flutter/material.dart';

/// Widget de background adaptatif qui utilise une grande image
/// et s'adapte automatiquement selon la taille de l'écran
class AdaptiveBackground extends StatelessWidget {
  final Widget child;
  final String? backgroundImage;
  final Color? fallbackColor;
  final BoxFit fit;
  final Alignment alignment;
  final double opacity;
  final bool enableParallax;
  
  const AdaptiveBackground({
    Key? key,
    required this.child,
    this.backgroundImage,
    this.fallbackColor,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.opacity = 1.0,
    this.enableParallax = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Background layer
            _buildBackground(context, constraints),
            
            // Content layer
            child,
          ],
        );
      },
    );
  }

  Widget _buildBackground(BuildContext context, BoxConstraints constraints) {
    if (backgroundImage == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: fallbackColor ?? Theme.of(context).colorScheme.background,
      );
    }

    return Positioned.fill(
      child: _buildAdaptiveImage(context, constraints),
    );
  }

  Widget _buildAdaptiveImage(BuildContext context, BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final aspectRatio = screenWidth / screenHeight;
    
    // Déterminer le type d'écran
    final screenType = _getScreenType(screenWidth, screenHeight, aspectRatio);
    
    Widget imageWidget = Image.asset(
      backgroundImage!,
      width: double.infinity,
      height: double.infinity,
      fit: _getFitForScreenType(screenType),
      alignment: _getAlignmentForScreenType(screenType),
      opacity: AlwaysStoppedAnimation(opacity),
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: fallbackColor ?? Theme.of(context).colorScheme.background,
          child: Center(
            child: Icon(
              Icons.image_not_supported,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
              size: 48,
            ),
          ),
        );
      },
    );

    // Ajouter l'effet parallax si activé
    if (enableParallax) {
      imageWidget = _wrapWithParallax(imageWidget, screenType);
    }

    return imageWidget;
  }

  ScreenType _getScreenType(double width, double height, double aspectRatio) {
    // Déterminer si c'est un téléphone, tablette, ou desktop
    if (width < 600) {
      // Mobile
      return aspectRatio > 1 ? ScreenType.mobileLandscape : ScreenType.mobilePortrait;
    } else if (width < 1200) {
      // Tablette
      return aspectRatio > 1 ? ScreenType.tabletLandscape : ScreenType.tabletPortrait;
    } else {
      // Desktop
      return ScreenType.desktop;
    }
  }

  BoxFit _getFitForScreenType(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobilePortrait:
        return BoxFit.cover; // Couvre tout l'écran
      case ScreenType.mobileLandscape:
        return BoxFit.cover; // Couvre tout l'écran
      case ScreenType.tabletPortrait:
        return BoxFit.cover; // Couvre tout l'écran
      case ScreenType.tabletLandscape:
        return BoxFit.cover; // Utilise toute la largeur disponible
      case ScreenType.desktop:
        return BoxFit.cover; // Couvre tout l'écran
    }
  }

  Alignment _getAlignmentForScreenType(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobilePortrait:
        return Alignment.center;
      case ScreenType.mobileLandscape:
        return Alignment.center;
      case ScreenType.tabletPortrait:
        return Alignment.center;
      case ScreenType.tabletLandscape:
        return Alignment.center; // Centre pour les tablettes en paysage
      case ScreenType.desktop:
        return Alignment.center; // Centre pour desktop
    }
  }

  Widget _wrapWithParallax(Widget imageWidget, ScreenType screenType) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - value)),
          child: Transform.scale(
            scale: 1.0 + (0.1 * (1 - value)),
            child: imageWidget,
          ),
        );
      },
    );
  }
}

/// Types d'écran supportés
enum ScreenType {
  mobilePortrait,
  mobileLandscape,
  tabletPortrait,
  tabletLandscape,
  desktop,
}

/// Extension pour faciliter l'utilisation
extension AdaptiveBackgroundExtension on Widget {
  /// Enveloppe le widget avec un background adaptatif
  Widget withAdaptiveBackground({
    String? backgroundImage,
    Color? fallbackColor,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    double opacity = 1.0,
    bool enableParallax = false,
  }) {
    return AdaptiveBackground(
      backgroundImage: backgroundImage,
      fallbackColor: fallbackColor,
      fit: fit,
      alignment: alignment,
      opacity: opacity,
      enableParallax: enableParallax,
      child: this,
    );
  }
}

/// Widget spécialisé pour les écrans de l'application
class GameBackground extends StatelessWidget {
  final Widget child;
  final GameBackgroundType type;
  final double opacity;
  final bool enableParallax;

  const GameBackground({
    Key? key,
    required this.child,
    this.type = GameBackgroundType.home,
    this.opacity = 1.0,
    this.enableParallax = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveBackground(
      backgroundImage: _getBackgroundForType(type),
      fallbackColor: _getFallbackColorForType(type),
      opacity: opacity,
      enableParallax: enableParallax,
      child: child,
    );
  }

  String _getBackgroundForType(GameBackgroundType type) {
    switch (type) {
      case GameBackgroundType.home:
        return 'assets/images/theme/background_home.png';
      case GameBackgroundType.game:
        return 'assets/images/theme/background_home.png'; // Même image pour l'instant
      case GameBackgroundType.menu:
        return 'assets/images/theme/background_home.png'; // Même image pour l'instant
    }
  }

  Color _getFallbackColorForType(GameBackgroundType type) {
    switch (type) {
      case GameBackgroundType.home:
        return Color(0xFF1A1A1A);
      case GameBackgroundType.game:
        return Color(0xFF0F1419);
      case GameBackgroundType.menu:
        return Color(0xFF2D3748);
    }
  }
}

/// Types de background pour l'application
enum GameBackgroundType {
  home,
  game,
  menu,
}

/// Scaffold avec background adaptatif intégré
class AdaptiveScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final String? backgroundImage;
  final GameBackgroundType? gameBackgroundType;
  final bool enableParallax;
  final double backgroundOpacity;

  const AdaptiveScaffold({
    Key? key,
    this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.backgroundImage,
    this.gameBackgroundType,
    this.enableParallax = false,
    this.backgroundOpacity = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget scaffoldContent = Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: Colors.transparent, // Transparent pour voir le background
    );

    // Appliquer le background adaptatif
    if (gameBackgroundType != null) {
      return GameBackground(
        type: gameBackgroundType!,
        opacity: backgroundOpacity,
        enableParallax: enableParallax,
        child: scaffoldContent,
      );
    } else if (backgroundImage != null) {
      return AdaptiveBackground(
        backgroundImage: backgroundImage,
        fallbackColor: backgroundColor,
        opacity: backgroundOpacity,
        enableParallax: enableParallax,
        child: scaffoldContent,
      );
    } else {
      return Container(
        color: backgroundColor ?? Theme.of(context).colorScheme.background,
        child: scaffoldContent,
      );
    }
  }
}

