import 'package:game_map_master_flutter_app/screens/host/players_screen.dart';
import 'package:flutter/material.dart';
import 'package:game_map_master_flutter_app/utils/app_utils.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/game_map_service.dart';
import '../../services/invitation_service.dart';
import '../../services/notifications.dart';
import '../../services/scenario_service.dart';
import '../../services/websocket_service.dart';
import '../../services/game_state_service.dart';
import '../../widgets/host_history_tab.dart';
import '../../widgets/adaptive_background.dart';
import '../scenario/treasure_hunt/scoreboard_screen.dart';
import 'team_form_screen.dart';
import 'scenario_form_screen.dart';
import 'game_map_form_screen.dart';
import 'terrain_dashboard_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late InvitationService _invitationService;
  bool _isSectionCardVisible = true; // État de visibilité de l'encadré complet

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Connecter au WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _invitationService = context.read<InvitationService>();
      final webSocketService = context.read<WebSocketService>();

      webSocketService.connect();
      _invitationService.onInvitationReceivedDialog = _showInvitationDialog;

      _loadGameMaps();
      _loadScenarios();
    });

    // Écouter les changements d'onglet pour mettre à jour l'encadré
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Redessiner pour changer l'encadré
      }
    });
  }

  @override
  void dispose() {
    _invitationService.onInvitationReceivedDialog = null;
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showInvitationDialog(Map<String, dynamic> invitation) async {
    final l10n = AppLocalizations.of(context)!;

    if (ModalRoute.of(context)?.isCurrent == true) {
      showDialog(
        context: context,
        builder: (context) => _buildMilitaryDialog(
          title: l10n.invitationReceivedTitle,
          content: Text(
            l10n.invitationReceivedMessage(
              invitation['fromUsername'] ?? l10n.unknownPlayerName,
              invitation['mapName'] ?? l10n.unknownMap,
            ),
            style: const TextStyle(color: Color(0xFFF7FAFC)),
          ),
          actions: [
            _buildMilitaryButton(
              text: l10n.declineInvitation,
              onPressed: () {
                _invitationService.respondToInvitation(context, invitation, false);
                Navigator.of(context).pop();
              },
              style: _MilitaryButtonStyle.secondary,
            ),
            _buildMilitaryButton(
              text: l10n.acceptInvitation,
              onPressed: () {
                _invitationService.respondToInvitation(context, invitation, true);
                Navigator.of(context).pop();
              },
              style: _MilitaryButtonStyle.primary,
            ),
          ],
        ),
      );
    } else {
      await showInvitationNotification(invitation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.watch<AuthService>();
    final gameStateService = context.watch<GameStateService>();

    return AdaptiveScaffold(
      gameBackgroundType: GameBackgroundType.home,
      enableParallax: true,
      backgroundOpacity: 0.9,
      body: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildMilitaryAppBar(l10n),
        body: Stack(
          children: [
            // Contenu principal
            Column(
              children: [
                // Espace pour l'encadré flottant
                SizedBox(height: _isSectionCardVisible ? 140 : 20),

                // ✅ CONTENU EXISTANT
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Onglet Terrain (tableau de bord host)
                      const TerrainDashboardScreen(),

                      // Onglet Cartes (gestion des terrains/cartes)
                      _buildMapsTab(),

                      // Onglet Scénarios
                      _buildScenariosTab(),

                      // Onglet Joueurs (équipes)
                      gameStateService.isTerrainOpen
                          ? const PlayersScreen()
                          : _buildDisabledTeamsTab(),

                      // Onglet Historique
                      const HostHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),

            // 🆕 ENCADRÉ COMPLET FLOTTANT AVEC SYSTÈME SHOW/HIDE
            _buildFloatingSectionCard(),

            // 🆕 POINT D'INTERROGATION POUR RÉAFFICHER (toujours visible quand caché)
            if (!_isSectionCardVisible) _buildShowButton(),
          ],
        ),
        floatingActionButton: _buildContextualFAB(),
      ),
    );
  }

  /// 🆕 ENCADRÉ COMPLET FLOTTANT AVEC SYSTÈME SHOW/HIDE
  Widget _buildFloatingSectionCard() {
    if (!_isSectionCardVisible) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return Positioned(
      top: 20,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Encadré principal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748).withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getSectionAccentColor().withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getSectionAccentColor().withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo/Image à gauche (SANS BORDURE, JUSTE OMBRE)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        // Ombre en dessous
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                          spreadRadius: 1,
                        ),
                        // Ombre légère avec couleur d'accent
                        BoxShadow(
                          color: _getSectionAccentColor().withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildSectionLogo(),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Titre + Texte scrollable à droite
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre de la section
                        Text(
                          _getSectionTitle(l10n),
                          style: TextStyle(
                            color: _getSectionAccentColor(),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Texte scrollable
                        Container(
                          height: 60, // Hauteur fixe pour le scroll
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getSectionDescription(l10n),
                                  style: const TextStyle(
                                    color: Color(0xFFF7FAFC),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getSectionSubtitle(l10n),
                                  style: const TextStyle(
                                    color: Color(0xFF718096),
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ✅ NOUVEAU : Croix discrète petite et noire
            Positioned(
              top: 8, // ✅ MODIFIÉ : Position plus discrète
              right: 8, // ✅ MODIFIÉ : Position plus discrète
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isSectionCardVisible = false;
                  });
                },
                child: Container(
                  width: 20, // ✅ MODIFIÉ : Plus petite (20x20 au lieu de 30x30)
                  height: 20, // ✅ MODIFIÉ : Plus petite
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6), // ✅ MODIFIÉ : Noir semi-transparent
                    borderRadius: BorderRadius.circular(10), // ✅ MODIFIÉ : Coins arrondis discrets
                    // ✅ SUPPRIMÉ : border blanche
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2), // ✅ MODIFIÉ : Ombre plus discrète
                        blurRadius: 2, // ✅ MODIFIÉ : Ombre plus petite
                        offset: const Offset(0, 1), // ✅ MODIFIÉ : Ombre plus subtile
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white, // ✅ GARDÉ : Icône blanche pour contraste
                    size: 12, // ✅ MODIFIÉ : Icône plus petite (12 au lieu de 18)
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🆕 BOUTON POINT D'INTERROGATION POUR RÉAFFICHER
  Widget _buildShowButton() {
    return Positioned(
      top: 15,
      left: 15,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isSectionCardVisible = true;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _getSectionAccentColor(),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _getSectionAccentColor().withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.help_outline,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// 🆕 APPBAR MILITAIRE PERSONNALISÉE
  PreferredSizeWidget _buildMilitaryAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(
        l10n.hostDashboardTitle,
        style: const TextStyle(
          color: Color(0xFFF7FAFC),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      backgroundColor: const Color(0xFF4A5568),
      foregroundColor: const Color(0xFFF7FAFC),
      elevation: 4,
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2D3748),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF718096).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout,
            onPressed: () async {
              final authService = context.read<AuthService>();
              await authService.leaveAndLogout(context);
              if (mounted) {
                context.go('/login');
              }
            },
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF48BB78), // accentGreen
        labelColor: const Color(0xFFF7FAFC), // textLight
        unselectedLabelColor: const Color(0xFF718096), // lightMetal
        indicatorWeight: 3,
        tabs: [
          Tab(icon: const Icon(Icons.dashboard), text: l10n.terrainTab),
          Tab(icon: const Icon(Icons.map), text: l10n.mapTab),
          Tab(icon: const Icon(Icons.videogame_asset), text: l10n.scenariosTab),
          Tab(icon: const Icon(Icons.people), text: l10n.playersTab),
          Tab(icon: const Icon(Icons.history), text: l10n.historyTab),
        ],
      ),
    );
  }

  /// 🆕 LOGO DE SECTION SELON L'ONGLET
  Widget _buildSectionLogo() {
    return Image.asset(
      _getSectionLogoPath(),
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback avec icône stylisée
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getSectionAccentColor().withOpacity(0.3),
                _getSectionAccentColor().withOpacity(0.1),
              ],
            ),
          ),
          child: Icon(
            _getSectionIcon(),
            color: _getSectionAccentColor(),
            size: 40,
          ),
        );
      },
    );
  }

  /// 🆕 CHEMINS DES LOGOS
  String _getSectionLogoPath() {
    switch (_tabController.index) {
      case 0: return 'assets/images/theme/logos/logo_command_center.png';
      case 1: return 'assets/images/theme/logos/logo_map_room.png';
      case 2: return 'assets/images/theme/logos/logo_mission_briefing.png';
      case 3: return 'assets/images/theme/logos/logo_squad_management.png';
      case 4: return 'assets/images/theme/logos/logo_after_action.png';
      default: return 'assets/images/theme/logos/logo_command_center.png';
    }
  }

  /// 🆕 COULEUR D'ACCENT PAR SECTION
  Color _getSectionAccentColor() {
    switch (_tabController.index) {
      case 0: return const Color(0xFF4A5568); // Gris métallique
      case 1: return const Color(0xFF48BB78); // Vert militaire
      case 2: return const Color(0xFFED8936); // Orange tactique
      case 3: return const Color(0xFF9F7AEA); // Violet commandement
      case 4: return const Color(0xFF718096); // Gris archives
      default: return const Color(0xFF4A5568);
    }
  }

  /// 🆕 ICÔNE DE SECTION (FALLBACK)
  IconData _getSectionIcon() {
    switch (_tabController.index) {
      case 0: return Icons.dashboard;
      case 1: return Icons.map;
      case 2: return Icons.videogame_asset;
      case 3: return Icons.people;
      case 4: return Icons.history;
      default: return Icons.dashboard;
    }
  }

  /// 🆕 TITRE DE SECTION
  String _getSectionTitle(AppLocalizations l10n) {
    switch (_tabController.index) {
      case 0: return l10n.hostSectionCommandCenterTitle;
      case 1: return l10n.hostSectionMapManagementTitle;
      case 2: return l10n.hostSectionMissionScenariosTitle;
      case 3: return l10n.hostSectionTeamsPlayersTitle;
      case 4: return l10n.hostSectionGameHistoryTitle;
      default: return l10n.hostSectionCommandCenterTitle;
    }
  }

  /// 🆕 DESCRIPTION DE SECTION
  String _getSectionDescription(AppLocalizations l10n) {
    switch (_tabController.index) {
      case 0: return l10n.hostSectionCommandCenterDescription;
    case 1: return l10n.hostSectionMapManagementDescription;
    case 2: return l10n.hostSectionMissionScenariosDescription;
    case 3: return l10n.hostSectionTeamsPlayersDescription;
    case 4: return l10n.hostSectionGameHistoryDescription;
    default: return l10n.hostSectionCommandCenterDescription;
    }
  }

  /// 🆕 SOUS-TITRE DE SECTION
  String _getSectionSubtitle(AppLocalizations l10n) {
    switch (_tabController.index) {
      case 0: return l10n.hostSectionCommandCenterSubtitle;
      case 1: return l10n.hostSectionMapManagementSubtitle;
      case 2: return l10n.hostSectionMissionScenariosSubtitle;
      case 3: return l10n.hostSectionTeamsPlayersSubtitle;
      case 4: return l10n.hostSectionGameHistorySubtitle;
      default: return l10n.hostSectionCommandCenterSubtitle;
    }
  }

  /// ✅ FLOATING ACTION BUTTON CONTEXTUEL
  Widget? _buildContextualFAB() {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.watch<GameStateService>();

    // ✅ RETOURNER null POUR L'ONGLET FIELD (index 0)
    if (_tabController.index == 0) {
      return null;  // Pas de FAB sur l'onglet Field
    }

    return _buildMilitaryButton(
      text: _getFABText(l10n, gameStateService),
      onPressed: _getFABAction(l10n, gameStateService),
      style: _MilitaryButtonStyle.primary,
      icon: _getFABIcon(),
    );
  }

  String _getFABText(AppLocalizations l10n, GameStateService gameStateService) {
    switch (_tabController.index) {
      case 0: return "";
      case 1: return l10n.createMap;
      case 2: return l10n.createScenario;
      case 3: return gameStateService.isTerrainOpen ? l10n.createTeam : l10n.openFieldFirstSnackbar;
      case 4: return "Exporter";
      default: return l10n.noActionForFieldTabSnackbar;
    }
  }

  IconData _getFABIcon() {
    switch (_tabController.index) {
      case 0: return Icons.info;
      case 1: return Icons.add;
      case 2: return Icons.add;
      case 3: return Icons.add;
      case 4: return Icons.download;
      default: return Icons.add;
    }
  }

  VoidCallback? _getFABAction(AppLocalizations l10n, GameStateService gameStateService) {
    switch (_tabController.index) {
      case 0:
        return () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.noActionForFieldTabSnackbar),
              backgroundColor: Colors.blue,
            ),
          );
        };
      case 1:
        return () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GameMapFormScreen()),
          );
        };
      case 2:
        return () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScenarioFormScreen()),
          );
        };
      case 3:
        return gameStateService.isTerrainOpen
            ? () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TeamFormScreen()),
          );
        }
            : () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.openFieldFirstSnackbar),
              backgroundColor: Colors.orange,
            ),
          );
        };
      case 4:
        return () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Fonctionnalité d'export en cours de développement"),
              backgroundColor: Colors.blue,
            ),
          );
        };
      default:
        return null;
    }
  }

  /// ✅ ONGLET CARTES
  Widget _buildMapsTab() {
    final l10n = AppLocalizations.of(context)!;
    final gameMapService = context.watch<GameMapService>();

    if (gameMapService.gameMaps.isEmpty) {
      return _buildEmptyState(
        icon: Icons.map_outlined,
        title: l10n.noMapAvailable,
        subtitle: l10n.createMapPrompt,
        buttonText: l10n.createMap,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GameMapFormScreen()),
          );
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: gameMapService.gameMaps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final map = gameMapService.gameMaps[index];
        return Card(
          color: const Color(0xFF2D3748).withOpacity(0.8),
          child: ListTile(
            title: Text(
              map.name ?? l10n.noMapAvailable,
              style: const TextStyle(color: Color(0xFFF7FAFC)),
            ),
            subtitle: Text(
              map.description ?? l10n.noDescription,
              style: const TextStyle(color: Color(0xFF718096)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF48BB78)),
                  tooltip: l10n.editMap,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameMapFormScreen(gameMap: map),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFFE53E3E)),
                  tooltip: l10n.deleteMap,
                  onPressed: () => _confirmDeleteMap(map),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ✅ ONGLET SCÉNARIOS
  Widget _buildScenariosTab() {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.watch<GameStateService>();
    final scenarioService = context.watch<ScenarioService>();

    final activeScenario = gameStateService.selectedScenarios?.isNotEmpty == true
        ? gameStateService.selectedScenarios!.first
        : null;

    if (scenarioService.scenarios.isEmpty) {
      return _buildEmptyState(
        icon: Icons.videogame_asset,
        title: l10n.noScenarioAvailable,
        subtitle: l10n.createScenarioPrompt,
        buttonText: l10n.createScenario,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScenarioFormScreen()),
          );
        },
        extraWidget: activeScenario != null && activeScenario.scenario.type == 'treasure_hunt'
            ? _buildMilitaryButton(
          text: l10n.scoreboardButton,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScoreboardScreen(
                  treasureHuntId: activeScenario.scenario.id,
                  scenarioName: activeScenario.scenario.name,
                  isHost: true,
                ),
              ),
            );
          },
          style: _MilitaryButtonStyle.secondary,
        )
            : null,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: scenarioService.scenarios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final scenario = scenarioService.scenarios[index];
        return Card(
          color: const Color(0xFF2D3748).withOpacity(0.8),
          child: ListTile(
            title: Text(
              scenario.name,
              style: const TextStyle(color: Color(0xFFF7FAFC)),
            ),
            subtitle: Text(
              scenario.description ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF718096)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF48BB78)),
                  tooltip: l10n.editScenario,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScenarioFormScreen(scenario: scenario),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFFE53E3E)),
                  tooltip: l10n.deleteScenario,
                  onPressed: () => _confirmDeleteScenario(scenario),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ✅ ONGLET JOUEURS DÉSACTIVÉ
  Widget _buildDisabledTeamsTab() {
    final l10n = AppLocalizations.of(context)!;
    return _buildEmptyState(
      icon: Icons.people,
      title: l10n.playersUnavailableTitle,
      subtitle: l10n.openField,
      buttonText: l10n.goToFieldTabButton,
      onPressed: () {
        _tabController.animateTo(0);
      },
      iconOpacity: 0.5,
    );
  }

  /// 🆕 WIDGET ÉTAT VIDE STYLISÉ
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    double iconOpacity = 1.0,
    Widget? extraWidget,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: const Color(0xFF718096).withOpacity(iconOpacity),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF7FAFC),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF718096)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildMilitaryButton(
              text: buttonText,
              onPressed: onPressed,
              style: _MilitaryButtonStyle.primary,
              icon: Icons.add,
            ),
            if (extraWidget != null) ...[
              const SizedBox(height: 16),
              extraWidget,
            ],
          ],
        ),
      ),
    );
  }

  /// 🆕 BOUTON MILITAIRE PERSONNALISÉ
  Widget _buildMilitaryButton({
    required String text,
    required VoidCallback? onPressed,
    required _MilitaryButtonStyle style,
    IconData? icon,
  }) {
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    switch (style) {
      case _MilitaryButtonStyle.primary:
        backgroundColor = const Color(0xFF48BB78);
        foregroundColor = const Color(0xFFF7FAFC);
        borderColor = const Color(0xFF48BB78);
        break;
      case _MilitaryButtonStyle.secondary:
        backgroundColor = Colors.transparent;
        foregroundColor = const Color(0xFF48BB78);
        borderColor = const Color(0xFF48BB78);
        break;
      case _MilitaryButtonStyle.danger:
        backgroundColor = const Color(0xFFE53E3E);
        foregroundColor = const Color(0xFFF7FAFC);
        borderColor = const Color(0xFFE53E3E);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: foregroundColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🆕 DIALOG MILITAIRE PERSONNALISÉ
  Widget _buildMilitaryDialog({
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return Dialog(
      backgroundColor: const Color(0xFF2D3748),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF4A5568), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFF7FAFC),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions.map((action) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: action,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ MÉTHODES UTILITAIRES
  Future<void> _confirmDeleteMap(dynamic map) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildMilitaryDialog(
        title: l10n.confirmDeleteTitle,
        content: Text(
          l10n.confirmDeleteMapMessage,
          style: const TextStyle(color: Color(0xFFF7FAFC)),
        ),
        actions: [
          _buildMilitaryButton(
            text: l10n.cancel,
            onPressed: () => Navigator.of(context).pop(false),
            style: _MilitaryButtonStyle.secondary,
          ),
          _buildMilitaryButton(
            text: l10n.delete,
            onPressed: () => Navigator.of(context).pop(true),
            style: _MilitaryButtonStyle.danger,
          ),
        ],
      ),
    );

    if (confirm == true) {
      final gameMapService = context.read<GameMapService>();
      try {
        await gameMapService.deleteGameMap(map.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mapDeletedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorDeletingMap(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteScenario(dynamic scenario) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildMilitaryDialog(
        title: l10n.confirmDeleteTitle,
        content: Text(
          l10n.confirmDeleteScenarioMessage,
          style: const TextStyle(color: Color(0xFFF7FAFC)),
        ),
        actions: [
          _buildMilitaryButton(
            text: l10n.cancel,
            onPressed: () => Navigator.of(context).pop(false),
            style: _MilitaryButtonStyle.secondary,
          ),
          _buildMilitaryButton(
            text: l10n.delete,
            onPressed: () => Navigator.of(context).pop(true),
            style: _MilitaryButtonStyle.danger,
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<ScenarioService>().deleteScenario(scenario.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.scenarioDeletedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.error + e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadGameMaps() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final gameMapService = context.read<GameMapService>();
      await gameMapService.loadGameMaps();
    } catch (e) {
      logger.d(l10n.errorLoadingMaps(e.toString()));
    }
  }

  Future<void> _loadScenarios() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final scenarioService = context.read<ScenarioService>();
      await scenarioService.loadScenarios();
    } catch (e) {
      logger.d(l10n.errorLoadingScenarios(e.toString()));
    }
  }
}

/// 🆕 ENUM POUR LES STYLES DE BOUTONS
enum _MilitaryButtonStyle {
  primary,
  secondary,
  danger,
}

