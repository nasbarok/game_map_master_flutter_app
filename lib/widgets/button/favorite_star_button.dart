// lib/widgets/favorite_star_button.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

import '../../services/favorites_service.dart';

class FavoriteStarButton extends StatefulWidget {
  final int playerId;
  final String playerName;
  final double size;
  final Color? favoriteColor;
  final Color? notFavoriteColor;

  const FavoriteStarButton({
    Key? key,
    required this.playerId,
    required this.playerName,
    this.size = 24.0,
    this.favoriteColor = Colors.amber,
    this.notFavoriteColor,
  }) : super(key: key);

  @override
  State<FavoriteStarButton> createState() => _FavoriteStarButtonState();
}

class _FavoriteStarButtonState extends State<FavoriteStarButton> {
  late FavoritesService _favoritesService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _favoritesService = GetIt.I<FavoritesService>();
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _favoritesService.toggleFavorite(widget.playerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _favoritesService.isFavorite(widget.playerId)
                  ? '⭐ ${widget.playerName} ajouté aux favoris'
                  : '☆ ${widget.playerName} retiré des favoris',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      logger.d('❌ Erreur toggle favori: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur lors de la mise à jour des favoris'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _favoritesService,
      builder: (context, child) {
        final isFavorite = _favoritesService.isFavorite(widget.playerId);
        final effectiveNotFavoriteColor = widget.notFavoriteColor ??
            Colors.grey.withOpacity(0.4);

        return IconButton(
          onPressed: _isLoading ? null : _toggleFavorite,
          icon: _isLoading
              ? SizedBox(
            width: widget.size * 0.8,
            height: widget.size * 0.8,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite
                ? widget.favoriteColor
                : effectiveNotFavoriteColor,
            size: widget.size,
          ),
          tooltip: isFavorite
              ? 'Retirer des favoris'
              : 'Ajouter aux favoris',
        );
      },
    );
  }
}