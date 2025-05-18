import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import '../../models/field.dart';
import '../../models/game_map.dart';
import '../../models/scenario/scenario_dto.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_session_service.dart';
import '../../services/player_connection_service.dart';
import '../../services/team_service.dart';
import '../../services/websocket_service.dart';
import '../../services/game_state_service.dart';
import '../gamesession/game_session_screen.dart';
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
    _webSocketService = context.read<WebSocketService>();
    _webSocketService.addListener(_updateConnectedPlayers);
  }

  @override
  void dispose() {
    _webSocketService.removeListener(_updateConnectedPlayers);
    super.dispose();
  }

  void _updateConnectedPlayers() {
    // Cette méthode sera appelée quand le WebSocketService notifie ses listeners
    final gameStateService = context.read<GameStateService>();
    final webSocketService = context.read<WebSocketService>();

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
    final gameStateService = context.read<GameStateService>();

    if (!gameStateService.isTerrainOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord ouvrir une carte'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedScenarios = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) =>
          ScenarioSelectionDialog(
            mapId: gameStateService.selectedMap!.id!,
          ),
    );

    if (selectedScenarios != null && selectedScenarios.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        gameStateService.setSelectedScenarios(selectedScenarios);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scénarios sélectionnés'),
            backgroundColor: Colors.green,
          ),
        );
      });
    }
  }

  void _setGameDuration() {
    final gameStateService = context.read<GameStateService>();

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
    final gameStateService = context.read<GameStateService>();
    final gameSessionService = context.read<GameSessionService>();
    final teamService = context.read<TeamService>();
    final teamId = teamService.myTeamId;

    final user = context.read<AuthService>().currentUser!;
    final field = gameStateService.selectedMap!.field;
    final isHost =user.hasRole('HOST') && field!.owner!.id! == user.id;

    print('🧩 [START] Lancement du jeu demandé');
    print('📋 Terrain ouvert ? ${gameStateService.isTerrainOpen}');
    print('📋 Scénarios sélectionnés : ${gameStateService.selectedScenarios?.length}');
    print('📋 User ID: ${user.id}, Host? $isHost, Team ID: $teamId');

    if (!gameStateService.isTerrainOpen) {
      print('❌ Terrain fermé, annulation');
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
      print('❌ Aucun scénario sélectionné, annulation');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un scénario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int fieldId = gameStateService.selectedMap!.field?.id ?? 0;
    int gameMapId = gameStateService.selectedMap!.id!;
    int duration = gameStateService.gameDuration ?? 0;

    print('🚀 Création de la GameSession (Field: $fieldId, Map: $gameMapId, Duration: $duration min)');

    gameSessionService.createGameSession( gameMapId, field!, duration).then((gameSession) {
      print('✅ GameSession créée avec succès : ID = ${gameSession.id}');

      gameSessionService.startGameSession(gameSession.id!).then((startedSession) {
        print('✅ Partie démarrée : ID = ${startedSession.id}, active=${startedSession.active}');
        print('🎮 Navigation vers GameSessionScreen...');
        gameStateService.setGameRunning(true);
        gameStateService.setActiveGameSession(startedSession);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameSessionScreen(
              userId: user.id!,
              teamId: teamId,
              isHost: isHost,
              gameSession: startedSession,
            ),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La partie a été lancée !'),
            backgroundColor: Colors.green,
          ),
        );
      }).catchError((e) {
        print('❌ Erreur lors du démarrage de la session : $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du démarrage de la session : $e'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }).catchError((error) {
      print('❌ Erreur lors de la création de la GameSession : $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du lancement de la partie : $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }


  void _stopGame() {
    final gameStateService = GetIt.I<GameStateService>();
    gameStateService.stopGameLocally();
    gameStateService.stopGameRemotely();

    // Logique pour arrêter la partie via WebSocket
    final webSocketService = GetIt.I<WebSocketService>();
    // webSocketService.stopGame();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La partie a été arrêtée'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _selectMap() async {
    final apiService = context.read<ApiService>();
    final gameStateService = context.read<GameStateService>();

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
    final gameStateService = context.read<GameStateService>();
    final apiService = context.read<ApiService>();
    final playerConnectionService = context.read<PlayerConnectionService>();
    GameMap selectedMap = gameStateService.selectedMap!;

    if (selectedMap == null) {
      print('❌ Aucune carte sélectionnée.');
      return;
    }

    try {
      Field? field = selectedMap.field;

      // 🔁 Si on ouvre le terrain
      if (!gameStateService.isTerrainOpen) {
        // 🧠 S’il n’y a pas encore de terrain, on en crée un
        if (field == null || field.closedAt != null) {
          print('🛠 Création d’un terrain via POST /fields...');
          final fieldResponse = await apiService.post('fields', {
            'name': 'Terrain de ${selectedMap.name}',
            'description': selectedMap.description ?? '',
          });
          field = Field.fromJson(fieldResponse);
          print('✅ Terrain créé avec ID: ${field.id}');

          // 🔁 Mise à jour de la GameMap pour lier le terrain
          final updatedMap = selectedMap.copyWith(field: field);
          final mapResponse = await apiService.put(
              'maps/${selectedMap.id}', updatedMap.toJson());
          selectedMap = GameMap.fromJson(mapResponse);
          gameStateService.selectMap(selectedMap);
        }

        final fieldId = field.id!;
        print('📡 Requête POST /fields/$fieldId/open');
        final response = await apiService.post('fields/$fieldId/open', {});
        print('✅ Terrain ouvert côté serveur : $response');
        gameStateService.setTerrainOpen(true);

        try {
          await gameStateService.connectHostToField();

          final players =
          await playerConnectionService.getConnectedPlayers(fieldId);
          final playersList = players
              .map((player) =>
          {
            'id': player.user.id,
            'username': player.user.username,
            'teamId': player.team?.id,
            'teamName': player.team?.name,
          })
              .toList();

          for (var player in playersList) {
            gameStateService.addConnectedPlayer(player);
          }

          print('✅ Joueurs connectés récupérés : ${playersList.length}');
        } catch (e) {
          print(
              'ℹ️ Aucun joueur connecté pour le moment (ou erreur mineure) : $e');
        }

        _webSocketService.subscribeToField(fieldId);
      } else {
        // 🔒 Fermeture du terrain
        final fieldId = field?.id;
        if (fieldId == null) {
          print('❌ Impossible de fermer : aucun terrain associé à la carte');
          return;
        }

        print('📡 Requête POST /fields/$fieldId/close');
        final response = await apiService.post('fields/$fieldId/close', {});
        print('✅ Terrain fermé côté serveur : $response');
        gameStateService.setTerrainOpen(false);

        // 🔄 Dissocier le terrain de la carte
        final updatedMap = selectedMap.copyWith(field: null);
        final mapResponse =
        await apiService.put('maps/${selectedMap.id}', updatedMap.toJson());
        print('🧹 Terrain dissocié de la carte');

        // 🧼 Réinitialisation de la carte sélectionnée
        gameStateService.selectMap(null);
      }
    } catch (e) {
      print('❌ Erreur lors de l’ouverture/fermeture du terrain : $e');
    }
  }

  // méthode pour gérer l'hôte comme joueur
  void _toggleHostAsPlayer() async {
    final gameStateService = context.read<GameStateService>();
    final authService = context.read<AuthService>();
    final playerConnectionService = context.read<PlayerConnectionService>();

    final user = authService.currentUser!;
    final mapId = gameStateService.selectedMap!.id;
    final fieldId = gameStateService.selectedMap!.field?.id;

    // Vérifier si l'hôte est déjà dans la liste des joueurs
    final isHostPlayer = gameStateService.isPlayerConnected(user.id!);

    try {
      if (!isHostPlayer) {
        // Ajouter l'hôte comme joueur
        await playerConnectionService.joinMap(fieldId!);

        // Ajouter manuellement l'hôte à la liste des joueurs
        gameStateService.addConnectedPlayer({
          'id': user.id,
          'username': user.username,
          'teamId': null,
          'teamName': null,
        });
      } else {
        // Retirer l'hôte de la liste des joueurs
        await playerConnectionService.leaveFieldForHost(fieldId!);

        // Retirer manuellement l'hôte de la liste des joueurs
        gameStateService.removeConnectedPlayer(user.id!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  Widget _buildSelectedMapCard(GameStateService gameStateService) {
    final selectedMap = gameStateService.selectedMap;
    if (selectedMap == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedMap.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (selectedMap.description != null && selectedMap.description!.isNotEmpty)
            Text(
              selectedMap.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (selectedMap.sourceAddress != null && selectedMap.sourceAddress!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: Colors.grey[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedMap.sourceAddress!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildInfoCards(GameStateService gameStateService) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceAround,
      children: [
        _buildInfoCard(
          icon: Icons.people,
          title: 'Joueurs',
          value: '${gameStateService.connectedPlayersList.length}',
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
    );
  }

  Widget _buildFieldStatus(GameStateService gameStateService) {
    return Container(
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
              color: gameStateService.isTerrainOpen ? Colors.green : Colors.red,
            ),
          ),
          if (gameStateService.selectedMap != null)
            ElevatedButton.icon(
              onPressed: _toggleTerrainOpen,
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
    );
  }

  Widget _buildGameConfiguration(GameStateService gameStateService) {
    return Column(
      children: [
        Text(
          'Configuration de la partie',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: gameStateService.isTerrainOpen ? null : _selectMap,
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
                onPressed: gameStateService.isTerrainOpen ? _selectScenarios : null,
                icon: const Icon(Icons.videogame_asset),
                label: const Text('Choisir scénarios'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: gameStateService.isTerrainOpen ? _setGameDuration : null,
                icon: const Icon(Icons.timer),
                label: const Text('Définir durée'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
                value: gameStateService.isPlayerConnected(context.read<AuthService>().currentUser!.id!),
                onChanged: gameStateService.isTerrainOpen
                    ? (value) => _toggleHostAsPlayer()
                    : null,
                activeColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
        const SizedBox(height: 24),
        gameStateService.isGameRunning
            ? Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final user = context.read<AuthService>().currentUser!;
                  final teamId = context.read<TeamService>().myTeamId;
                  final field = gameStateService.selectedMap!.field;
                  final isHost = user.hasRole('HOST') && field!.owner!.id! == user.id;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameSessionScreen(
                        gameSession: gameStateService.activeGameSession!,
                        userId: user.id!,
                        teamId: teamId,
                        isHost: isHost,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Rejoindre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _stopGame,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Arrêter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        )
            : SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: gameStateService.isTerrainOpen &&
                (gameStateService.selectedScenarios?.isNotEmpty ?? false)
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
        ),
      ],
    );
  }

  Widget _buildConnectedPlayersList(GameStateService gameStateService, AuthService authService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            final isHost = player['id'] == authService.currentUser!.id;
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
                  fontWeight: isHost ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildSelectedScenarios(GameStateService gameStateService) {
    final scenarios = gameStateService.selectedScenarios ?? [];

    if (scenarios.isEmpty) {
      return const SizedBox(); // Aucun scénario sélectionné
    }

    final bigScenarios = scenarios.where((s) => s.treasureHuntScenario?.size == 'BIG').toList();
    final smallScenarios = scenarios.where((s) => s.treasureHuntScenario?.size != 'BIG').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scénarios sélectionnés',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (bigScenarios.isNotEmpty) ...[
          _buildScenarioCard(bigScenarios.first, isBig: true),
        ],
        const SizedBox(height: 8),
        ...smallScenarios.map((scenario) => _buildScenarioCard(scenario)).toList(),
      ],
    );
  }

  Widget _buildScenarioCard(ScenarioDTO scenarioDTO, {bool isBig = false}) {
    final name = scenarioDTO.scenario.name;
    final description = scenarioDTO.scenario.description;
    final treasureHuntData = scenarioDTO.treasureHuntScenario;

    String subtitle = '';
    if (treasureHuntData != null) {
      final totalTreasures = treasureHuntData.totalTreasures;
      final symbol = treasureHuntData.defaultSymbol;
      subtitle = 'Chasse au trésor : $totalTreasures trésors à collecter ($symbol)';
    } else if (description != null && description.isNotEmpty) {
      subtitle = description;
    }

    return Card(
      color: isBig ? Colors.amber.shade100 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isBig ? 20 : 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: isBig ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final gameStateService = context.watch<GameStateService>();
    final authService = context.watch<AuthService>();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSelectedMapCard(gameStateService),
            const SizedBox(height: 16),
            _buildInfoCards(gameStateService),
            const SizedBox(height: 16),
            _buildSelectedScenarios(gameStateService),
            const SizedBox(height: 16),
            _buildFieldStatus(gameStateService),
            const SizedBox(height: 16),
            _buildGameConfiguration(gameStateService),
            const SizedBox(height: 32),
            _buildConnectedPlayersList(gameStateService, authService),
          ],
        ),
      ),
    );
  }



}