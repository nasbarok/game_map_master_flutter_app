# Instructions d'intégration des nouvelles fonctionnalités

Ce document explique comment intégrer les nouvelles fonctionnalités dans votre application Flutter "game_map_master_flutter_app".

## Dépendances requises

Ajoutez la dépendance suivante à votre fichier `pubspec.yaml` :

```yaml
dependencies:
  flutter_datetime_picker_plus: ^2.1.0
```

Puis exécutez :

```
flutter pub get
```

## Fichiers modifiés et nouveaux fichiers

1. **Services**
   - `lib/services/game_state_service.dart` - Mise à jour pour le décompte synchronisé
   - `lib/services/invitation_service.dart` - Nouveau service pour la gestion des invitations
   - `lib/services/team_service.dart` - Nouveau service pour la gestion des équipes

2. **Modèles**
   - `lib/models/team.dart` - Nouveau modèle pour les équipes

3. **Écrans**
   - `lib/screens/host/terrain_dashboard_screen.dart` - Mise à jour avec le sélecteur de temps amélioré
   - `lib/screens/host/players_screen.dart` - Nouvel écran pour la gestion des joueurs et des équipes

## Modifications à apporter à votre code existant

### 1. Mise à jour de `lib/app.dart`

Ajoutez les nouveaux services au Provider :

```dart
return MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthService()),
    ChangeNotifierProvider(create: (_) => ApiService()),
    ChangeNotifierProvider(create: (_) => WebSocketService()),
    ChangeNotifierProvider(create: (_) => GameStateService()),
    // Nouveaux services
    ProxyProvider3<WebSocketService, AuthService, GameStateService, InvitationService>(
      update: (_, webSocketService, authService, gameStateService, __) => 
          InvitationService(webSocketService, authService, gameStateService),
    ),
    ProxyProvider2<ApiService, GameStateService, TeamService>(
      update: (_, apiService, gameStateService, __) => 
          TeamService(apiService, gameStateService),
    ),
  ],
  child: MaterialApp.router(
    // ...
  ),
);
```

### 2. Mise à jour de `lib/screens/host/host_dashboard_screen.dart`

Remplacez l'onglet "Joueurs" par le nouvel écran PlayersScreen :

```dart
// Onglet Joueurs (équipes)
gameStateService.isTerrainOpen 
    ? const PlayersScreen() 
    : _buildDisabledTeamsTab(),
```

N'oubliez pas d'ajouter l'import :

```dart
import 'players_screen.dart';
```

## Fonctionnalités implémentées

### 1. Sélecteur de temps amélioré (type "roue")
- Implémenté dans `terrain_dashboard_screen.dart` avec la méthode `_setGameDuration()`
- Utilise le package `flutter_datetime_picker_plus` pour une interface intuitive

### 2. Décompte sur le bouton de partie lancée
- Implémenté dans `game_state_service.dart` avec les méthodes `startGame()` et `_startGameTimer()`
- Affiche le temps restant au format HH:MM:SS sur le bouton d'arrêt de partie
- Synchronisé via WebSocket pour tous les joueurs

### 3. Système d'invitations
- Implémenté dans `invitation_service.dart`
- Restrictions pour que seuls les hosts puissent envoyer des invitations quand leur terrain est ouvert
- Interface de recherche d'utilisateurs et d'envoi/réception d'invitations dans `players_screen.dart`

### 4. Gestion des équipes et lobby
- Implémenté dans `team_service.dart` et `players_screen.dart`
- Support jusqu'à 100 joueurs avec minimum 2 joueurs par équipe
- Possibilité de renommer les équipes
- Mémorisation des configurations d'équipes précédentes
- Interface pour répartir les joueurs dans les équipes

## Test des nouvelles fonctionnalités

1. Ouvrez l'application et connectez-vous en tant qu'host
2. Sélectionnez une carte dans l'onglet "Terrain" et ouvrez-la
3. Testez le sélecteur de temps en cliquant sur "Définir durée"
4. Sélectionnez un scénario et lancez la partie pour voir le décompte sur le bouton
5. Allez dans l'onglet "Joueurs" pour tester la recherche d'utilisateurs et la gestion des équipes

## Remarques importantes

- Les fonctionnalités WebSocket nécessitent une implémentation côté serveur pour fonctionner complètement
- Certaines fonctionnalités utilisent des données simulées pour le développement
- Assurez-vous que votre API backend prend en charge les nouveaux endpoints utilisés dans les services
