import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_map.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/websocket_service.dart';
import '../../services/game_state_service.dart';

class TerrainDashboardScreen extends StatefulWidget {
  const TerrainDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TerrainDashboardScreen> createState() => _TerrainDashboardScreenState();
}

class _TerrainDashboardScreenState extends State<TerrainDashboardScreen> {
  late WebSocketService _webSocketService;

  @override
  void initState() {
    super.initState();
    // Rien ici pour WebSocketService
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialisation sûre ici
    _webSocketService = Provider.of<WebSocketService>(context, listen: false);
    _webSocketService.addListener(_updateConnectedPlayers);
  }

  @override
  void dispose() {
    _webSocketService.removeListener(_updateConnectedPlayers);
    super.dispose();
  }

  void _updateConnectedPlayers() {
    // Cette méthode sera appelée quand le WebSocketService notifie ses listeners
    final gameStateService =
        Provider.of<GameStateService>(context, listen: false);
    final webSocketService =
        Provider.of<WebSocketService>(context, listen: false);

    // Pour l'instant, simulons un nombre aléatoire de joueurs connectés
    if (gameStateService.isTerrainOpen) {
      // Dans une implémentation réelle, vous récupéreriez le nombre de joueurs connectés
      // gameStateService.updateConnectedPlayers(webSocketService.connectedPlayers.length);

      // Simulation pour le développement
      gameStateService
          .updateConnectedPlayers(gameStateService.connectedPlayers);
    }
  }

  void _selectScenarios() async {
    final gameStateService =
        Provider.of<GameStateService>(context, listen: false);

    if (!gameStateService.isTerrainOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord ouvrir une carte'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ici, vous afficheriez une boîte de dialogue pour sélectionner des scénarios
    // Pour l'instant, simulons une sélection
    gameStateService.setSelectedScenarios([
      {"id": 1, "name": "Scénario test"}
    ]);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scénario sélectionné'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _setGameDuration() {
    final gameStateService =
        Provider.of<GameStateService>(context, listen: false);

    if (!gameStateService.isTerrainOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord ouvrir une carte'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Définir la durée de la partie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Durée en minutes (laisser vide pour aucune limite)'),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final duration = value.isEmpty ? null : int.tryParse(value);
                gameStateService.setGameDuration(duration);
              },
              decoration: InputDecoration(
                hintText: 'Ex: 60',
                helperText: gameStateService.gameDuration == null
                    ? 'Aucune limite de temps'
                    : 'La partie durera ${gameStateService.gameDuration} minutes',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    final gameStateService =
        Provider.of<GameStateService>(context, listen: false);

    if (!gameStateService.isTerrainOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord ouvrir une carte'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (gameStateService.selectedScenarios == null ||
        gameStateService.selectedScenarios!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un scénario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    gameStateService.startGame();

    // Logique pour démarrer la partie via WebSocket
    final webSocketService =
        Provider.of<WebSocketService>(context, listen: false);
    // webSocketService.startGame(gameStateService.selectedMap!.id, gameStateService.selectedScenarios, gameStateService.gameDuration);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La partie a été lancée !'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _stopGame() {
    final gameStateService =
        Provider.of<GameStateService>(context, listen: false);
    gameStateService.stopGame();

    // Logique pour arrêter la partie via WebSocket
    final webSocketService =
        Provider.of<WebSocketService>(context, listen: false);
    // webSocketService.stopGame();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La partie a été arrêtée'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _selectMap() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final gameStateService = Provider.of<GameStateService>(context, listen: false);

    try {
      final List<dynamic> mapData = await apiService.get('maps/owner/self');
      final List<GameMap> maps = mapData.map((json) => GameMap.fromJson(json)).toList();

      if (maps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune carte disponible'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      GameMap? tempSelectedMap = maps.first;

      showDialog<GameMap>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Sélectionner une carte'),
                content: DropdownButton<GameMap>(
                  isExpanded: true,
                  value: tempSelectedMap,
                  onChanged: (GameMap? newMap) {
                    setState(() {
                      tempSelectedMap = newMap;
                    });
                  },
                  items: maps.map((map) {
                    return DropdownMenuItem<GameMap>(
                      value: map,
                      child: Text(map.name),
                    );
                  }).toList(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(tempSelectedMap);
                    },
                    child: const Text('Valider'),
                  ),
                ],
              );
            },
          );
        },
      ).then((selectedMap) {
        if (selectedMap != null) {
          gameStateService.selectMap(selectedMap);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Carte "${selectedMap.name}" sélectionnée'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des cartes : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final gameStateService = Provider.of<GameStateService>(context);

    return _buildTerrainDashboard();
  }

  Widget _buildTerrainDashboard() {
    final gameStateService = Provider.of<GameStateService>(context);

    return Column(
      children: [
        // En-tête avec informations sur la carte ouverte
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tableau de bord',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoCard(
                    icon: Icons.map,
                    title: 'Carte active',
                    value: gameStateService.selectedMap?.name ?? 'Aucune',
                  ),
                  _buildInfoCard(
                    icon: Icons.people,
                    title: 'Joueurs',
                    value: '${gameStateService.connectedPlayers}',
                  ),
                  _buildInfoCard(
                    icon: Icons.videogame_asset,
                    title: 'Scénarios',
                    value: gameStateService.selectedScenarios?.isEmpty ?? true
                        ? 'Aucun'
                        : '${gameStateService.selectedScenarios!.length}',
                  ),
                  _buildInfoCard(
                    icon: Icons.timer,
                    title: 'Durée',
                    value: gameStateService.gameDuration == null
                        ? 'Illimitée'
                        : '${gameStateService.gameDuration} min',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Statut du terrain
        Container(
          padding: const EdgeInsets.all(16),
          color: gameStateService.isTerrainOpen
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statut: ${gameStateService.isTerrainOpen ? "Terrain ouvert" : "Terrain fermé"}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: gameStateService.isTerrainOpen
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              if (gameStateService.selectedMap != null)
                ElevatedButton.icon(
                  onPressed: () {
                    gameStateService.toggleTerrainOpen();
                  },
                  icon: Icon(gameStateService.isTerrainOpen
                      ? Icons.close
                      : Icons.door_front_door),
                  label: Text(gameStateService.isTerrainOpen
                      ? 'Fermer le terrain'
                      : 'Ouvrir le terrain'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gameStateService.isTerrainOpen
                        ? Colors.red
                        : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),

        // Contrôles pour la partie
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configuration de la partie',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _selectMap,
                icon: const Icon(Icons.map),
                label: Text(
                  gameStateService.selectedMap != null
                      ? 'Carte : ${gameStateService.selectedMap!.name}'
                      : 'Choisir une carte',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: gameStateService.isTerrainOpen
                          ? _selectScenarios
                          : null,
                      icon: const Icon(Icons.videogame_asset),
                      label: const Text('Choisir scénarios'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: gameStateService.isTerrainOpen
                          ? _setGameDuration
                          : null,
                      icon: const Icon(Icons.timer),
                      label: const Text('Définir durée'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              gameStateService.isGameRunning
                  ? ElevatedButton.icon(
                      onPressed: _stopGame,
                      icon: const Icon(Icons.stop),
                      label: const Text('Arrêter la partie'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: gameStateService.isTerrainOpen &&
                              (gameStateService.selectedScenarios?.isNotEmpty ??
                                  false)
                          ? _startGame
                          : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Lancer la partie'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
            ],
          ),
        ),

        // Informations sur les joueurs connectés
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Joueurs connectés',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: gameStateService.connectedPlayers > 0
                      ? ListView.builder(
                          itemCount: gameStateService.connectedPlayers,
                          itemBuilder: (context, index) {
                            // Simuler des joueurs pour l'exemple
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text('Joueur ${index + 1}'),
                              subtitle: Text(
                                  'Équipe: ${index % 2 == 0 ? "Rouge" : "Bleu"}'),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            'Aucun joueur connecté',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon),
            Text(title, style: const TextStyle(fontSize: 12)),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
