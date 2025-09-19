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
          SizedBox(height: 16),

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

          // Informations en bas selon l'état du terrain
          _buildBottomInfo(canInvite),
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
    // État de chargement
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingState();
    }

    // État d'erreur
    if (snapshot.hasError) {
      return _buildErrorState();
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
      return _buildEmptyState();
    }

    // Tous les favoris sont connectés
    if (availableFavorites.isEmpty) {
      return _buildAllConnectedState(favoritePlayersList.length);
    }

    // Affichage de la liste avec statistiques
    return _buildFavoritesList(
      favoritePlayersList: favoritePlayersList,
      availableFavorites: availableFavorites,
      invitationService: invitationService,
      canInvite: canInvite,
    );
  }

  /// État de chargement
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Chargement des favoris...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// État d'erreur
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Erreur lors du chargement des favoris',
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              final favoritesService = context.read<FavoritesService>();
              favoritesService.loadFavorites();
            },
            icon: Icon(Icons.refresh),
            label: Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  /// État aucun favori
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border,
              size: 80, color: Colors.grey.withOpacity(0.5)),
          SizedBox(height: 16),
          Text(
            'Aucun joueur favori',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Marquez des joueurs en favoris en cliquant sur l\'étoile dans les autres onglets',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// État tous connectés
  Widget _buildAllConnectedState(int totalFavorites) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 80, color: Colors.green.withOpacity(0.5)),
          SizedBox(height: 16),
          Text(
            'Tous vos favoris sont déjà connectés !',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '$totalFavorites joueur(s) favori(s) dans la partie',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Liste des favoris avec statistiques
  Widget _buildFavoritesList({
    required List<Map<String, dynamic>> favoritePlayersList,
    required List<Map<String, dynamic>> availableFavorites,
    required InvitationService invitationService,
    required bool canInvite,
  }) {
    return Column(
      children: [
        // Statistiques en haut
        _buildStatistics(
          favoritePlayersList: favoritePlayersList,
          availableFavorites: availableFavorites,
          invitationService: invitationService,
        ),
        SizedBox(height: 16),

        // Liste des favoris disponibles
        Expanded(
          child: ListView.builder(
            itemCount: availableFavorites.length,
            itemBuilder: (context, index) {
              final player = availableFavorites[index];
              return _buildPlayerCard(
                player: player,
                canInvite: canInvite,
                invitationService: invitationService,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Construit les statistiques des favoris
  Widget _buildStatistics({
    required List<Map<String, dynamic>> favoritePlayersList,
    required List<Map<String, dynamic>> availableFavorites,
    required InvitationService invitationService,
  }) {
    final totalFavorites = favoritePlayersList.length;
    final availableCount = availableFavorites.length;
    final connectedCount = totalFavorites - availableCount;

    // Compter les invités parmi les disponibles
    final invitedCount = availableFavorites.where((player) {
      return invitationService.sentInvitations
          .any((invitation) => invitation.targetUserId == player['id']);
    }).length;

    final readyToInviteCount = availableCount - invitedCount;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.star,
            label: 'Total',
            value: totalFavorites.toString(),
            color: Colors.amber,
          ),
          _buildStatItem(
            icon: Icons.people,
            label: 'Connectés',
            value: connectedCount.toString(),
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.schedule,
            label: 'Invités',
            value: invitedCount.toString(),
            color: Colors.orange,
          ),
          _buildStatItem(
            icon: Icons.send,
            label: 'Disponibles',
            value: readyToInviteCount.toString(),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  /// Construit un élément de statistique
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Construit une carte pour un joueur favori
  Widget _buildPlayerCard({
    required Map<String, dynamic> player,
    required bool canInvite,
    required InvitationService invitationService,
  }) {
    final playerId = player['id'] as int;
    final playerName = player['username'] ?? 'Joueur inconnu';
    final playerEmail = player['email'] ?? '';

    // Vérifier si une invitation est déjà envoyée
    final isAlreadyInvited = invitationService.sentInvitations
        .any((invitation) => invitation.targetUserId == playerId);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber,
          child: Icon(Icons.star, color: Colors.white),
        ),
        title: Text(
          playerName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (playerEmail.isNotEmpty)
              Text(
                playerEmail,
                style: TextStyle(color: Colors.grey[600]),
              ),
            SizedBox(height: 4),
            _buildStatusChip(isAlreadyInvited),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton d'invitation intelligent
            _buildInvitationButton(
              player: player,
              canInvite: canInvite,
              isAlreadyInvited: isAlreadyInvited,
            ),
            SizedBox(width: 8),
            // Bouton pour retirer des favoris
            FavoriteStarButton(
              playerId: playerId,
              playerName: playerName,
              size: 20.0,
            ),
          ],
        ),
        isThreeLine: playerEmail.isNotEmpty,
      ),
    );
  }

  /// Construit un chip indiquant le statut du joueur
  Widget _buildStatusChip(bool isAlreadyInvited) {
    if (isAlreadyInvited) {
      return const Chip(
        label: Text(
          'Invitation envoyée',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: Colors.orange,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    } else {
      return const Chip(
        label: Text(
          'Disponible',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: Colors.blue,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }
  }

  /// Construit un bouton d'invitation intelligent
  Widget _buildInvitationButton({
    required Map<String, dynamic> player,
    required bool canInvite,
    required bool isAlreadyInvited,
  }) {
    // Déterminer l'état du bouton
    String buttonText;
    Color? buttonColor;
    IconData buttonIcon;
    bool isEnabled;

    if (isAlreadyInvited) {
      // Joueur déjà invité
      buttonText = 'Invité';
      buttonColor = Colors.orange;
      buttonIcon = Icons.schedule;
      isEnabled = false;
    } else if (!canInvite) {
      // Terrain fermé
      buttonText = 'Inviter';
      buttonColor = Colors.grey;
      buttonIcon = Icons.send;
      isEnabled = false;
    } else {
      // Disponible pour invitation
      buttonText = 'Inviter';
      buttonColor = Colors.green;
      buttonIcon = Icons.send;
      isEnabled = true;
    }

    return ElevatedButton.icon(
      onPressed: isEnabled ? () => _sendInvitation(player) : null,
      icon: Icon(buttonIcon, size: 16),
      label: Text(buttonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[600],
      ),
    );
  }

  /// Construit les informations en bas selon l'état du terrain
  Widget _buildBottomInfo(bool canInvite) {
    if (canInvite) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.green, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Vous pouvez inviter vos joueurs favoris à rejoindre votre terrain',
                style: TextStyle(color: Colors.green[700], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ouvrez votre terrain pour pouvoir envoyer des invitations',
                style: TextStyle(color: Colors.orange[700], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Méthode pour envoyer une invitation à un joueur favori
  Future<void> _sendInvitation(Map<String, dynamic> player) async {
    final invitationService = context.read<InvitationService>();
    final playerName = player['username'] ?? 'Joueur inconnu';

    // Vérifier une dernière fois si pas déjà invité
    final isAlreadyInvited = invitationService.sentInvitations
        .any((invitation) => invitation.targetUserId == player['id']);

    if (isAlreadyInvited) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ $playerName est déjà invité'),
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
            content: Text('✉️ Invitation envoyée à $playerName'),
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
            content: Text(
                '❌ Erreur lors de l\'envoi de l\'invitation à $playerName'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
