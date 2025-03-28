import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import '../../models/field.dart';
import '../../models/game_map.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/player_connection_service.dart';
import '../../services/team_service.dart';
import '../../services/websocket_service.dart';
import '../../services/game_state_service.dart';
import 'scenario_selection_dialog.dart';

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

    // Ouvre la boîte de dialogue et récupère les scénarios sélectionnés
    final selectedScenarios = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) => ScenarioSelectionDialog(
        mapId: gameStateService.selectedMap!.id!,
        onScenariosSelected: (scenarios) {
          Navigator.of(context).pop(scenarios); // Retourne la sélection
        },
      ),
    );

    // Si des scénarios ont été sélectionnés
    if (selectedScenarios != null && selectedScenarios.isNotEmpty) {
      gameStateService.setSelectedScenarios(selectedScenarios);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scénario sélectionné'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
    // Utiliser le sélecteur de type "roue" pour les heures et minutes
    DatePicker.showTimePicker(
      context,
      showSecondsColumn: false,
      onChanged: (time) {
        // Mise à jour en temps réel pendant que l'utilisateur fait défiler
      },
      onConfirm: (time) {
        // Calculer la durée en minutes
        int minutes = time.hour * 60 + time.minute;
        gameStateService.setGameDuration(minutes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Durée définie: ${time.hour}h ${time.minute}min'),
            backgroundColor: Colors.green,
          ),
        );
      },
      currentTime: DateTime(2022, 1, 1, 0, 0),
      // Commencer à 00:00
      locale: LocaleType.fr,
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
    final gameStateService =
        Provider.of<GameStateService>(context, listen: false);

    try {
      final List<dynamic> mapData = await apiService.get('maps/owner/self');
      final List<GameMap> maps =
          mapData.map((json) => GameMap.fromJson(json)).toList();

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

  void _toggleTerrainOpen() async {
    final gameStateService = Provider.of<GameStateService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final playerConnectionService = Provider.of<PlayerConnectionService>(context, listen: false);
    GameMap selectedMap = gameStateService.selectedMap!;

    if (selectedMap == null) {
      print('❌ Aucune carte sélectionnée.');
      return;
    }

    int? fieldId = selectedMap.field?.id;

    try {
      // 1️⃣ Créer un terrain si la carte n’en a pas encore
      if (fieldId == null) {
        print('🛠 Création d’un terrain via POST /fields...');
        final fieldResponse  = await apiService.post('fields', {
          'name': 'Terrain de ${selectedMap.name}',
          'description': selectedMap.description ?? '',
        });

        final field = Field.fromJson(fieldResponse);

        print('✅ Terrain créé avec ID: $field.id');

        // 2️⃣ Mise à jour de la GameMap avec ce fieldId via PUT
        final updatedMap = selectedMap.copyWith(field: field);
        final updatedJson = updatedMap.toJson();

        print('field ajouté à la map : $updatedJson');

        print('🔁 Mise à jour GameMap via PUT /maps/${selectedMap.id}');
        final mapResponse = await apiService.put('maps/${selectedMap.id}', updatedJson);

        selectedMap = GameMap.fromJson(mapResponse);

        print('✅ GameMap mise à jour avec : ${selectedMap.id}');
        gameStateService.selectMap(selectedMap);
      }

      // 3️⃣ Ouvrir ou fermer le terrain
      if (!gameStateService.isTerrainOpen) {
        print('📡 Requête POST /fields/$fieldId/open');
        final response = await apiService.post('fields/$fieldId/open', {});
        print('✅ Terrain ouvert côté serveur : $response');
        gameStateService.setTerrainOpen(true);
      } else {
        print('📡 Requête POST /fields/$fieldId/close');
        final response = await apiService.post('fields/$fieldId/close', {});
        print('✅ Terrain fermé côté serveur : $response');
        gameStateService.setTerrainOpen(false);
      }

      // 4️⃣ Récupération des joueurs (si terrain ouvert)
      if (gameStateService.isTerrainOpen) {
        try {
          final players = await playerConnectionService.getConnectedPlayers(selectedMap.id!);

          final playersList = players.map((player) => {
            'id': player.user.id,
            'username': player.user.username,
            'teamId': player.team?.id,
            'teamName': player.team?.name,
          }).toList();

          for (var player in playersList) {
            gameStateService.addConnectedPlayer(player);
          }

          print('✅ Joueurs connectés récupérés : ${playersList.length}');
        } catch (e) {
          // 👉 Ici on ne considère plus ça comme une vraie erreur
          print('ℹ️ Aucun joueur connecté pour le moment (ou erreur mineure) : $e');
        }
      }

    } catch (e) {
      print('❌ Erreur lors de l’ouverture/fermeture du terrain : $e');
    }
  }




  // méthode pour gérer l'hôte comme joueur
  void _toggleHostAsPlayer() async {
    final gameStateService =
        Provider.of<GameStateService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final playerConnectionService =
        Provider.of<PlayerConnectionService>(context, listen: false);

    final user = authService.currentUser!;
    final mapId = gameStateService.selectedMap!.id;

    // Vérifier si l'hôte est déjà dans la liste des joueurs
    final isHostPlayer = gameStateService.isPlayerConnected(user.id!);

    try {
      if (!isHostPlayer) {
        // Ajouter l'hôte comme joueur
        await playerConnectionService.joinMap(mapId!);

        // Ajouter manuellement l'hôte à la liste des joueurs
        gameStateService.addConnectedPlayer({
          'id': user.id,
          'username': user.username,
          'teamId': null,
          'teamName': null,
        });
      } else {
        // Retirer l'hôte de la liste des joueurs
        await playerConnectionService.leaveMap(mapId!);

        // Retirer manuellement l'hôte de la liste des joueurs
        gameStateService.removeConnectedPlayer(user.id!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final gameStateService = Provider.of<GameStateService>(context);
    final authService = Provider.of<AuthService>(context);
    final teamService = Provider.of<TeamService>(context);
    final connectedPlayers = gameStateService.connectedPlayersList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'), // ✅ Nouveau titre
        actions: [
          Switch(
            value: gameStateService.isTerrainOpen,
            onChanged: gameStateService.selectedMap != null
                ? (value) => _toggleTerrainOpen()
                : null,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bloc d'informations
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tableau de bord',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceAround,
                    children: [
                      _buildInfoCard(
                        icon: Icons.map,
                        title: 'Carte active',
                        value: gameStateService.selectedMap?.name ?? 'Aucune',
                      ),
                      _buildInfoCard(
                        icon: Icons.people,
                        title: 'Joueurs',
                        value:
                        '${gameStateService.connectedPlayersList.length}',
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
            const SizedBox(height: 16),

            // Statut du terrain
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: gameStateService.isTerrainOpen
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
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
                      onPressed: () => _toggleTerrainOpen(),
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
            const SizedBox(height: 16),

            // Configuration de la partie
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
            const SizedBox(height: 16),

            // Switch pour que l'hôte rejoigne comme joueur
            if (gameStateService.selectedMap != null)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Participer en tant que joueur :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Switch(
                    value: gameStateService
                        .isPlayerConnected(authService.currentUser!.id!),
                    onChanged: gameStateService.isTerrainOpen
                        ? (value) => _toggleHostAsPlayer()
                        : null,
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),

            const SizedBox(height: 24),
            // Bouton Start/Stop
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

            const SizedBox(height: 32),

            // ✅ Liste des joueurs connectés (scrollable vers le bas)
            Text(
              'Joueurs connectés',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            gameStateService.connectedPlayersList.isNotEmpty
                ? ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gameStateService.connectedPlayersList.length,
              itemBuilder: (context, index) {
                final player = gameStateService.connectedPlayersList[index];
                final isHost =
                    player['id'] == authService.currentUser!.id;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isHost
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade400,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    player['username'] ?? 'Joueur',
                    style: TextStyle(
                      fontWeight:
                      isHost ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    player['teamName'] != null
                        ? 'Équipe: ${player['teamName']}'
                        : 'Sans équipe',
                  ),
                  trailing: isHost ? const Text('Vous (Hôte)') : null,
                );
              },
            )
                : const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Aucun joueur connecté',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
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
