import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/scenario/bomb_operation/bomb_operation_team.dart';
import '../models/scenario/bomb_operation/bomb_site.dart';
import '../models/websocket/bomb_planted_message.dart';
import '../services/scenario/bomb_operation/bomb_operation_auto_manager.dart';
import '../services/scenario/bomb_operation/bomb_operation_service.dart';
import '../services/scenario/bomb_operation/bomb_timer_calculator_service.dart';
import '../utils/logger.dart';

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

  static final Color neutralCardColor = Colors.grey.shade200;
  static final Color attackCardColor = Colors.red.shade100;
  static final Color defenseCardColor = Colors.blue.shade100;

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

      final scenario = bombOperationService.activeSessionScenarioBomb?.bombOperationScenario;
      if (scenario == null) return;

      final activeSites = bombOperationService.activeBombSites;
      final newArmedBombs = activeSites.map((site) {
        return ArmedBombInfo(
          siteId: site.id!,
          siteName: site.name,
          plantedTimestamp: site.plantedTimestamp ?? DateTime.now(), // ✅ vraie valeur si dispo
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
        logger.d('🟦 Bombe désamorcée détectée : ${bomb.siteName} – suppression du timer');
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
    final scenario = _bombOperationService.activeSessionScenarioBomb?.bombOperationScenario;
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
      logger.d('⚠️ [BombOperationInfoCard] teamId est null, impossible d\'afficher le rôle');
      return const SizedBox.shrink();
    }

    final teamRoles = _bombOperationService.teamRoles;
    
    if (teamRoles.isEmpty) {
      logger.d('⚠️ [BombOperationInfoCard] Aucun rôle d\'équipe défini');
      return Card(
        color: neutralCardColor,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Scénario Opération Bombe actif - En attente d\'assignation des rôles',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final role = teamRoles[widget.teamId];
    if (role == null) {
      logger.d('⚠️ [BombOperationInfoCard] Aucun rôle trouvé pour l\'équipe ${widget.teamId}');
      return Card(
        color: neutralCardColor,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Votre équipe n\'a pas de rôle assigné dans ce scénario',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return _buildEnrichedInfoCard(role);
  }

  Widget _buildEnrichedInfoCard(BombOperationTeam role) {
    // Déterminer le style en fonction du rôle
    String roleText;
    String objectiveText;
    Color cardColor;
    IconData roleIcon;

    switch (role) {
      case BombOperationTeam.attack:
        roleText = 'Terroriste';
        objectiveText = 'Objectif : Rendez-vous dans une zone de bombe pour activer la détonation';
        cardColor = attackCardColor;
        roleIcon = Icons.dangerous;
        break;
      case BombOperationTeam.defense:
        roleText = 'Anti-terroriste';
        objectiveText = 'Objectif : Rendez-vous dans la zone de bombe active pour la désactiver';
        cardColor = defenseCardColor;
        roleIcon = Icons.shield;
        break;
      default:
        roleText = 'Rôle inconnu';
        objectiveText = 'Objectif : Observer la partie';
        cardColor = neutralCardColor;
        roleIcon = Icons.question_mark;
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

    return Card(
      color: cardColor,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec rôle et objectif
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(roleIcon, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Vous êtes : $roleText',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    objectiveText,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Informations sur les sites
            Text(
              '$activatedCount sites activés sur $totalSites',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),

            // Temps d'amorçage/désarmement
            if (scenario != null) ...[
              const SizedBox(height: 4),
              Text(
                role == BombOperationTeam.attack
                  ? 'Temps d\'amorçage : ${scenario.armingTime}s'
                  : 'Temps de désarmement : ${scenario.defuseTime}s',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],

            const SizedBox(height: 16),

            // Liste des bombes amorcées avec timers dynamiques
            if (_armedBombs.isNotEmpty) ...[
              _buildArmedBombsSection(role),
              const SizedBox(height: 16),
            ],

            // Statistiques globales
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                '$armedCount bombes amorcées • $disarmedCount désarmées • $explodedCount explosées',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),

            // Résultat du jeu
            if (gameEnded) ...[
              const SizedBox(height: 12),
              _buildGameResultWidget(result),
            ],

            // Indicateur de zone active
            if (widget.autoManager != null && widget.autoManager!.isInActiveZone && widget.autoManager!.currentSite != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red.shade700, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Dans la zone : ${widget.autoManager!.currentSite!.name}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildArmedBombsSection(BombOperationTeam role) {
    final icon = role == BombOperationTeam.attack ? '🔥' : '⚠️';
    final title = role == BombOperationTeam.attack ? 'Bombes armées :' : 'Bombes à désarmer :';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$icon $title',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._armedBombs.map((bomb) => _buildBombTimerRow(bomb)),
      ],
    );
  }

  Widget _buildBombTimerRow(ArmedBombInfo bomb) {
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
        'Bombe du site ${bomb.siteName} amorcée - explosion dans $formattedTime',
        style: TextStyle(
          fontSize: 13,
          color: textColor,
          fontWeight: timerColor == TimerColor.critical ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildGameResultWidget(GameResult result) {
    String resultText;
    Color resultColor;

    switch (result) {
      case GameResult.win:
        resultText = '🏆 Victoire !';
        resultColor = Colors.green.shade700;
        break;
      case GameResult.lose:
        resultText = '💀 Défaite !';
        resultColor = Colors.red.shade700;
        break;
      case GameResult.draw:
        resultText = '⚖️ Égalité';
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
    return _bombOperationService.activeBombSites.where((site) => site.active == false).length;
  }

  bool _isGameEnded(List<BombSite> activeSites, List<ArmedBombInfo> armedBombs) {
    // 1. Il ne doit plus rester de sites à activer
    final toActivateEmpty = _bombOperationService.toActivateBombSites.isEmpty;

    // 2. Tous les sites activés doivent être soit désamorcés (active == false), soit explosés
    final allHandled = _bombOperationService.activeBombSites.every((site) => !site.active);

    return toActivateEmpty && allHandled && armedBombs.isEmpty;
  }

  GameResult _getGameResult(BombOperationTeam role, int explodedCount, int disarmedCount) {
    if (explodedCount == disarmedCount) return GameResult.draw;

    if (role == BombOperationTeam.attack) {
      return explodedCount > disarmedCount ? GameResult.win : GameResult.lose;
    } else {
      return disarmedCount > explodedCount ? GameResult.win : GameResult.lose;
    }
  }

}
