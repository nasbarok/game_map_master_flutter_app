# Liste des fichiers à ajouter ou modifier

## Côté serveur (Spring Boot)

### Fichiers à ajouter

#### Modèles
- `src/main/java/com/airsoft/gamemapmaster/model/ConnectedPlayer.java`

#### Repositories
- `src/main/java/com/airsoft/gamemapmaster/repository/ConnectedPlayerRepository.java`
- `src/main/java/com/airsoft/gamemapmaster/repository/InvitationRepository.java`

#### Services
- `src/main/java/com/airsoft/gamemapmaster/service/ConnectedPlayerService.java`
- `src/main/java/com/airsoft/gamemapmaster/service/InvitationService.java`
- `src/main/java/com/airsoft/gamemapmaster/service/impl/ConnectedPlayerServiceImpl.java`
- `src/main/java/com/airsoft/gamemapmaster/service/impl/InvitationServiceImpl.java`

#### Contrôleurs
- `src/main/java/com/airsoft/gamemapmaster/controller/PlayerConnectionController.java`
- `src/main/java/com/airsoft/gamemapmaster/controller/InvitationController.java`
- `src/main/java/com/airsoft/gamemapmaster/controller/GameSessionController.java`

#### Tests
- `src/test/java/com/airsoft/gamemapmaster/controller/PlayerConnectionControllerTest.java`
- `src/test/java/com/airsoft/gamemapmaster/controller/InvitationControllerTest.java`
- `src/test/java/com/airsoft/gamemapmaster/controller/GameSessionControllerTest.java`

#### Documentation
- `API_DOCUMENTATION.md`
- `IMPLEMENTATION_REPORT.md`

### Fichiers à modifier

#### Configuration de la base de données
- Ajouter une définition de table pour `connected_players` dans le fichier changelog-master.yaml :

```yaml
databaseChangeLog:
  - changeSet:
      id: create-connected-players-table
      author: developer
      changes:
        - createTable:
            tableName: connected_players
            columns:
              - column:
                  name: id
                  type: bigint
                  autoIncrement: true
                  constraints:
                    primaryKey: true
                    nullable: false
              - column:
                  name: user_id
                  type: bigint
                  constraints:
                    nullable: false
                    foreignKeyName: fk_connected_player_user
                    references: users(id)
              - column:
                  name: game_map_id
                  type: bigint
                  constraints:
                    nullable: false
                    foreignKeyName: fk_connected_player_game_map
                    references: game_maps(id)
              - column:
                  name: team_id
                  type: bigint
                  constraints:
                    nullable: true
                    foreignKeyName: fk_connected_player_team
                    references: teams(id)
              - column:
                  name: joined_at
                  type: datetime
                  constraints:
                    nullable: false
              - column:
                  name: active
                  type: boolean
                  defaultValueBoolean: true
                  constraints:
                    nullable: false
        - addUniqueConstraint:
            tableName: connected_players
            columnNames: user_id, game_map_id
            constraintName: uk_connected_player_user_map
```

## Côté client (Flutter)

Après avoir examiné les modifications récentes dans le dépôt Flutter, je constate que vous avez déjà commencé à implémenter les fonctionnalités côté client. Voici les fichiers que vous avez modifiés :

- `lib/app.dart`
- `lib/screens/gamer/game_lobby_screen.dart`
- `lib/services/game_state_service.dart`
- `lib/services/invitation_service.dart`
- `lib/widgets/websocket_handler.dart`

### Modifications à apporter

Pour compléter l'intégration avec les nouveaux endpoints du serveur, vous devrez ajouter ou modifier les fichiers suivants :

#### Modèles à ajouter
- `lib/models/connected_player.dart` - Pour représenter un joueur connecté

#### Services à ajouter ou modifier
- `lib/services/player_connection_service.dart` - Pour interagir avec les endpoints de connexion des joueurs

Le service `PlayerConnectionService` devrait implémenter les méthodes suivantes :

```dart
class PlayerConnectionService {
  final String baseUrl;
  final http.Client client;

  PlayerConnectionService({required this.baseUrl, required this.client});

  // Rejoindre une carte
  Future<ConnectedPlayer> joinMap(int mapId, {int? teamId}) async {
    final url = '$baseUrl/api/maps/$mapId/join';
    final queryParams = teamId != null ? {'teamId': teamId.toString()} : {};
    
    final response = await client.post(
      Uri.parse(url).replace(queryParameters: queryParams),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 201) {
      return ConnectedPlayer.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to join map: ${response.body}');
    }
  }

  // Quitter une carte
  Future<void> leaveMap(int mapId) async {
    final url = '$baseUrl/api/maps/$mapId/leave';
    
    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to leave map: ${response.body}');
    }
  }

  // Obtenir la liste des joueurs connectés
  Future<List<ConnectedPlayer>> getConnectedPlayers(int mapId) async {
    final url = '$baseUrl/api/maps/$mapId/players';
    
    final response = await client.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final List<dynamic> playersJson = jsonDecode(response.body);
      return playersJson.map((json) => ConnectedPlayer.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get connected players: ${response.body}');
    }
  }

  // Fermer une carte (pour le propriétaire)
  Future<void> closeMap(int mapId) async {
    final url = '$baseUrl/api/maps/$mapId/close';
    
    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to close map: ${response.body}');
    }
  }

  // Assigner un joueur à une équipe
  Future<ConnectedPlayer> assignPlayerToTeam(int mapId, int userId, int teamId) async {
    final url = '$baseUrl/api/maps/$mapId/players/$userId/team/$teamId';
    
    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return ConnectedPlayer.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to assign player to team: ${response.body}');
    }
  }
}
```

#### Modifications au service d'invitation existant

Votre service d'invitation actuel utilise WebSocket pour la communication en temps réel. Pour l'intégrer avec les nouveaux endpoints REST, vous devrez ajouter les méthodes suivantes :

```dart
// Récupérer toutes les invitations pour l'utilisateur connecté
Future<List<Invitation>> getMyInvitations() async {
  final url = '$baseUrl/api/invitations/me';
  
  final response = await client.get(Uri.parse(url));
  
  if (response.statusCode == 200) {
    final List<dynamic> invitationsJson = jsonDecode(response.body);
    return invitationsJson.map((json) => Invitation.fromJson(json)).toList();
  } else {
    throw Exception('Failed to get invitations: ${response.body}');
  }
}

// Récupérer les invitations en attente
Future<List<Invitation>> getMyPendingInvitations() async {
  final url = '$baseUrl/api/invitations/me/pending';
  
  final response = await client.get(Uri.parse(url));
  
  if (response.statusCode == 200) {
    final List<dynamic> invitationsJson = jsonDecode(response.body);
    return invitationsJson.map((json) => Invitation.fromJson(json)).toList();
  } else {
    throw Exception('Failed to get pending invitations: ${response.body}');
  }
}

// Accepter une invitation
Future<Invitation> acceptInvitation(int invitationId) async {
  final url = '$baseUrl/api/invitations/$invitationId/accept';
  
  final response = await client.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
  );
  
  if (response.statusCode == 200) {
    return Invitation.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to accept invitation: ${response.body}');
  }
}

// Refuser une invitation
Future<Invitation> declineInvitation(int invitationId) async {
  final url = '$baseUrl/api/invitations/$invitationId/decline';
  
  final response = await client.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
  );
  
  if (response.statusCode == 200) {
    return Invitation.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to decline invitation: ${response.body}');
  }
}
```

#### Modifications au service de gestion des sessions de jeu

Vous devrez également ajouter un service pour interagir avec les endpoints de gestion des sessions de jeu :

```dart
class GameSessionService {
  final String baseUrl;
  final http.Client client;

  GameSessionService({required this.baseUrl, required this.client});

  // Démarrer une partie
  Future<void> startGame(int mapId, int scenarioId) async {
    final url = '$baseUrl/api/games/maps/$mapId/start';
    final queryParams = {'scenarioId': scenarioId.toString()};
    
    final response = await client.post(
      Uri.parse(url).replace(queryParameters: queryParams),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to start game: ${response.body}');
    }
  }

  // Terminer une partie
  Future<void> endGame(int mapId) async {
    final url = '$baseUrl/api/games/maps/$mapId/end';
    
    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to end game: ${response.body}');
    }
  }
}
```

Ces modifications vous permettront d'intégrer complètement les nouveaux endpoints du serveur avec votre application Flutter.
