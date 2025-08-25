import 'package:game_map_master_flutter_app/screens/host/players_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/field.dart';
import '../../models/invitation.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_map_service.dart';
import '../../services/invitation_service.dart';
import '../../services/notifications.dart';
import '../../services/scenario_service.dart';
import '../../services/storage/info_panel_preferences_service.dart';
import '../../services/team_service.dart';
import '../../services/websocket_service.dart';
import '../../services/game_state_service.dart';
import '../../widgets/appbar/host_section_appbar_title.dart';
import '../../widgets/host_history_tab.dart';
import '../../widgets/adaptive_background.dart';
import '../../widgets/options/user_options_menu.dart';
import '../../widgets/options/cropped_logo_button.dart';
import '../scenario/treasure_hunt/scoreboard_screen.dart';
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
  bool _isJoining = false;

  bool _isInfoModalOpen = false;

  //Gestion des panneaux vus
  Map<int, bool> _tabInfoPanelsSeen = {};
  bool _isFirstTimeModalShown = false; // Pour éviter les doublons

  bool get _showJoinLastField {
    final gameState = context.watch<GameStateService>();
    if (gameState.isTerrainOpen) return false;
    final i = _tabController.index;
    return i == 0 || i == 3; // Field ou Players
  }

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

      // Charger les préférences et vérifier l'affichage
      _loadInfoPanelPreferences();
    });

    // Écouter les changements d'onglet pour mettre à jour l'encadré
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;

      // 🔁 NOUVEAU : refresh quand on arrive sur "Joueurs"
      if (_tabController.index == 3 || _tabController.index == 0) {
        final gameState = context.read<GameStateService>();
        final teamService = context.read<TeamService>();
        if (gameState.selectedMap?.id != null) {
          gameState.loadConnectedPlayers();
          teamService.loadTeams(gameState.selectedMap!.id!);
        }
      }

      setState(() {}); // garder ton redraw pour l’encadré
      _isFirstTimeModalShown = false; // reset pour l’onglet courant
      _checkAndShowFullscreenInfoPanel();
    });
  }

  @override
  void dispose() {
    _invitationService.onInvitationReceivedDialog = null;
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showInvitationDialog(Map<String, dynamic> payload) async {
    final l10n = AppLocalizations.of(context)!;
    final invitation = Invitation.fromJson(payload);

    if (ModalRoute.of(context)?.isCurrent == true) {
      showDialog(
        context: context,
        builder: (context) => _buildMilitaryDialog(
          title: l10n.invitationReceivedTitle,
          content: Text(
            l10n.invitationReceivedMessage(
              invitation.senderUsername ?? l10n.unknownPlayerName,
              invitation.fieldName ?? l10n.unknownMap,
            ),
            style: const TextStyle(color: Color(0xFFF7FAFC)),
          ),
          actions: [
            _buildMilitaryButton(
              text: l10n.declineInvitation,
              onPressed: () {
                _invitationService.respondToInvitation(
                    context, invitation.id, false);
                Navigator.of(context).pop();
              },
              style: _MilitaryButtonStyle.secondary,
            ),
            _buildMilitaryButton(
              text: l10n.acceptInvitation,
              onPressed: () {
                _invitationService.respondToInvitation(
                    context, invitation.id, true);
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
    void _goToField() => _tabController.animateTo(0);

    return AdaptiveScaffold(
      gameBackgroundType: GameBackgroundType.home,
      enableParallax: true,
      backgroundOpacity: 0.9,
      body: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildMilitaryAppBar(l10n),
        body: Stack(
          children: [
            // 1) Contenu principal
            Column(
              children: [
                if (_showJoinLastField) _buildJoinLastField(),
                SizedBox(height: 20),
                // barre de navigation
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
                      PlayersScreen(onGoToFieldTab: _goToField),

                      // Onglet Historique
                      const HostHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),

            // 3) POINT D'INTERROGATION POUR RÉAFFICHER (toujours visible quand caché)
            _buildShowButton(),

            // 4) OVERLAY DE CHARGEMENT – TOUJOURS EN DERNIER !
            if (_isJoining)
              Positioned.fill(
                child: AbsorbPointer(
                  absorbing: true,
                  child: Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: _buildContextualFAB(),
      ),
    );
  }

  /// BOUTON POINT D'INTERROGATION POUR RÉAFFICHER
  Widget _buildShowButton() {
    return Positioned(
      top: 15,
      left: 15,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showFullscreenInfoPanel(_tabController.index);
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

  /// APPBAR MILITAIRE PERSONNALISÉE
  PreferredSizeWidget _buildMilitaryAppBar(AppLocalizations l10n) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CroppedLogoButtonAnimated(
          size: 35.0,
          onPressed: () {
            // Par exemple : ouvrir un menu audio ou un écran d’options
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserOptionsMenu(),
              ),
            );
          },
        ),
      ),
      title: HostSectionAppBarTitle(
        controller: _tabController,
        titleOf: (i) => _getSectionTitle(l10n),
        iconOf: (i) => _iconOfTab(i),
        iconSize: 22, // ajuste si tu veux (20–26)
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
        indicatorColor: const Color(0xFF48BB78),
        // accentGreen
        labelColor: const Color(0xFFF7FAFC),
        // textLight
        unselectedLabelColor: const Color(0xFF718096),
        // lightMetal
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
      case 0:
        return 'assets/images/theme/logos/logo_command_center.png';
      case 1:
        return 'assets/images/theme/logos/logo_map_room.png';
      case 2:
        return 'assets/images/theme/logos/logo_mission_briefing.png';
      case 3:
        return 'assets/images/theme/logos/logo_squad_management.png';
      case 4:
        return 'assets/images/theme/logos/logo_after_action.png';
      default:
        return 'assets/images/theme/logos/logo_command_center.png';
    }
  }

  /// 🆕 COULEUR D'ACCENT PAR SECTION
  Color _getSectionAccentColor() {
    switch (_tabController.index) {
      case 0:
        return const Color(0xFF4A5568); // Gris métallique
      case 1:
        return const Color(0xFF48BB78); // Vert militaire
      case 2:
        return const Color(0xFFED8936); // Orange tactique
      case 3:
        return const Color(0xFF9F7AEA); // Violet commandement
      case 4:
        return const Color(0xFF718096); // Gris archives
      default:
        return const Color(0xFF4A5568);
    }
  }

  /// 🆕 ICÔNE DE SECTION (FALLBACK)
  IconData _getSectionIcon() {
    switch (_tabController.index) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.map;
      case 2:
        return Icons.videogame_asset;
      case 3:
        return Icons.people;
      case 4:
        return Icons.history;
      default:
        return Icons.dashboard;
    }
  }

  /// 🆕 TITRE DE SECTION
  String _getSectionTitle(AppLocalizations l10n) {
    switch (_tabController.index) {
      case 0:
        return l10n.hostSectionCommandCenterTitle;
      case 1:
        return l10n.hostSectionMapManagementTitle;
      case 2:
        return l10n.hostSectionMissionScenariosTitle;
      case 3:
        return l10n.hostSectionTeamsPlayersTitle;
      case 4:
        return l10n.hostSectionGameHistoryTitle;
      default:
        return l10n.hostSectionCommandCenterTitle;
    }
  }

  /// 🆕 DESCRIPTION DE SECTION
  String _getSectionDescription(AppLocalizations l10n) {
    switch (_tabController.index) {
      case 0:
        return l10n.hostSectionCommandCenterDescription;
      case 1:
        return l10n.hostSectionMapManagementDescription;
      case 2:
        return l10n.hostSectionMissionScenariosDescription;
      case 3:
        return l10n.hostSectionTeamsPlayersDescription;
      case 4:
        return l10n.hostSectionGameHistoryDescription;
      default:
        return l10n.hostSectionCommandCenterDescription;
    }
  }

  /// 🆕 SOUS-TITRE DE SECTION
  String _getSectionSubtitle(AppLocalizations l10n) {
    switch (_tabController.index) {
      case 0:
        return l10n.hostSectionCommandCenterSubtitle;
      case 1:
        return l10n.hostSectionMapManagementSubtitle;
      case 2:
        return l10n.hostSectionMissionScenariosSubtitle;
      case 3:
        return l10n.hostSectionTeamsPlayersSubtitle;
      case 4:
        return l10n.hostSectionGameHistorySubtitle;
      default:
        return l10n.hostSectionCommandCenterSubtitle;
    }
  }

  /// ✅ FLOATING ACTION BUTTON CONTEXTUEL
  Widget? _buildContextualFAB() {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.watch<GameStateService>();

    // ⚠️ pas de FAB sur Field (0) et Players (3) ET History (4)
    if (_tabController.index == 0 ||
        _tabController.index == 3 ||
        _tabController.index == 4) {
      return null; // Pas de FAB sur l'onglet Field
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
      case 0:
        return "";
      case 1:
        return l10n.createMap;
      case 2:
        return l10n.createScenario;
      default:
        return l10n.noActionForFieldTabSnackbar;
    }
  }

  IconData _getFABIcon() {
    switch (_tabController.index) {
      case 0:
        return Icons.info;
      case 1:
        return Icons.add;
      case 2:
        return Icons.add;
      default:
        return Icons.add;
    }
  }

  VoidCallback? _getFABAction(
      AppLocalizations l10n, GameStateService gameStateService) {
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
              map.name,
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

    final activeScenario =
        gameStateService.selectedScenarios?.isNotEmpty == true
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
        extraWidget: activeScenario != null &&
                activeScenario.scenario.type == 'treasure_hunt'
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
                        builder: (context) =>
                            ScenarioFormScreen(scenario: scenario),
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
              children: actions
                  .map((action) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: action,
                      ))
                  .toList(),
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

  /// Affiche le bouton pour rejoindre le dernier terrain ouvert si l'utilisateur
  /// n'a pas de terrain ouvert actuellement.
  ///
  /// Si l'utilisateur a déjà un terrain ouvert, ne rien afficher.
  ///
  /// Si le terrain est fermé, afficher le bouton pour l'ouvrir.
  /// Si le terrain est ouvert, afficher le bouton pour le rejoindre.
  ///
  /// Si l'utilisateur est propriétaire du terrain, ne rien afficher.
  ///
  /// Si il n'y a pas de terrain ouvert, afficher un message d'erreur.
  ///
  Widget _buildJoinLastField() {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = context.watch<GameStateService>();

    // Ne rien afficher si l'utilisateur a déjà un terrain ouvert
    if (gameStateService.isTerrainOpen) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<Field>>(
      future: _loadLastActiveField(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text(l10n.loadingError(snapshot.error.toString())));
        }

        final fields = snapshot.data ?? [];
        if (fields.isEmpty) {
          return const Center(child: Text(""));
        }

        final lastField = fields.first;

        final authService = context.read<AuthService>();
        if (lastField.owner?.id == authService.currentUser?.id) {
          return const SizedBox
              .shrink(); // Pas d'affichage si c'est son propre terrain
        }

        // Infos pour la ListTile
        final isOpen = lastField.active;
        final openedAtStr = lastField.openedAt != null
            ? l10n.fieldOpenedOn(_formatDate(lastField.openedAt!))
            : l10n.unknownOpeningDate;
        final ownerName = lastField.owner?.username != null
            ? l10n.ownerLabel(lastField.owner!.username)
            : l10n.unknownOwner;

        return Card(
          color: Colors.black.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ListTile(
                title: Text(lastField.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(openedAtStr),
                    Text(ownerName),
                  ],
                ),
                trailing: Wrap(
                  direction: Axis.vertical,
                  spacing: 4,
                  children: [
                    if (isOpen)
                      ElevatedButton(
                        onPressed: () => _joinField(lastField.id!),
                        child: Text(l10n.joinButton),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _joinField(int fieldId) async {
    final l10n = AppLocalizations.of(context)!;
    final gameStateService = GetIt.I<GameStateService>();
    final apiService = GetIt.I<ApiService>();

    setState(() => _isJoining = true);
    try {
      // Appeler l'API pour rejoindre le terrain
      final response = await apiService.post('fields/$fieldId/join', {});

      if (response != null) {
        // Mettre à jour l'état du jeu après la connexion
        await gameStateService.restoreSessionIfNeeded(apiService, fieldId);
        if (!mounted) return;
        context.go(Routes.lobby);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loadingError(e.toString()))),
      );
    }
  }

  // Méthode pour charger le dernier terrain actif où l'utilisateur a été invité
  Future<List<Field>> _loadLastActiveField() async {
    try {
      final apiService = GetIt.I<ApiService>();
      final response = await apiService.get(
          'fields-history/last-active'); // On récupère les derniers terrains visités

      if (response == null || !(response is List)) {
        return []; // Retourne une liste vide si aucune donnée n'est trouvée
      }

      final fields = (response).map((data) => Field.fromJson(data)).toList();

      // Trier par date de dernière activité (en premier les terrains récemment ouverts)
      fields.sort((a, b) => b.openedAt!.compareTo(a.openedAt!));

      return fields;
    } catch (e) {
      logger.d('❌ Erreur lors du chargement des terrains actifs : $e');
      return [];
    }
  }

  // Charge les préférences "vu/pas vu" pour chaque onglet au démarrage
  Future<void> _loadInfoPanelPreferences() async {
    // 0..4 : field, maps, scenarios, players, history
    for (int i = 0; i < 5; i++) {
      final tabKey = InfoPanelPreferencesService.getTabKeyFromIndex(i);
      final seen = await InfoPanelPreferencesService.hasSeenInfoPanel(tabKey);
      _tabInfoPanelsSeen[i] = seen;
    }
    // Affiche si nécessaire pour l’onglet courant
    if (mounted) {
      _checkAndShowFullscreenInfoPanel();
      setState(() {}); // pour refléter _tabInfoPanelsSeen
    }
  }

// Vérifie l’état pour l’onglet courant et ouvre le modal si 1ʳᵉ fois
  Future<void> _checkAndShowFullscreenInfoPanel() async {
    if (_isFirstTimeModalShown) return; // évite doublons
    final currentIndex = _tabController.index;
    final hasSeenPanel = _tabInfoPanelsSeen[currentIndex] ?? false;
    if (!hasSeenPanel) {
      _isFirstTimeModalShown = true;
      // Laisse à l’onglet le temps de s’afficher
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _showFullscreenInfoPanel(currentIndex);
    }
  }

// Ouvre le modal plein écran
  void _showFullscreenInfoPanel(int tabIndex) {
    if (_isInfoModalOpen) return;
    _isInfoModalOpen = true;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildFullscreenInfoModal(l10n, tabIndex),
    ).whenComplete(() {
      _isInfoModalOpen = false;
    });
  }

// Contenu du modal plein écran (reprend ton identité visuelle)
  // 1) MODAL plein écran avec image responsive XXL
  Widget _buildFullscreenInfoModal(AppLocalizations l10n, int tabIndex) {
    return Material(
      color: Colors.black.withOpacity(0.95),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = MediaQuery.of(context).size;
            final shortestSide = size.shortestSide;
            final isTablet = shortestSide >= 600;

            // Taille max de l’illustration (pour “le plus grand possible” sans casser la mise en page)
            final maxGraphicHeight =
                constraints.maxHeight * (isTablet ? 0.34 : 0.46);

            // Typo un poil responsive
            final titleFs = isTablet ? 40.0 : 32.0;
            final subtitleFs = isTablet ? 22.0 : 18.0;
            final bodyFs = isTablet ? 18.0 : 16.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // *** Illustration XXL ***
                      ConstrainedBox(
                        constraints:
                            BoxConstraints(maxHeight: maxGraphicHeight),
                        child: _buildLargeSectionGraphic(),
                      ),

                      const SizedBox(height: 24),

                      // Titre
                      Text(
                        _getSectionTitle(l10n),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleFs,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                          color: _getSectionAccentColor(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Sous-titre
                      Text(
                        _getSectionSubtitle(l10n),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: subtitleFs,
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Description
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3748).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getSectionAccentColor().withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getSectionDescription(l10n),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: bodyFs,
                            color: Colors.white,
                            height: 1.6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Bouton OK
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _markInfoPanelAsSeen(tabIndex);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getSectionAccentColor(),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline),
                            const SizedBox(width: 12),
                            Text(
                              l10n.ok,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

// 2) Illustration grand format avec halo/ombre et fallback propre
  Widget _buildLargeSectionGraphic() {
    final accent = _getSectionAccentColor();
    final logoPath = _getSectionLogoPath();

    return AspectRatio(
      aspectRatio: 1, // carré propre
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo/Glow doux derrière l’image (effet “néon”)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.55),
                  blurRadius: 120,
                  spreadRadius: 30,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 40,
                ),
              ],
            ),
          ),

          // Image qui prend 100% de la zone dispo, sans rogner
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox.expand(
              child: Image.asset(
                logoPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback cohérent avec ton style
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withOpacity(0.30),
                          accent.withOpacity(0.10),
                        ],
                      ),
                    ),
                    child: Icon(Icons.image, color: accent, size: 64),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

// Marque l’onglet comme vu et met à jour l’état mémoire
  Future<void> _markInfoPanelAsSeen(int tabIndex) async {
    final tabKey = InfoPanelPreferencesService.getTabKeyFromIndex(tabIndex);
    await InfoPanelPreferencesService.markInfoPanelAsSeen(tabKey);
    setState(() {
      _tabInfoPanelsSeen[tabIndex] = true;
      _isFirstTimeModalShown = false;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  IconData _iconOfTab(int i) {
    switch (i) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.map;
      case 2:
        return Icons.videogame_asset;
      case 3:
        return Icons.people;
      case 4:
        return Icons.history;
      default:
        return Icons.dashboard;
    }
  }
}

/// 🆕 ENUM POUR LES STYLES DE BOUTONS
enum _MilitaryButtonStyle {
  primary,
  secondary,
  danger,
}
