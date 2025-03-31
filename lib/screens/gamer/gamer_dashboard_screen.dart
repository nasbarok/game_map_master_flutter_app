import 'package:airsoft_game_map/models/websocket/websocket_message.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/field.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../../services/team_service.dart';
import '../../services/websocket_service.dart';
import 'join_team_screen.dart';
import 'qr_code_scanner_screen.dart';
import 'package:go_router/go_router.dart';

class GamerDashboardScreen extends StatefulWidget {
  const GamerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<GamerDashboardScreen> createState() => _GamerDashboardScreenState();
}

class _GamerDashboardScreenState extends State<GamerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    // Initialiser avec un seul onglet par défaut
    _tabController = TabController(length: 1, vsync: this);

    // Connecter au WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final webSocketService =
          Provider.of<WebSocketService>(context, listen: false);
      webSocketService.connect();
    });
    // Vérifier si le joueur est connecté à un terrain
    final gameStateService =
        Provider.of<GameStateService>(context, listen: false);
    if (gameStateService.isTerrainOpen) {
      // Si connecté, ajouter l'onglet Joueurs
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final gameStateService = Provider.of<GameStateService>(context);

    // Déterminer le nombre d'onglets en fonction de l'état de connexion
    final bool isConnectedToField = gameStateService.isTerrainOpen;

    // Si le nombre d'onglets a changé, mettre à jour le TabController
    if ((isConnectedToField && _tabController.length != 2) ||
        (!isConnectedToField && _tabController.length != 1)) {
      _tabController.dispose();
      _tabController = TabController(
        length: isConnectedToField ? 2 : 1,
        vsync: this,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (mounted) {
                context.go('/login');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(icon: Icon(Icons.map), text: 'Terrain'),
            if (isConnectedToField)
              const Tab(icon: Icon(Icons.people), text: 'Joueurs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Terrain
          _buildTerrainTab(),
          // Onglet Joueurs (conditionnel)
          if (isConnectedToField) _buildPlayersTab(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action en fonction de l'onglet actif
          if (_tabController.index == 0 && !isConnectedToField) {
            _showScanQRCodeDialog(context);
          } else if (_tabController.index == 1 || isConnectedToField) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const JoinTeamScreen()),
            );
          }
        },
        child: Icon(_tabController.index == 0 && !isConnectedToField
            ? Icons.qr_code_scanner
            : Icons.group_add),
      ),
    );
  }

  Widget _buildTerrainTab() {
    final gameState = Provider.of<GameStateService>(context);

    if (!gameState.isTerrainOpen || gameState.selectedMap == null) {
      // Afficher la liste des anciens terrains
      return _buildPreviousFieldsList();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Carte : ${gameState.selectedMap?.name ?? "Inconnue"}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Scénario : ${gameState.selectedScenarios != null && gameState.selectedScenarios!.isNotEmpty ? gameState.selectedScenarios!.first['name'] ?? 'Inconnu' : 'Aucun'}',
          ),
          const SizedBox(height: 8),
          if (gameState.timeLeftDisplay != null)
            Text('Temps restant : ${gameState.timeLeftDisplay}'),
          const Spacer(),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                _showLeaveConfirmationDialog();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Quitter la partie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
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
                  'Scannez un QR code pour rejoindre un terrain',
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
            final isOpen = field.active ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isOpen ? Colors.green : Colors.grey,
                  child: Icon(
                    Icons.map,
                    color: Colors.white,
                  ),
                ),
                title: Text(field.name ?? 'Terrain sans nom'),
                subtitle: Text(isOpen ? 'Ouvert' : 'Fermé'),
                trailing: isOpen
                    ? ElevatedButton(
                        onPressed: () => _joinField(field.id!),
                        child: const Text('Rejoindre'),
                      )
                    : null,
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
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get('fields/history');

      if (response == null || !(response is List)) {
        return [];
      }

      return (response as List).map((data) => Field.fromJson(data)).toList();
    } catch (e) {
      print('❌ Erreur lors du chargement des terrains: $e');
      return [];
    }
  }

  // Méthode pour rejoindre un terrain
  Future<void> _joinField(int fieldId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final gameStateService =
          Provider.of<GameStateService>(context, listen: false);

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

        // Mettre à jour le TabController si nécessaire
        if (_tabController.length != 2) {
          _tabController.dispose();
          _tabController = TabController(length: 2, vsync: this);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez rejoint le terrain avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la connexion au terrain: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLeaveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la partie'),
        content: const Text('Êtes-vous sûr de vouloir quitter cette partie ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveField();
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

  Future<void> _leaveField() async {
    try {
      final gameStateService =
          Provider.of<GameStateService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final webSocketService =
          Provider.of<WebSocketService>(context, listen: false);

      if (gameStateService.selectedMap == null ||
          authService.currentUser == null) {
        return;
      }

      final fieldId = gameStateService.selectedMap!.field!.id;
      final userId = authService.currentUser!.id;

      // Envoyer un message WebSocket pour quitter le terrain
      await webSocketService.sendMessage(
          '/app/leave-field',
          {
            'fieldId': fieldId,
            'userId': userId,
          } as WebSocketMessage);

      // Réinitialiser l'état du jeu
      gameStateService.reset();

      // Mettre à jour le TabController
      if (_tabController.length != 1) {
        _tabController.dispose();
        _tabController = TabController(length: 1, vsync: this);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez quitté le terrain'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('❌ Erreur lors de la déconnexion du terrain: $e');
    }
  }

  Widget _buildPlayersTab(BuildContext context) {
    final teamService = Provider.of<TeamService>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.id;

    final players = teamService.connectedPlayers;
    final myTeamId = teamService.myTeamId;

    if (players.isEmpty) {
      return const Center(
        child: Text('Aucun joueur connecté.'),
      );
    }

    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final isMe = player['id'] == currentUserId;
        final isSameTeam = player['teamId'] == myTeamId;

        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(player['username'] ?? 'Joueur'),
          subtitle: Text(isSameTeam ? 'Dans votre équipe' : 'Autre équipe'),
          trailing: isMe
              ? ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JoinTeamScreen()),
                    );
                  },
                  child: const Text('Changer d\'équipe'),
                )
              : null,
        );
      },
    );
  }

  void _showScanQRCodeDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRCodeScannerScreen()),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
