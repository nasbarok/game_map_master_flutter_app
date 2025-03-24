import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/websocket_service.dart';
import 'join_team_screen.dart';
import 'qr_code_scanner_screen.dart';
import 'package:go_router/go_router.dart';

class GamerDashboardScreen extends StatefulWidget {
  const GamerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<GamerDashboardScreen> createState() => _GamerDashboardScreenState();
}

class _GamerDashboardScreenState extends State<GamerDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Connecter au WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final webSocketService = Provider.of<WebSocketService>(context, listen: false);
      webSocketService.connect();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
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
          tabs: const [
            Tab(icon: Icon(Icons.videogame_asset), text: 'Parties'),
            Tab(icon: Icon(Icons.people), text: 'Équipes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Parties
          _buildGamesTab(),
          
          // Onglet Équipes
          _buildTeamsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action en fonction de l'onglet actif
          if (_tabController.index == 0) {
            _showScanQRCodeDialog();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const JoinTeamScreen()),
            );
          }
        },
        child: Icon(_tabController.index == 0 ? Icons.qr_code_scanner : Icons.group_add),
      ),
    );
  }
  
  Widget _buildGamesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videogame_asset, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucune partie en cours',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scannez un QR code pour rejoindre une partie',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showScanQRCodeDialog,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scanner un QR code'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTeamsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Vous n\'êtes dans aucune équipe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rejoignez une équipe pour participer à des parties',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JoinTeamScreen()),
              );
            },
            icon: const Icon(Icons.group_add),
            label: const Text('Rejoindre une équipe'),
          ),
        ],
      ),
    );
  }
  
  void _showScanQRCodeDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRCodeScannerScreen()),
    );
  }
}
