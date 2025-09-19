import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/favorites_service.dart';
import '../../services/game_state_service.dart';
import '../../services/invitation_service.dart';
import '../../utils/logger.dart';
import '../button/favorite_star_button.dart';

/// Widget dédié pour l'onglet Favorites
class FavoritesTabWidget extends StatefulWidget {
  const FavoritesTabWidget({Key? key}) : super(key: key);

  @override
  State<FavoritesTabWidget> createState() => _FavoritesTabWidgetState();
}

class _FavoritesTabWidgetState extends State<FavoritesTabWidget> {
  @override
  void initState() {
    super.initState();
    // Charger les favoris au démarrage du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final favoritesService = context.read<FavoritesService>();
      favoritesService.loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final favoritesService = context.watch<FavoritesService>();
    final invitationService = context.watch<InvitationService>();
    final gameStateService = context.watch<GameStateService>();
    final canInvite = invitationService.canSendInvitations();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec titre et bouton refresh
          _buildHeader(l10n, favoritesService),
          SizedBox(height: 12), // Plus compact

          // Contenu principal avec FutureBuilder
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: favoritesService.getFavoritePlayersDetails(),
              builder: (context, snapshot) {
                return _buildContent(
                  snapshot: snapshot,
                  gameStateService: gameStateService,
                  invitationService: invitationService,
                  canInvite: canInvite,
                );
              },
            ),
          ),

          // ✅ SUPPRESSION DU MESSAGE INFORMATIF EN BAS
          // _buildBottomInfo(canInvite), // SUPPRIMÉ
        ],
      ),
    );
  }

  /// Construit l'en-tête avec titre et bouton refresh
  Widget _buildHeader(
      AppLocalizations l10n, FavoritesService favoritesService) {
    return Row(
      children: [
        Icon(Icons.star, color: Colors.amber, size: 24),
        SizedBox(width: 8),
        Text(
          l10n.favoritesTab,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Spacer(),
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: () => favoritesService.loadFavorites(),
          tooltip: 'Actualiser les favoris',
        ),
      ],
    );
  }

  /// Construit le contenu principal selon l'état du FutureBuilder
  Widget _buildContent({
    required AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
    required GameStateService gameStateService,
    required InvitationService invitationService,
    required bool canInvite,
  }) {
    final l10n = AppLocalizations.of(context)!;

    // État de chargement
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingState(l10n);
    }

    // État d'erreur
    if (snapshot.hasError) {
      return _buildErrorState(l10n);
    }

    final favoritePlayersList = snapshot.data ?? [];
    final connectedPlayerIds = gameStateService.connectedPlayersList
        .map((p) => p['id'] as int)
        .toSet();

    // Filtrer les joueurs favoris qui ne sont pas déjà connectés
    final availableFavorites = favoritePlayersList
        .where((player) => !connectedPlayerIds.contains(player['id']))
        .toList();

    // Aucun favori
    if (favoritePlayersList.isEmpty) {
      return _buildEmptyState(l10n);
    }

    // Tous les favoris sont connectés
    if (availableFavorites.isEmpty) {
      return _buildAllConnectedState(favoritePlayersList.length, l10n);
    }

    // ✅ SUPPRESSION DES STATISTIQUES - Liste directe
    return ListView.builder(
      itemCount: availableFavorites.length,
      itemBuilder: (context, index) {
        final player = availableFavorites[index];
        return _buildCompactPlayerCard(
          player: player,
          canInvite: canInvite,
          invitationService: invitationService,
          l10n: l10n,
        );
      },
    );
  }

  /// État de chargement
  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12), // Plus compact
          Text(
            l10n.loadingFavorites,
            style: TextStyle(color: Colors.grey, fontSize: 14), // Plus petit
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 48, color: Colors.red), // Plus petit
          SizedBox(height: 12),
          Text(
            l10n.errorLoadingFavorites,
            style: TextStyle(color: Colors.red, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              final favoritesService = context.read<FavoritesService>();
              favoritesService.loadFavorites();
            },
            icon: Icon(Icons.refresh, size: 16),
            label: Text(l10n.retry, style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 64, color: Colors.grey.withOpacity(0.5)), // Plus petit
          SizedBox(height: 12),
          Text(
            l10n.noFavorites,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Plus petit
          ),
          SizedBox(height: 8),
          Text(
            l10n.markPlayersAsFavorites,
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAllConnectedState(int totalFavorites, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.green.withOpacity(0.5)), // Plus petit
          SizedBox(height: 12),
          Text(
            l10n.allFavoritesConnected,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Plus petit
          ),
          SizedBox(height: 8),
          Text(
            l10n.favoritesInGame(totalFavorites),
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPlayerCard({
    required Map<String, dynamic> player,
    required bool canInvite,
    required InvitationService invitationService,
    required AppLocalizations l10n,
  }) {
    final playerId = player['id'] as int;
    final playerName = player['username'] ?? l10n.unknownPlayer;

    // Vérifier si une invitation est déjà envoyée
    final isAlreadyInvited = invitationService.sentInvitations
        .any((invitation) => invitation.targetUserId == playerId);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 2), // Plus compact
      elevation: 1, // Plus discret
      child: ListTile(
        dense: true, // Plus compact
        leading: const CircleAvatar(
          backgroundColor: Colors.amber,
          radius: 16, // Plus petit
          child: Icon(Icons.star, color: Colors.white, size: 16),
        ),
        title: Text(
          playerName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), // Plus petit
        ),
        subtitle: _buildCompactStatusChip(isAlreadyInvited, l10n),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton d'invitation compact
            _buildCompactInvitationButton(
              player: player,
              canInvite: canInvite,
              isAlreadyInvited: isAlreadyInvited,
              l10n: l10n,
            ),
            SizedBox(width: 4),
            // Bouton étoile compact
            FavoriteStarButton(
              playerId: playerId,
              playerName: playerName,
              size: 16.0, // Plus petit
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatusChip(bool isAlreadyInvited, AppLocalizations l10n) {
    if (isAlreadyInvited) {
      return Chip(
        label: Text(
          l10n.invitationSent,
          style: TextStyle(color: Colors.white, fontSize: 10), // Plus petit
        ),
        backgroundColor: Colors.orange,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact, // Plus compact
      );
    } else {
      return Chip(
        label: Text(
          l10n.available,
          style: TextStyle(color: Colors.white, fontSize: 10), // Plus petit
        ),
        backgroundColor: Colors.blue,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact, // Plus compact
      );
    }
  }

  Widget _buildCompactInvitationButton({
    required Map<String, dynamic> player,
    required bool canInvite,
    required bool isAlreadyInvited,
    required AppLocalizations l10n,
  }) {
    String buttonText;
    Color? buttonColor;
    IconData buttonIcon;
    bool isEnabled;

    if (isAlreadyInvited) {
      buttonText = l10n.invited;
      buttonColor = Colors.orange;
      buttonIcon = Icons.schedule;
      isEnabled = false;
    } else if (!canInvite) {
      buttonText = l10n.invite;
      buttonColor = Colors.grey;
      buttonIcon = Icons.send;
      isEnabled = false;
    } else {
      buttonText = l10n.invite;
      buttonColor = Colors.green;
      buttonIcon = Icons.send;
      isEnabled = true;
    }

    return ElevatedButton.icon(
      onPressed: isEnabled ? () => _sendInvitation(player, l10n) : null,
      icon: Icon(buttonIcon, size: 12), // Plus petit
      label: Text(buttonText, style: TextStyle(fontSize: 12)), // Plus petit
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[600],
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Plus compact
        minimumSize: Size(60, 28), // Plus petit
      ),
    );
  }

  Future<void> _sendInvitation(Map<String, dynamic> player, AppLocalizations l10n) async {
    final invitationService = context.read<InvitationService>();
    final playerName = player['username'] ?? l10n.unknownPlayer;

    // Vérifier une dernière fois si pas déjà invité
    final isAlreadyInvited = invitationService.sentInvitations
        .any((invitation) => invitation.targetUserId == player['id']);

    if (isAlreadyInvited) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.playerAlreadyInvited(playerName)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await invitationService.sendInvitation(
        player['id'],
        context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invitationSentTo(playerName)),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      logger.d('❌ Erreur envoi invitation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorSendingInvitation(playerName)),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

}
