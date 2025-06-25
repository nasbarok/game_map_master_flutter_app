import 'package:game_map_master_flutter_app/models/scenario/bomb_operation/bomb_site_history.dart';
import 'package:game_map_master_flutter_app/services/scenario/bomb_operation/bomb_operation_history_service.dart';
import 'package:game_map_master_flutter_app/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'package:game_map_master_flutter_app/utils/logger.dart';

import '../../../models/scenario/bomb_operation/bomb_operation_history.dart';
import '../../../models/scenario/scenario_replay_extension.dart';

/// Extension de replay pour le scénario Bomb Operation
///
/// Cette classe gère l'affichage et la logique de replay spécifique
/// au scénario Bomb Operation, en réutilisant le même style visuel
/// que BombOperationMapExtension
class BombOperationReplayExtension implements ScenarioReplayExtension {
  final BombOperationHistoryService _historyService;

  BombOperationHistory? _bombHistory;
  Map<int, BombSiteHistory> _currentSitesState = {};
  List<BombEvent> _visibleEvents = [];
  DateTime? _currentTime;
  double _zoomLevel = 17.0; // Valeur par défaut

  BombOperationReplayExtension()
      : _historyService = BombOperationHistoryService();

  @override
  Future<void> loadData(int gameSessionId) async {
    try {
      _bombHistory = await _historyService.getSessionHistory(gameSessionId);
    } catch (e) {
      logger.d(
          '❌[BombOperationReplayExtension] [loadData] Erreur lors du chargement des données Bomb Operation: $e');
      _bombHistory = null;
    }
  }

  @override
  void updateState(DateTime currentTime) {
    _currentTime = currentTime;
    _updateSitesState();
    _updateVisibleEvents();
  }

  void _updateSitesState() {
    if (_bombHistory == null || _currentTime == null) return;

    final newSitesState = <int, BombSiteHistory>{};

    // 1️⃣ Associer les timestamps SITE_ACTIVATED aux sites
    final Map<int, DateTime> activatedTimes = {};
    for (final event in _bombHistory!.timeline) {
      if (event.eventType == 'SITE_ACTIVATED') {
        final site = _bombHistory!.bombSitesHistory.firstWhere(
          (s) => s.name == event.siteName,
          orElse: () => BombSiteHistory(
            id: -1,
            originalBombSiteId: -1,
            name: '',
            latitude: 0.0,
            longitude: 0.0,
            radius: 5.0,
            status: 'INACTIVE',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            gameSessionId: null,
          ),
        );
        if (site != null) {
          activatedTimes[site.originalBombSiteId] = event.timestamp;
        }
      }
    }

    // 2️⃣ Construire l'état actuel de chaque site
    for (final siteHistory in _bombHistory!.bombSitesHistory) {
      final activationTime = siteHistory.activatedAt ??
          activatedTimes[siteHistory.originalBombSiteId];

      // ⚠️ Ne pas masquer les sites si un event SITE_ACTIVATED existe déjà
      final siteWasActivated = _bombHistory!.timeline.any(
            (e) => e.eventType == 'SITE_ACTIVATED' && e.siteName == siteHistory.name,
      );

      if (!siteWasActivated) {
        debugPrint('[ReplayExtension] ⏳ Site ${siteHistory.name} ignoré (jamais activé dans la timeline)');
        continue;
      }

      // 👷 Appliquer une version modifiée avec activatedAt injecté
      final patchedSite = siteHistory.copyWith(activatedAt: activationTime);

      final computedStatus = _calculateStatusAtTime(patchedSite, _currentTime!);

      final visibleSite = patchedSite.copyWith(status: computedStatus);
      newSitesState[visibleSite.originalBombSiteId] = visibleSite;

      debugPrint(
          '[ReplayExtension] ✅ Site visible : ${visibleSite.name} (id=${visibleSite.originalBombSiteId}) → statut calculé=$computedStatus');
    }

    _currentSitesState = newSitesState;
  }

  void _updateVisibleEvents() {
    if (_bombHistory == null || _currentTime == null) return;

    _visibleEvents = _bombHistory!.timeline
        .where((event) => !event.timestamp.isAfter(_currentTime!))
        .toList();
  }

  String _calculateStatusAtTime(BombSiteHistory siteHistory, DateTime time) {
    // Déterminer le statut au temps donné
    String status = 'INACTIVE';

    if (siteHistory.activatedAt != null &&
        !time.isBefore(siteHistory.activatedAt!)) {
      status = 'ACTIVE';
    }

    if (siteHistory.armedAt != null && !time.isBefore(siteHistory.armedAt!)) {
      status = 'ARMED';
    }

    if (siteHistory.disarmedAt != null &&
        !time.isBefore(siteHistory.disarmedAt!)) {
      status = 'DISARMED';
    }

    if (siteHistory.explodedAt != null &&
        !time.isBefore(siteHistory.explodedAt!)) {
      status = 'EXPLODED';
    }

    return status;
  }

  @override
  List<Marker> buildMarkers() {
    if (_bombHistory == null) return [];

    logger.d('[ReplayExtension] 📍 Construction des marqueurs... ${_currentSitesState.length} sites visibles à l’instant');

    final List<Marker> markers = [];

    for (final siteState in _currentSitesState.values) {
      final radiusInMeters = siteState.radius;
      final lat = siteState.latitude;
      final zoom = _zoomLevel;

      final radiusInPixels = AppUtils.metersToPixelsForReplay(
          radiusInMeters, lat, zoom);

      logger.d('🔍 Site "${siteState.name}" : radius=$radiusInMeters m, zoom=$zoom → radiusPixels=$radiusInPixels');

      markers.add(
        Marker(
          point: LatLng(siteState.latitude, siteState.longitude),
          width: radiusInPixels * 2,
          height: radiusInPixels * 2,
          child: _buildBombSiteMarker(
            siteState: siteState,
            radiusInPixels: radiusInPixels,
          ),
        ),
      );
    }

    return markers;
  }


  /// Construit un marqueur pour un site de bombe (style identique à BombOperationMapExtension)
  Widget _buildBombSiteMarker({
    required BombSiteHistory siteState,
    required double radiusInPixels,
  }) {
    Color markerColor;
    IconData markerIcon;

    switch (siteState.status) {
      case 'EXPLODED':
        markerColor = Colors.black;
        markerIcon = Icons.whatshot;
        break;
      case 'DISARMED':
        markerColor = Colors.blue;
        markerIcon = Icons.shield;
        break;
      case 'ARMED':
        markerColor = Colors.red.shade800;
        markerIcon = Icons.local_fire_department;
        break;
      case 'ACTIVE':
        markerColor = Colors.orange;
        markerIcon = Icons.location_on;
        break;
      default:
        markerColor = Colors.grey;
        markerIcon = Icons.location_on;
    }

    final double dynamicFontSize = math.max(8, radiusInPixels / 3);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Cercle de rayon du site
        Container(
          width: radiusInPixels * 2,
          height: radiusInPixels * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: markerColor.withOpacity(0.2),
            border: Border.all(
              color: markerColor,
              width: siteState.status == 'EXPLODED' ? 3 : 2,
            ),
          ),
        ),

        // Icône centrale
        Icon(
          markerIcon,
          color: markerColor,
          size: dynamicFontSize * 1.2,
        ),

        // Nom du site
        Positioned(
          bottom: radiusInPixels * 0.1,
          child: Text(
            siteState.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  siteState.status == 'EXPLODED' ? Colors.white : Colors.black,
              fontSize: dynamicFontSize,
              fontWeight: siteState.status == 'EXPLODED'
                  ? FontWeight.w900
                  : FontWeight.bold,
              shadows: [
                Shadow(
                  offset: const Offset(0, 0),
                  blurRadius: 2,
                  color: siteState.status == 'EXPLODED'
                      ? Colors.black
                      : Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget? buildInfoPanel() {
    if (_bombHistory == null) return null;

    // Afficher uniquement un petit indicateur d'état des sites
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatusIndicator(
              'ACTIVE', Colors.orange, _countSitesByStatus('ACTIVE')),
          SizedBox(width: 16),
          _buildStatusIndicator(
              'ARMED', Colors.red.shade800, _countSitesByStatus('ARMED')),
          SizedBox(width: 16),
          _buildStatusIndicator(
              'DISARMED', Colors.blue, _countSitesByStatus('DISARMED')),
          SizedBox(width: 16),
          _buildStatusIndicator(
              'EXPLODED', Colors.black, _countSitesByStatus('EXPLODED')),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status, Color color, int count) {
    IconData icon;
    switch (status) {
      case 'EXPLODED':
        icon = Icons.whatshot;
        break;
      case 'DISARMED':
        icon = Icons.shield;
        break;
      case 'ARMED':
        icon = Icons.local_fire_department;
        break;
      case 'ACTIVE':
        icon = Icons.location_on;
        break;
      default:
        icon = Icons.circle;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(width: 4),
        Text('$count', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  int _countSitesByStatus(String status) {
    return _currentSitesState.values
        .where((site) => site.status == status)
        .length;
  }

  @override
  bool get hasData => _bombHistory != null;

  @override
  String get scenarioName => _bombHistory?.scenarioName ?? 'Bomb Operation';

  @override
  String get scenarioType => 'BOMB_OPERATION';

  @override
  void updateZoom(double zoom) {
    _zoomLevel = zoom;
  }
  @override
  void dispose() {
    // Rien à libérer pour l'instant
  }
}
