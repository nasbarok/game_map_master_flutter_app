import 'package:airsoft_game_map/screens/gamer/team_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../models/field.dart';
import '../../models/websocket/player_left_message.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../../services/player_connection_service.dart';
import '../../services/team_service.dart';
import '../../services/websocket_service.dart';
import '../../services/invitation_service.dart';
import 'package:go_router/go_router.dart';
import '../../models/team.dart';
import '../../widgets/gamer_history_button.dart';
import '../gamesession/game_session_screen.dart';
import '../history/field_sessions_screen.dart';
import 'package:airsoft_game_map/utils/logger.dart';

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

  @override
  void initState() {
    super.initState();

    // Initialiser avec un seul onglet par défaut
    _tabController = TabController(length: 2, vsync: this);

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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.read<GameStateService>();

    final selectedMap = gameState.selectedMap;
    final terrainOuvert = gameState.isTerrainOpen;

    logger.d('🧭 [GameLobbyScreen] build() déclenché');
    logger.d('🔍 Carte sélectionnée : ${selectedMap?.name ?? "Aucune"}');
    logger.d('🔓 Terrain ouvert : $terrainOuvert');

    final bool isConnectedToField = gameState.isTerrainOpen;

    // ✅ Rendu normal
    logger.d('✅ Affichage de l’interface GameLobbyScreen');

    return Scaffold(
      appBar: AppBar(
        title: Text('Partie sur ${gameState.selectedMap?.name ?? ""}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = context.read<AuthService>();
              await authService.leaveAndLogout(context);
              if (mounted) {
                context.go('/login');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Terrain'),
            Tab(icon: Icon(Icons.people), text: 'Joueurs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Terrain
          _buildTerrainTab(),
          // Onglet Joueurs
          _buildPlayersTab(),
        ],
      ),
    );
  }

  Widget _buildTerrainTab() {
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Carte : ${gameState.selectedMap?.name ?? "Inconnue"}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          tooltip: 'Historique des sessions',
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
                                const SnackBar(
                                    content:
                                        Text('Aucun terrain associé trouvé')),
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
                              'Temps restant : ${gameState.timeLeftDisplay}',
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Partie en cours',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Suivez les instructions de l\'hôte et collaborez avec votre équipe pour atteindre les objectifs du scénario.',
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToGameSession(context),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Rejoindre la partie'),
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
              const Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'En attente de démarrage',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'L\'hôte n\'a pas encore lancé la partie. Préparez votre équipement et rejoignez une équipe en attendant.',
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
                label: const Text('Quitter le terrain'),
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
    final gameState = context.read<GameStateService>();

    final scenarios = gameState.selectedScenarios ?? [];

    if (scenarios.isEmpty) {
      return const Text(
        'Aucun scénario sélectionné',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scénarios sélectionnés :',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...scenarios.map((scenario) {
          final String name = scenario.scenario.name;
          final treasure = scenario.treasureHuntScenario;
          final String description = treasure != null
              ? 'Chasse au trésor : ${treasure.totalTreasures} QR codes (${treasure.defaultSymbol})'
              : (scenario.scenario.description ?? 'Pas de description');

          return Card(
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
    return FutureBuilder<List<Field>>(
      future: _loadPreviousFields(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final fields = snapshot.data ?? [];

        if (fields.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 80, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Aucun terrain visité',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Attendez une invitation pour rejoindre un terrain',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: fields.length,
          itemBuilder: (context, index) {
            final field = fields[index];
            final isOpen = field.active;

            String openedAtStr = field.openedAt != null
                ? 'Ouvert le ${_formatDate(field.openedAt!)}'
                : 'Date d\'ouverture inconnue';

            String closedAtStr = field.closedAt != null
                ? 'Fermé le ${_formatDate(field.closedAt!)}'
                : 'Encore actif';

            String ownerName = field.owner?.username != null
                ? 'Propriétaire : ${field.owner!.username}'
                : 'Propriétaire inconnu';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isOpen ? Colors.green : Colors.grey,
                      child: const Icon(Icons.map, color: Colors.white),
                    ),
                    title: Text(field.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isOpen ? 'Ouvert' : 'Fermé'),
                        Text(openedAtStr),
                        Text(closedAtStr),
                        Text(ownerName),
                      ],
                    ),
                    trailing: Wrap(
                      direction: Axis.vertical,
                      spacing: 4,
                      children: [
                        if (isOpen)
                          ElevatedButton(
                            onPressed: () => _joinField(field.id!),
                            child: const Text('Rejoindre'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Supprimer de l\'historique',
                          onPressed: () => _deleteHistoryEntry(field),
                        ),
                      ],
                    ),
                  ),
                  // 👇 Bouton Historique spécifique
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GamerHistoryButton(fieldId: field.id!),
                  ),
                ],
              ),
            );
          },
        );
      },
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
      // 🔥 NOUVEAU : pour chaque terrain actif, tenter de s'abonner
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
        await gameStateService.restoreSessionIfNeeded(apiService);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez rejoint le terrain avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger.d('❌ Erreur lors de la connexion au terrain: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _leaveField() async {
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
        const SnackBar(
          content: Text('Vous avez quitté le terrain'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      logger.d('❌ Erreur lors de la déconnexion du terrain: $e');
    }
  }

  Widget _buildPlayersTab() {
    final gameStateService = context.read<GameStateService>();
    final teamService = context.read<TeamService>();
    final authService = context.read<AuthService>();
    final connectedPlayers = gameStateService.connectedPlayersList;
    final teams = teamService.teams;
    final currentUserId = authService.currentUser?.id;

    if (!gameStateService.isTerrainOpen) {
      return const Center(
        child: Text("Vous n'êtes pas connecté à un terrain"),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTeamInfo(),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Joueurs connectés (${connectedPlayers.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (connectedPlayers.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Aucun joueur connecté',
                        style: TextStyle(color: Colors.grey),
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
                      String teamName = "Sans équipe";
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
                          player['username'] ?? 'Joueur',
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
                            ? const Chip(
                                label: Text('Vous'),
                                backgroundColor: Colors.amber,
                                labelStyle: TextStyle(color: Colors.white),
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
    final teamService = context.read<TeamService>();
    final myTeamId = teamService.myTeamId;

    // Trouver l'équipe du joueur
    String teamName = "Aucune équipe";
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
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre équipe',
              style: TextStyle(
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
              label: const Text('Gérer les équipes'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer d\'équipe'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              final teamService = context.read<TeamService>();
              final isCurrentTeam = team.id == teamService.myTeamId;

              return ListTile(
                title: Text(team.name),
                subtitle: Text(
                    '${team.players.length} joueur${team.players.length != 1 ? 's' : ''}'),
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
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmationDialog(Field field) {
    final playerConnectionService = context.read<PlayerConnectionService>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter le terrain'),
        content: const Text(
            'Êtes-vous sûr de vouloir quitter ce terrain ? Vous ne pourrez pas la rejoindre à nouveau si elle est fermée.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              playerConnectionService.leaveField(field.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHistoryEntry(Field field) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce terrain ?'),
        content: const Text(
            'Voulez-vous vraiment supprimer ce terrain de votre historique ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final apiService = GetIt.I<ApiService>();
      await apiService.delete('fields-history/history/${field.id}');

      setState(
          () {}); // ❗ Recharge le FutureBuilder (déclenche à nouveau _loadPreviousFields)

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terrain supprimé de l’historique')),
      );
    } catch (e) {
      logger.d('❌ Erreur suppression terrain : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la suppression')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _navigateToGameSession(BuildContext context) {
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
            fieldId: gameStateService.selectedMap!.field!.id,
          ),
        ),
      );
    } else {
      logger.d(
          '❌ Impossible de rejoindre la partie : utilisateur ou session manquants');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de rejoindre la partie')),
      );
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
    super.dispose();
  }
}
