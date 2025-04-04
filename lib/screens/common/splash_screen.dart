import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAndRestore();
  }

  Future<void> _navigateAndRestore() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final gameState = Provider.of<GameStateService>(context, listen: false);

    await Future.delayed(const Duration(milliseconds: 1000)); // Animation splash

    // ✅ Restaurer la session depuis SharedPreferences
    await authService.loadSession();

    if (!authService.isLoggedIn) {
      context.go('/login');
      return;
    }

    try {
      while (!gameState.isReady) {
        print('⏳ Attente de la fin de la restauration de la websocket...');
        await Future.delayed(const Duration(milliseconds: 50));
      }
      print('✅ websocket restaurée');
      await gameState.restoreSessionIfNeeded(apiService);
    } catch (e) {
      print('❌ Erreur pendant restoreSessionIfNeeded: $e');
    }

    final user = authService.currentUser!;
    final isHost = user.hasRole('HOST');
    final isTerrainOpen = gameState.isTerrainOpen;
    final isGameRunning = gameState.isGameRunning;

    if (!isTerrainOpen) {
      // Aucun terrain ouvert, gamer → scanner | host → dashboard vide
      context.go(isHost ? '/host' : '/gamer/lobby');
    } else {
      if(!isGameRunning) {
        // Terrain ouvert mais pas de jeu en cours → host → dashboard / gamer → lobby
        context.go(isHost ? '/host' : '/gamer/lobby');

      }else{
        // Terrain ouvert et jeu en cours → gamer → lobby
        context.go(isHost ? '/host' : '/gamer');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green, Colors.lightGreen],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'Game Map Master',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Créez et jouez des scénarios 2.0',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 50),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
