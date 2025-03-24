import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/field.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/websocket_service.dart';
import 'field_form_screen.dart';
import 'team_form_screen.dart';
import 'scenario_form_screen.dart';
import 'game_map_form_screen.dart';
import 'qr_code_generator_screen.dart';
import 'scenario_selection_dialog.dart';
import 'package:go_router/go_router.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> with SingleTickerProviderStateMixin {
  
  void _showGenerateQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => const ScenarioSelectionDialog(),
    );
  }
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
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
        title: const Text('Host Dashboard'),
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
            Tab(icon: Icon(Icons.map), text: 'Terrains'),
            Tab(icon: Icon(Icons.map_outlined), text: 'Cartes'),
            Tab(icon: Icon(Icons.videogame_asset), text: 'Scénarios'),
            Tab(icon: Icon(Icons.people), text: 'Équipes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Terrains
          _buildFieldsTab(),
          
          // Onglet Cartes
          _buildMapsTab(),
          
          // Onglet Scénarios
          _buildScenariosTab(),
          
          // Onglet Équipes
          _buildTeamsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action en fonction de l'onglet actif
          switch (_tabController.index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FieldFormScreen()),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GameMapFormScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScenarioFormScreen()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TeamFormScreen()),
              );
              break;
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFieldsTab() {
    final authService = Provider.of<AuthService>(context);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final userId = authService.currentUser?.id;

    return FutureBuilder<List<dynamic>>(
      future: apiService.get('fields/owner/self').then((data) => data as List<dynamic>),
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
                const Icon(Icons.map, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Aucun terrain',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ajoutez un terrain pour commencer',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FieldFormScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un terrain'),
                ),
              ],
            ),
          );
        }

        // Affichage de la liste des terrains
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: fields.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final field = fields[index];
            return Card(
              child: ListTile(
                title: Text(field['name'] ?? 'Sans nom'),
                subtitle: Text(field['description'] ?? 'Pas de description'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FieldFormScreen(
                          field: Field.fromJson(field),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildMapsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucune carte',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez une carte pour commencer',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GameMapFormScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Créer une carte'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScenariosTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videogame_asset, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucun scénario',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez un scénario pour commencer',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScenarioFormScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer un scénario'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Afficher une boîte de dialogue pour sélectionner un scénario
                  _showGenerateQRCodeDialog();
                },
                icon: const Icon(Icons.qr_code),
                label: const Text('Générer QR Code'),
              ),
            ],
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
            'Aucune équipe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez une équipe pour commencer',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TeamFormScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Créer une équipe'),
          ),
        ],
      ),
    );
  }
}
