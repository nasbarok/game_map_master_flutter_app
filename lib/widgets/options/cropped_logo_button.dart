import 'package:flutter/material.dart';
import 'audio_options_menu.dart';

/// Bouton logo croppé sur la tête du personnage pour accéder aux options
class CroppedLogoButton extends StatelessWidget {
  final double size;
  final VoidCallback? onPressed;

  const CroppedLogoButton({
    Key? key,
    this.size = 40.0,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => _openAudioOptions(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.green[700]!,
                  Colors.green[900]!,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Image du logo croppée sur la tête
                Positioned.fill(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/theme/logo_military.png',
                      fit: BoxFit.cover,
                      // Ajustement pour centrer sur la tête du personnage
                      alignment: Alignment(0, -0.3), // Légèrement vers le haut
                    ),
                  ),
                ),
                // Overlay avec icône d'options
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                        ],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAudioOptions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioOptionsMenu(),
      ),
    );
  }
}

/// Version alternative avec effet de pression
class CroppedLogoButtonAnimated extends StatefulWidget {
  final double size;
  final VoidCallback? onPressed;

  const CroppedLogoButtonAnimated({
    Key? key,
    this.size = 40.0,
    this.onPressed,
  }) : super(key: key);

  @override
  _CroppedLogoButtonAnimatedState createState() =>
      _CroppedLogoButtonAnimatedState();
}

class _CroppedLogoButtonAnimatedState extends State<CroppedLogoButtonAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
        if (widget.onPressed != null) {
          widget.onPressed!();
        } else {
          _openAudioOptions(context);
        }
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isPressed ? 0.5 : 0.3),
                    blurRadius: _isPressed ? 6 : 4,
                    offset: Offset(0, _isPressed ? 3 : 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05), // optionnel
                  ),
                  child: Stack(
                    children: [
                      // Image du logo croppée sur la tête
                      Positioned.fill(
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/theme/logo_military.png',
                            fit: BoxFit.cover,
                            alignment: Alignment(0, -0.45),
                          ),
                        ),
                      ),
                      // Overlay avec icône d'options
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black
                                    .withOpacity(_isPressed ? 0.4 : 0.2),
                              ],
                              stops: [0.6, 1.0],
                            ),
                          ),
                          child: Icon(
                            Icons.settings,
                            color: Colors.white
                                .withOpacity(_isPressed ? 1.0 : 0.8),
                            size: widget.size * 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAudioOptions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioOptionsMenu(),
      ),
    );
  }
}

/// Widget helper pour intégrer facilement dans une AppBar
class AppBarLogoButton extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double logoSize;
  final Color? backgroundColor;
  final List<Widget>? actions;

  const AppBarLogoButton({
    Key? key,
    required this.title,
    this.logoSize = 35.0,
    this.backgroundColor,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: backgroundColor ?? Colors.green[800],
      leading: Padding(
        padding: EdgeInsets.all(8.0),
        child: CroppedLogoButtonAnimated(size: logoSize),
      ),
      actions: actions,
      iconTheme: IconThemeData(color: Colors.white),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
