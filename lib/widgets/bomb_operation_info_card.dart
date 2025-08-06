import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/scenario/bomb_operation/bomb_operation_team.dart';
import '../models/scenario/bomb_operation/bomb_site.dart';
import '../models/websocket/bomb_planted_message.dart';
import '../services/scenario/bomb_operation/bomb_operation_auto_manager.dart';
import '../services/scenario/bomb_operation/bomb_operation_service.dart';
import '../services/scenario/bomb_operation/bomb_timer_calculator_service.dart';
import '../utils/logger.dart';
import 'dart:ui';

/// Widget affichant les informations enrichies du scénario Opération Bombe
/// Utilise les calculs dynamiques basés sur les timestamps WebSocket
class BombOperationInfoCard extends StatefulWidget {
  final int? teamId;
  final int userId;
  final int gameSessionId;
  final BombOperationAutoManager? autoManager;

  const BombOperationInfoCard({
    Key? key,
    required this.teamId,
    required this.userId,
    required this.gameSessionId,
    this.autoManager,
  }) : super(key: key);

  @override
  _BombOperationInfoCardState createState() => _BombOperationInfoCardState();
}

enum GameResult { win, lose, draw }

class _BombOperationInfoCardState extends State<BombOperationInfoCard> {
  Timer? _updateTimer;
  late BombOperationService _bombOperationService;
  List<ArmedBombInfo> _armedBombs = [];

  static final Color neutralCardColor = Colors.transparent;
  static final Color attackCardColor = Colors.transparent;
  static final Color defenseCardColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _bombOperationService = GetIt.I<BombOperationService>();

    // Timer pour mettre à jour l'affichage toutes les secondes (calculs locaux uniquement)
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Vérifier les explosions automatiques
          _checkForExplosions();
        });
      }
    });

    // Écouter les messages WebSocket pour mettre à jour les bombes armées
    _listenToBombList();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _listenToBombList() {
    final bombOperationService = GetIt.I<BombOperationService>();

    bombOperationService.bombSitesStream.listen((_) {
      if (!mounted) return;

      logger.d('🔄 [BombOperationInfoCard] Mise à jour des bombSitesStream');

      final scenario =
          bombOperationService.activeSessionScenarioBomb?.bombOperationScenario;
      if (scenario == null) return;

      final activeSites = bombOperationService.activeBombSites;
      final newArmedBombs = activeSites.map((site) {
        return ArmedBombInfo(
          siteId: site.id!,
          siteName: site.name,
          plantedTimestamp: site.plantedTimestamp ?? DateTime.now(),
          // ✅ vraie valeur si dispo
          bombTimerSeconds: scenario.bombTimer,
          playerName: site.plantedBy ?? 'Inconnu', // ✅ nom du joueur si dispo
        );
      }).toList();

      setState(() {
        _armedBombs = newArmedBombs;
      });
    });
  }

  void _checkForExplosions() {
    final toRemove = <ArmedBombInfo>[];

    for (final bomb in _armedBombs) {
      final site = _bombOperationService.getBombSiteById(bomb.siteId);
      final isDisarmed = site != null && site.active == false;

      if (isDisarmed) {
        logger.d(
            '🟦 Bombe désamorcée détectée : ${bomb.siteName} – suppression du timer');
        toRemove.add(bomb);
      } else if (bomb.shouldHaveExploded) {
        logger.w('💥 Explosion locale détectée pour ${bomb.siteName}');
        _bombOperationService.markAsExploded(bomb.siteId);
        toRemove.add(bomb);
      }
    }

    if (toRemove.isNotEmpty) {
      setState(() {
        _armedBombs.removeWhere((b) => toRemove.contains(b));
      });
    }
  }

  void addArmedBomb(BombPlantedMessage message) {
    final scenario =
        _bombOperationService.activeSessionScenarioBomb?.bombOperationScenario;
    if (scenario == null) return;

    final armedBomb = ArmedBombInfo(
      siteId: message.siteId,
      siteName: message.siteName ?? 'Site ${message.siteId}',
      plantedTimestamp: message.timestamp,
      bombTimerSeconds: scenario.bombTimer,
      playerName: message.playerName,
    );

    setState(() {
      _armedBombs.add(armedBomb);
    });
  }

  void removeArmedBomb(int siteId) {
    setState(() {
      _armedBombs.removeWhere((bomb) => bomb.siteId == siteId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.teamId == null) {
      logger.d(
          '⚠️ [BombOperationInfoCard] teamId est null, impossible d\'afficher le rôle');
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final teamRoles = _bombOperationService.teamRoles;

    if (teamRoles.isEmpty) {
      logger.d('⚠️ [BombOperationInfoCard] Aucun rôle d\'équipe défini');
      return Card(
        color: neutralCardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            l10n.bombOperationActive,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final role = teamRoles[widget.teamId];
    if (role == null) {
      logger.d(
          '⚠️ [BombOperationInfoCard] Aucun rôle trouvé pour l\'équipe ${widget.teamId}');
      return Card(
        color: neutralCardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            l10n.noTeamRole,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return _buildEnrichedInfoCard(role, l10n);
  }

  Widget _buildEnrichedInfoCard(BombOperationTeam role, AppLocalizations l10n) {
    // Déterminer le style en fonction du rôle
    String roleText;
    String objectiveText;
    Color borderColor;
    Color accentColor;
    IconData roleIcon;
    LinearGradient backgroundGradient;

    switch (role) {
      case BombOperationTeam.attack:
        roleText = l10n.terroristRole;
        objectiveText = l10n.terroristObjective;
        borderColor = Colors.red.shade600;
        accentColor = Colors.red.shade700;
        roleIcon = Icons.dangerous;
        backgroundGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.red.withOpacity(0.05),
            Colors.transparent,
          ],
        );
        break;
      case BombOperationTeam.defense:
        roleText = l10n.antiTerroristRole;
        objectiveText = l10n.antiTerroristObjective;
        borderColor = Colors.blue.shade600;
        accentColor = Colors.blue.shade700;
        roleIcon = Icons.shield;
        backgroundGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
            Colors.transparent,
          ],
        );
        break;
      default:
        roleText = l10n.unknownRole;
        objectiveText = l10n.observerObjective;
        borderColor = Colors.grey.shade600;
        accentColor = Colors.grey.shade700;
        roleIcon = Icons.question_mark;
        backgroundGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.withOpacity(0.1),
            Colors.grey.withOpacity(0.05),
            Colors.transparent,
          ],
        );
    }

    // Récupération des données dynamiques
    final activeSites = _bombOperationService.activeBombSites;
    final explodedSites = _bombOperationService.explodedBombSites;
    final toActivateSites = _bombOperationService.toActivateBombSites;

    final activatedCount = activeSites.length + explodedSites.length;
    final totalSites = toActivateSites.length + activeSites.length;
    final scenario = _bombOperationService.activeSessionScenarioBomb?.bombOperationScenario;

    // Calcul des statistiques
    final armedCount = activeSites.length + explodedSites.length;
    final disarmedCount = _getDisarmedCount();
    final explodedCount = explodedSites.length;

    // Logique de victoire/défaite
    final gameEnded = _isGameEnded(activeSites, _armedBombs);
    final result = _getGameResult(role, explodedCount, disarmedCount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 3, // Bordure épaisse
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9), // Légèrement plus petit que la bordure
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1), // Fond très transparent
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec rôle et objectif - Style militaire
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7), // Fond sombre semi-transparent
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: borderColor.withOpacity(0.8),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              roleIcon,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.youAre(roleText),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        objectiveText,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade200,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Informations sur les sites - Style tactique
                _buildInfoRow(
                  icon: Icons.location_city,
                  label: l10n.sitesActivated(activatedCount, totalSites),
                  color: accentColor,
                  isImportant: true,
                ),

                // Temps d'amorçage/désarmement
                if (scenario != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.timer,
                    label: role == BombOperationTeam.attack
                        ? l10n.armingTime(scenario.armingTime)
                        : l10n.defuseTime(scenario.defuseTime),
                    color: Colors.orange.shade600,
                  ),
                ],

                const SizedBox(height: 16),

                // Liste des bombes amorcées avec timers dynamiques
                if (_armedBombs.isNotEmpty) ...[
                  _buildArmedBombsSection(role, l10n, accentColor),
                  const SizedBox(height: 16),
                ],

                // Statistiques globales - Style dashboard
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade600.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: Colors.grey.shade300,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.bombStats(armedCount, disarmedCount, explodedCount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade200,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Résultat du jeu
                if (gameEnded) ...[
                  const SizedBox(height: 12),
                  _buildGameResultWidget(result, l10n),
                ],

                // Indicateur de zone active - Style alerte
                if (widget.autoManager != null &&
                    widget.autoManager!.isInActiveZone &&
                    widget.autoManager!.currentSite != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.shade600,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.red.shade300,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.inZone(widget.autoManager!.currentSite!.name),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade100,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required Color color,
    bool isImportant = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isImportant ? 15 : 14,
              fontWeight: isImportant ? FontWeight.bold : FontWeight.w500,
              color: Colors.white,
              shadows: const [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArmedBombsSection(BombOperationTeam role, AppLocalizations l10n, Color accentColor) {
    final icon = role == BombOperationTeam.attack ? '🔥' : '⚠️';
    final title = role == BombOperationTeam.attack ? l10n.armedBombs : l10n.bombsToDefuse;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._armedBombs.map((bomb) => _buildBombTimerRow(bomb, l10n)),
        ],
      ),
    );
  }

  Widget _buildBombTimerRow(ArmedBombInfo bomb, AppLocalizations l10n) {
    final remainingSeconds = bomb.remainingSeconds;
    final formattedTime = bomb.formattedRemainingTime;
    final timerColor = bomb.timerColor;

    // Couleur selon le temps restant
    Color textColor;
    switch (timerColor) {
      case TimerColor.critical:
        textColor = Colors.red.shade700;
        break;
      case TimerColor.warning:
        textColor = Colors.orange.shade700;
        break;
      case TimerColor.normal:
        textColor = Colors.black87;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        l10n.bombTimerText(bomb.siteName, formattedTime),
        style: TextStyle(
          fontSize: 13,
          color: textColor,
          fontWeight: timerColor == TimerColor.critical
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildGameResultWidget(GameResult result, AppLocalizations l10n) {
    String resultText;
    Color resultColor;

    switch (result) {
      case GameResult.win:
        resultText = l10n.victory;
        resultColor = Colors.green.shade700;
        break;
      case GameResult.lose:
        resultText = l10n.defeat;
        resultColor = Colors.red.shade700;
        break;
      case GameResult.draw:
        resultText = l10n.draw;
        resultColor = Colors.orange.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: resultColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: resultColor.withOpacity(0.5)),
      ),
      child: Text(
        resultText,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: resultColor,
        ),
      ),
    );
  }

  // Méthodes utilitaires
  int _getDisarmedCount() {
    return _bombOperationService.activeBombSites
        .where((site) => site.active == false)
        .length;
  }

  bool _isGameEnded(
      List<BombSite> activeSites, List<ArmedBombInfo> armedBombs) {
    // 1. Il ne doit plus rester de sites à activer
    final toActivateEmpty = _bombOperationService.toActivateBombSites.isEmpty;

    // 2. Tous les sites activés doivent être soit désamorcés (active == false), soit explosés
    final allHandled =
        _bombOperationService.activeBombSites.every((site) => !site.active);

    return toActivateEmpty && allHandled && armedBombs.isEmpty;
  }

  GameResult _getGameResult(
      BombOperationTeam role, int explodedCount, int disarmedCount) {
    if (explodedCount == disarmedCount) return GameResult.draw;

    if (role == BombOperationTeam.attack) {
      return explodedCount > disarmedCount ? GameResult.win : GameResult.lose;
    } else {
      return disarmedCount > explodedCount ? GameResult.win : GameResult.lose;
    }
  }
}
