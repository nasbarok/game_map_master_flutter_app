import 'dart:async';

import 'package:game_map_master_flutter_app/screens/gamer/team_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/field.dart';
import '../../models/invitation.dart';
import '../../models/pagination/paginated_response.dart';
import '../../models/websocket/player_left_message.dart';
import '../../models/websocket/websocket_message.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../../services/history_service.dart';
import '../../services/player_connection_service.dart';
import '../../services/team_service.dart';
import '../../services/websocket_service.dart';
import '../../services/invitation_service.dart';
import 'package:go_router/go_router.dart';
import '../../models/team.dart';
import '../../widgets/adaptive_background.dart';
import '../../widgets/gamer_history_button.dart';
import '../../widgets/options/user_options_menu.dart';
import '../../widgets/options/cropped_logo_button.dart';
import '../../widgets/pagination/pagination_controls.dart';
import '../gamesession/game_session_screen.dart';
import '../history/field_sessions_screen.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

class GameLobbyScreen extends StatefulWidget {
  const GameLobbyScreen({Key? key}) : super(key: key);

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GameStateService _gameStateService;
  late WebSocketService _webSocketService;
  PaginatedResponse<Field>? _visitedFieldsPage;
  int _visitedPage = 0;
  bool _loadingVisited = true;
  String? _visitedError;
  final int _visitedPageSize = 5;
  int _lastIndex = 0;
  StreamSubscription<WebSocketMessage>? _webSocketSubscription;

  @override
  void initState() {
    super.initState();

    _loadVisitedFields(page: 0);

    // Initialiser avec un seul onglet par défaut
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_tabController.index == 1) {
            logger.d("📩 Rafraîchissement des invitations (onglet ouvert)");
            context.read<InvitationService>().loadReceivedInvitations();
          }
        });
      }
    });

    _gameStateService = Provider.of<GameStateService>(context, listen: false);
    _webSocketService = Provider.of<WebSocketService>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final teamService = Provider.of<TeamService>(context, listen: false);

      _webSocketService.connect();

      final mapId = _gameStateService.selectedMap?.id;
      final fieldId = _gameStateService.selectedMap?.field?.id;

      if (fieldId != null) {
        logger.d('📡 Abonnement au topic du terrain depuis GameLobbyScreen');
        _webSocketService.subscribeToField(fieldId);
        if (mapId != null) {
          _gameStateService.loadConnectedPlayers();
          teamService.loadTeams(mapId);
        }
      } else {
        logger.d('❌ Pas de terrain ouvert en cours');
        // 👉 Charger les invitations
        context.read<InvitationService>().loadReceivedInvitations();
      }
    });

    _webSocketSubscription = _webSocketService.messageStream.listen((message) {
      if (message != null && message.type == 'FIELD_CLOSED') {
        logger.d('🔄 Terrain fermé détecté, actualisation de la liste des terrains visités');
        _loadVisitedFields(page: _visitedPage);
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameState = context.watch<GameStateService>();

    final selectedMap = gameState.selectedMap;
    final fieldOpen = gameState.isTerrainOpen;
    final isHostVisiting = gameState.isHostVisiting;
    final bool hasActiveField = fieldOpen && selectedMap != null;
    String appBarTitle;
    Color appBarColor;

    logger.d('🧭 [GameLobbyScreen] build() déclenché');
    logger.d('🔍 Carte sélectionnée : ${selectedMap?.name ?? "Aucune"}');
    logger.d('🔓 Terrain ouvert : $fieldOpen');

    final invitationsCount =
        context.watch<InvitationService>().receivedPendingInvitations.length;

    if (isHostVisiting) {
      appBarTitle =
          '🏠 ${l10n.visitingTerrain(selectedMap?.name ?? l10n.unknownMap)}';
      appBarColor = Colors.orange; // Couleur distinctive pour host visiteur
    } else {
      appBarTitle = l10n.mapLabel(selectedMap?.name ?? l10n.unknownMap);
      appBarColor = Colors.blue; // Couleur normale pour gamer
    }

    // ✅ Rendu normal
    logger.d('✅ Affichage de l’interface GameLobbyScreen');

    return AdaptiveScaffold(
      gameBackgroundType: GameBackgroundType.home,
      enableParallax: true,
      backgroundOpacity: 0.85,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: hasActiveField
            ? Text(
                l10n.mapLabel(selectedMap!.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcomeMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.welcomeSubtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          child: const CroppedLogoButton(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHostVisiting
                  ? Colors.orange.withOpacity(0.8)
                  : Colors.red.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                isHostVisiting ? Icons.home : Icons.logout,
                color: Colors.white,
              ),
              tooltip: isHostVisiting ? l10n.returnToHostMode : l10n.logout,
              onPressed: () => _handleDisconnection(context, isHostVisiting),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(icon: const Icon(Icons.map), text: l10n.terrainTab),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.mail, size: 20),
                          if (invitationsCount > 0)
                            Positioned(
                              left: -8, // 👈 met le badge à gauche
                              top: -6, // ajuste verticalement
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 16, minHeight: 16),
                                child: Text(
                                  '$invitationsCount',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.invitations),
                    ],
                  ),
                ),
                Tab(icon: const Icon(Icons.people), text: l10n.playersTab),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTerrainTab(),
          _buildInvitationsTab(),
          _buildPlayersTab(),
        ],
      ),
    );
  }

  Widget _buildInvitationsTab() {
    final l10n = AppLocalizations.of(context)!;
    final invitationService = context.watch<InvitationService>();
    final pendingInvitations = invitationService.receivedInvitations;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.receivedInvitations,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<InvitationService>().loadReceivedInvitations();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.invitationsRefreshed)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
              child: RefreshIndicator(
            onRefresh: () =>
                context.read<InvitationService>().loadReceivedInvitations(),
            child: pendingInvitations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.mail_outline,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noInvitations,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Les invitations apparaîtront ici',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: pendingInvitations.length,
                    itemBuilder: (context, index) {
                      final invitation = pendingInvitations[index];
                      return _buildInvitationCard(invitation);
                    },
                  ),
          )),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(Invitation invitation) {
    final l10n = AppLocalizations.of(context)!;
    final invitationService = context.read<InvitationService>();

    final fromUsername = invitation.senderUsername ?? l10n.unknownPlayerName;
    final fieldName = invitation.fieldName ?? l10n.unknownMap;
    final DateTime timestamp = invitation.createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(l10n.invitationFrom(fromUsername)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.mapLabelShort(fieldName)),
            Text(
              _formatTimestamp(timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            OverflowBar(
              alignment: MainAxisAlignment.start,
              spacing: 8,
              overflowSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => invitationService.respondToInvitation(
                    context,
                    invitation.id,
                    false,
                  ),
                  child: Text(l10n.declineInvitation),
                ),
                ElevatedButton(
                  onPressed: () => invitationService.respondToInvitation(
                    context,
                    invitation.id,
                    true,
                  ),
                  child: Text(l10n.acceptInvitation),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  Widget _buildTerrainTab() {
    final l10n = AppLocalizations.of(context)!;
    final gameState = context.watch<GameStateService>();

    if (!gameState.isTerrainOpen || gameState.selectedMap == null) {
      // Afficher la liste des anciens terrains
      return _buildPreviousFieldsList();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              color: Colors.black.withOpacity(0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side:
                    BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.mapLabel(
                              gameState.selectedMap?.name ?? l10n.unknownMap),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          tooltip: l10n.sessionsHistoryTooltip,
                          icon: const Icon(Icons.history),
                          onPressed: () {
                            final fieldId = gameState.selectedMap?.field?.id;
                            if (fieldId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FieldSessionsScreen(fieldId: fieldId),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.noAssociatedField)),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSelectedScenarios(),
                    const SizedBox(height: 24),
                    if (gameState.isGameRunning)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              l10n.remainingTimeLabel(
                                  gameState.timeLeftDisplay),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (gameState.isGameRunning)
              Card(
                elevation: 4,
                color: Colors.black.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.gameInProgressTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.gameInProgressInstructions,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToGameSession(context),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(l10n.joinGameButton),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 4,
                color: Colors.black.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.waitingForGameStartTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.waitingForGameStartInstructions,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24), // ou ajustable
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _showLeaveConfirmationDialog(gameState.selectedMap!.field!);
                },
                icon: const Icon(Icons.logout),
                label: Text(l10n.leaveFieldButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedScenarios() {
    final l10n = AppLocalizations.of(context)!;
    final gameState = context.read<GameStateService>();

    final scenarios = gameState.selectedScenarios ?? [];

    if (scenarios.isEmpty) {
      return Text(
        l10n.noScenarioSelected,
        style: const TextStyle(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectedScenariosLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...scenarios.map((scenario) {
          final String name = scenario.scenario.name;
          final treasure = scenario.treasureHuntScenario;
          final String description = treasure != null
              ? l10n.treasureHuntScenarioDetails(
                  treasure.totalTreasures.toString(), treasure.defaultSymbol)
              : (scenario.scenario.description ?? l10n.noDescription);

          return Card(
            color: Colors.black.withOpacity(0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.flag),
              title: Text(name),
              subtitle: Text(description),
            ),
          );
        }).toList(),
      ],
    );
  }

  // Méthode pour afficher la liste des anciens terrains
  Widget _buildPreviousFieldsList() {
    final l10n = AppLocalizations.of(context)!;

    if (_loadingVisited) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_visitedError != null) {
      return Center(child: Text(_visitedError!));
    }

    final page = _visitedFieldsPage;
    final fields = page?.content ?? const <Field>[];

    if (fields.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(l10n.noFieldsVisited,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.waitForInvitation,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        if ((page?.totalPages ?? 0) > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: PaginationControls(
              currentPage: page!.number,
              totalPages: page.totalPages,
              totalElements: page.totalElements,
              isFirst: page.first,
              isLast: page.last,
              onPrevious: () => _loadVisitedFields(
                  page: (_visitedPage - 1).clamp(0, page.totalPages - 1)),
              onNext: () => _loadVisitedFields(
                  page: (_visitedPage + 1).clamp(0, page.totalPages - 1)),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final field = fields[index];
              return Card(
                color: Colors.black.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: Colors.white.withOpacity(0.3), width: 1),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            field.active ? Colors.green : Colors.grey,
                        child: const Icon(Icons.map, color: Colors.white),
                      ),
                      title: Text(field.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(field.active
                              ? l10n.fieldStatusOpen
                              : l10n.fieldStatusClosed),
                          Text(field.openedAt != null
                              ? l10n.fieldOpenedOn(_formatDate(field.openedAt!))
                              : l10n.unknownOpeningDate),
                        ],
                      ),
                      trailing: Wrap(
                        direction: Axis.vertical,
                        spacing: 4,
                        children: [
                          if (field.active)
                            ElevatedButton(
                              onPressed: () => _joinField(field.id!),
                              child: Text(l10n.joinButton),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: l10n.deleteFromHistoryTooltip,
                            onPressed: () => _deleteHistoryEntry(field),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GamerHistoryButton(fieldId: field.id!),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Méthode pour charger les anciens terrains
  Future<List<Field>> _loadPreviousFields() async {
    try {
      final apiService = GetIt.I<ApiService>();
      final response = await apiService.get('fields-history/history');

      if (response == null || !(response is List)) {
        return [];
      }

      final fields =
          (response as List).map((data) => Field.fromJson(data)).toList();

      // 🔽 TRI par openedAt décroissant (les null vont en bas)
      fields.sort((a, b) {
        final ad = a.openedAt;
        final bd = b.openedAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1; // a après b
        if (bd == null) return -1; // a avant b
        return bd.compareTo(ad); // récent d’abord
      });

      // pour chaque terrain actif, tenter de s'abonner
      for (final field in fields) {
        if (field.active == true && field.id != null) {
          logger.d(
              '📡 Tentative d\'abonnement WebSocket au terrain ${field.name} (ID: ${field.id})');
          _webSocketService.subscribeToField(field.id!);
        }
      }

      return fields;
    } catch (e) {
      logger.d('❌ Erreur lors du chargement des terrains: $e');
      return [];
    }
  }

  // Méthode pour rejoindre un terrain
  Future<void> _joinField(int fieldId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final apiService = GetIt.I<ApiService>();
      final authService = GetIt.I<AuthService>();
      final gameStateService = GetIt.I<GameStateService>();

      if (authService.currentUser == null) {
        return;
      }

      final userId = authService.currentUser!.id;

      // Appeler l'API pour rejoindre le terrain
      final response = await apiService.post('fields/$fieldId/join', {
        'userId': userId,
      });

      if (response != null) {
        // Mettre à jour l'état du jeu
        await gameStateService.restoreSessionIfNeeded(apiService, fieldId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.youJoinedFieldSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger.d('❌ Erreur lors de la connexion au terrain: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.loadingError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _leaveField() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final gameStateService = GetIt.I<GameStateService>();
      final authService = GetIt.I<AuthService>();
      final webSocketService = GetIt.I<WebSocketService>();

      if (gameStateService.selectedMap == null ||
          authService.currentUser == null) {
        return;
      }

      final fieldId = gameStateService.selectedMap!.field!.id;
      final userId = authService.currentUser!.id;

      // Envoyer un message WebSocket pour quitter le terrain
      final message = PlayerLeftMessage(
        senderId: userId!,
        fieldId: fieldId!,
      );
      await webSocketService.sendMessage('/app/leave-field', message);
      // Réinitialiser l'état du jeu
      gameStateService.reset();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.youLeftField),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      logger.d('❌ Erreur lors de la déconnexion du terrain: $e');
    }
  }

  Widget _buildPlayersTab() {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.watch<GameStateService>();
    final teamService = context.watch<TeamService>();
    final authService = context.read<AuthService>();
    final connectedPlayers = gameStateService.connectedPlayersList;
    final teams = teamService.teams;
    final currentUserId = authService.currentUser?.id;

    if (!gameStateService.isTerrainOpen) {
      return Center(
        child: Text(l10n.notConnectedToField),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTeamInfo(),
        const SizedBox(height: 16),
        Card(
          color: Colors.black.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.connectedPlayersCount(
                      connectedPlayers.length.toString()),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (connectedPlayers.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        l10n.noPlayerConnected,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: connectedPlayers.length,
                    itemBuilder: (context, index) {
                      final player = connectedPlayers[index];
                      final isCurrentUser = player['id'] == currentUserId;

                      // ✅ Calcul dynamique du nom d'équipe
                      String teamName = l10n.noTeam;
                      Color teamColor = Colors.grey;

                      final teamId = player['teamId'];
                      final team = teams.where((t) => t.id == teamId).toList();
                      if (team.isNotEmpty) {
                        teamName = team.first.name;
                        teamColor = Colors.blue;
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isCurrentUser ? Colors.amber : teamColor,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          player['username'] ?? l10n.playersTab,
                          // Fallback, should not happen
                          style: TextStyle(
                            fontWeight: isCurrentUser
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          teamName,
                          style: TextStyle(color: teamColor),
                        ),
                        trailing: isCurrentUser
                            ? Chip(
                                label: Text(l10n.youLabel),
                                backgroundColor: Colors.amber,
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                              )
                            : null,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Dans GameLobbyScreen

  Widget _buildTeamInfo() {
    final l10n = AppLocalizations.of(context)!;
    final teamService = GetIt.I<TeamService>();
    final myTeamId = teamService.myTeamId;

    // Trouver l'équipe du joueur
    String teamName = l10n.noTeam;
    Color teamColor = Colors.grey;

    if (myTeamId != null) {
      final teamIndex =
          teamService.teams.indexWhere((team) => team.id == myTeamId);
      if (teamIndex >= 0) {
        teamName = teamService.teams[teamIndex].name;
        teamColor = Colors.green;
      }
    }

    return Card(
      color: Colors.black.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.yourTeamLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: teamColor,
                  child: Icon(
                    myTeamId != null ? Icons.group : Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  teamName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: teamColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TeamManagementScreen()),
                );
              },
              icon: const Icon(Icons.group),
              label: Text(l10n.manageTeamsButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeTeamDialog(List<Team> teams) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changeTeamTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              final teamService = context.watch<TeamService>();
              final isCurrentTeam = team.id == teamService.myTeamId;

              return ListTile(
                title: Text(team.name),
                subtitle: Text(l10n.playersCountSuffix(team.players.length)),
                trailing: isCurrentTeam
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: isCurrentTeam
                    ? null
                    : () {
                        final authService = context.read<AuthService>();
                        final playerId = authService.currentUser!.id;
                        teamService.assignPlayerToTeam(playerId!, team.id,
                            context.read<GameStateService>().selectedMap!.id!);
                        Navigator.of(context).pop();
                      },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmationDialog(Field field) {
    final l10n = AppLocalizations.of(context)!;
    final playerConnectionService = context.read<PlayerConnectionService>();
    final authService = context.read<AuthService>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveFieldConfirmationTitle),
        content: Text(l10n.leaveFieldConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              // Ferme la boîte de dialogue
              Navigator.of(context).pop();
              // Effectuer la déconnexion
              playerConnectionService.leaveField(field.id!);

              // Vérifier si l'utilisateur est un hôte et rediriger en conséquence
              if (authService.currentUser?.hasRole('HOST') ?? false) {
                // Si c'est un hôte, redirigez vers /host
                context.go('/host');
              } else {
                // Sinon, redirigez vers /gamer/lobby
                context.go('/gamer/lobby');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.leaveButton),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHistoryEntry(Field field) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteFieldHistoryTitle),
        content: Text(l10n.deleteFieldHistoryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final apiService = GetIt.I<ApiService>();
      await apiService.delete('fields-history/history/${field.id}');

      await _loadVisitedFields(page: _visitedPage);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fieldDeletedFromHistory)),
      );
    } catch (e) {
      logger.d('❌ Erreur suppression terrain : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorDeletingField)),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _navigateToGameSession(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = GetIt.I<AuthService>();
    final gameStateService = GetIt.I<GameStateService>();

    final user = authService.currentUser;
    final teamId = GetIt.I<TeamService>().myTeamId;
    final isHost = false;
    final gameSession = gameStateService.activeGameSession;

    if (user != null && gameSession != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameSessionScreen(
            userId: user.id!,
            teamId: teamId,
            isHost: isHost,
            gameSession: gameSession,
            fieldId: gameSession.field!.id,
          ),
        ),
      );
    } else {
      logger.d(
          '❌ Impossible de rejoindre la partie : utilisateur ou session manquants');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cannotJoinGame)),
      );
    }
  }

  /// 🆕 Gérer la déconnexion selon le contexte
  Future<void> _handleDisconnection(
      BuildContext context, bool isHostVisiting) async {
    final l10n = AppLocalizations.of(context)!;

    if (isHostVisiting) {
      // CAS HOST VISITEUR : Retour mode host
      await _returnToHostMode(context);
    } else {
      // CAS GAMER NORMAL : Déconnexion complète
      await _performLogout(context);
    }
  }

  /// 🆕 Retour au mode host
  Future<void> _returnToHostMode(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.read<GameStateService>();
    final playerConnectionService = context.read<PlayerConnectionService>();
    final webSocketService = context.read<WebSocketService>();

    final fieldId = gameStateService.selectedMap?.field?.id;

    try {
      if (fieldId != null) {
        // quitte proprement le terrain visité (tu l’avais rejoint comme gamer)
        await playerConnectionService.leaveField(fieldId);
        webSocketService.unsubscribeFromField(fieldId);
      }

      // restaure l’état host (ta méthode existe déjà)
      gameStateService.endHostVisit();

      if (!context.mounted) return;

      // 3. Navigation vers interface host
      if (context.mounted) {
        context.go('/host');
      }

      // 4. Notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.returnedToHostMode),
            backgroundColor: Colors.green),
      );
      logger.d('🎮➡️🏠 Retour mode host réussi');
    } catch (e) {
      logger.e('Erreur lors du retour mode host: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorReturningToHostMode),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadVisitedFields({required int page}) async {
    setState(() {
      _loadingVisited = true;
      _visitedError = null;
    });

    try {
      final historyService = GetIt.I<HistoryService>();
      final pageObj = await historyService.getVisitedFieldsPaginated(
        page: page,
        size: _visitedPageSize,
      );
      if (!mounted) return;
      setState(() {
        _visitedFieldsPage = pageObj;
        _visitedPage = pageObj.number; // serveur source of truth
        _loadingVisited = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _visitedError = l10n.errorLoadingData(e.toString());
        _loadingVisited = false;
      });
    }
  }

  /// Déconnexion complète (gamer normal)
  Future<void> _performLogout(BuildContext context) async {
    final authService = context.read<AuthService>();
    await authService.leaveAndLogout(context);
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    final fieldId = _gameStateService.selectedMap?.field?.id;
    if (fieldId != null) {
      logger.d('📡 Désabonnement du topic du terrain depuis GameLobbyScreen');
      _webSocketService.unsubscribeFromField(fieldId);
    }
    _tabController.dispose();
    _webSocketSubscription?.cancel();

    super.dispose();
  }
}
