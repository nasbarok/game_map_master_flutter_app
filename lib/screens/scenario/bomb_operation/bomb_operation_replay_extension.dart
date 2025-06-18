import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_operation_history.dart';
import 'package:airsoft_game_map/models/scenario/bomb_operation/bomb_site_history.dart';
import 'package:airsoft_game_map/services/scenario/bomb_operation/bomb_operation_history_service.dart';
import 'package:airsoft_game_map/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

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
  
  BombOperationReplayExtension() : _historyService = BombOperationHistoryService();
  
  @override
  Future<void> loadData(int gameSessionId) async {
    try {
      _bombHistory = await _historyService.getSessionHistory(gameSessionId);
    } catch (e) {
      print('❌ Erreur lors du chargement des données Bomb Operation: $e');
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
    
    for (final siteHistory in _bombHistory!.bombSitesHistory) {
      // Créer un état basé sur le temps actuel
      final currentState = BombSiteHistory(
        id: siteHistory.id,
        gameSessionId: siteHistory.gameSessionId,
        originalBombSiteId: siteHistory.originalBombSiteId,
        name: siteHistory.name,
        latitude: siteHistory.latitude,
        longitude: siteHistory.longitude,
        radius: siteHistory.radius,
        status: _calculateStatusAtTime(siteHistory, _currentTime!),
        createdAt: siteHistory.createdAt,
        updatedAt: siteHistory.updatedAt,
        activatedAt: siteHistory.activatedAt,
        armedAt: siteHistory.armedAt,
        disarmedAt: siteHistory.disarmedAt,
        explodedAt: siteHistory.explodedAt,
        armedByUserId: siteHistory.armedByUserId,
        armedByUserName: siteHistory.armedByUserName,
        disarmedByUserId: siteHistory.disarmedByUserId,
        disarmedByUserName: siteHistory.disarmedByUserName,
        bombTimer: siteHistory.bombTimer,
        expectedExplosionAt: siteHistory.expectedExplosionAt,
        timeRemainingSeconds: siteHistory.timeRemainingSeconds,
        shouldHaveExploded: siteHistory.shouldHaveExploded,
      );
      
      // Vérifier si le site était créé à ce moment
      if (!siteHistory.createdAt.isAfter(_currentTime!)) {
        newSitesState[siteHistory.originalBombSiteId] = currentState;
      }
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
    
    if (siteHistory.activatedAt != null && !time.isBefore(siteHistory.activatedAt!)) {
      status = 'ACTIVE';
    }
    
    if (siteHistory.armedAt != null && !time.isBefore(siteHistory.armedAt!)) {
      status = 'ARMED';
    }
    
    if (siteHistory.disarmedAt != null && !time.isBefore(siteHistory.disarmedAt!)) {
      status = 'DISARMED';
    }
    
    if (siteHistory.explodedAt != null && !time.isBefore(siteHistory.explodedAt!)) {
      status = 'EXPLODED';
    }
    
    return status;
  }
  
  @override
  List<Marker> buildMarkers() {
    if (_bombHistory == null) return [];
    
    final List<Marker> markers = [];
    const double currentZoom = 15.0; // Zoom par défaut pour le calcul des rayons
    
    for (final siteState in _currentSitesState.values) {
      final radiusInPixels = AppUtils.metersToPixels(siteState.radius, siteState.latitude, currentZoom);
      
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
              width: 2,
            ),
          ),
        ),
        
        // Icône centrale
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: markerColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            markerIcon,
            color: Colors.white,
            size: 24,
          ),
        ),
        
        // Nom du site
        Positioned(
          bottom: -25,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              siteState.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: math.min(dynamicFontSize, 12),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  @override
  Widget? buildInfoPanel() {
    if (_bombHistory == null) return null;
    
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Résumé des équipes
          Row(
            children: [
              // Équipe Terroriste
              Expanded(
                child: _buildTeamSummary(
                  'Terroristes',
                  Colors.red,
                  _bombHistory!.finalStats.armedSites,
                  _bombHistory!.finalStats.explodedSites,
                  'Bombes armées',
                  'Bombes explosées',
                ),
              ),
              SizedBox(width: 16),
              // Équipe Anti-terroriste
              Expanded(
                child: _buildTeamSummary(
                  'Anti-terroristes',
                  Colors.blue,
                  _bombHistory!.finalStats.totalSites - _bombHistory!.finalStats.armedSites,
                  _bombHistory!.finalStats.disarmedSites,
                  'Sites protégés',
                  'Bombes désarmées',
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Résultat final
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: _getResultColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getResultText(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          SizedBox(height: 12),
          
          // Timeline des événements visibles
          if (_visibleEvents.isNotEmpty)
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _visibleEvents.length,
                itemBuilder: (context, index) {
                  final event = _visibleEvents[index];
                  return Container(
                    width: 200,
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getEventIcon(event.eventType),
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(height: 4),
                        Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          event.siteName,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTeamSummary(String teamName, Color teamColor, int stat1, int stat2, String label1, String label2) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: teamColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: teamColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: teamColor,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text('$label1: $stat1'),
          Text('$label2: $stat2'),
        ],
      ),
    );
  }
  
  String _getEventIcon(String eventType) {
    switch (eventType) {
      case 'ACTIVATED':
        return '🟠';
      case 'ARMED':
        return '💣';
      case 'DISARMED':
        return '🛡️';
      case 'EXPLODED':
        return '💥';
      default:
        return '📍';
    }
  }
  
  Color _getResultColor() {
    if (_bombHistory == null) return Colors.grey;
    
    final winningTeam = _bombHistory!.finalStats.winningTeam;
    switch (winningTeam) {
      case 'ATTACK':
        return Colors.red;
      case 'DEFENSE':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
  
  String _getResultText() {
    if (_bombHistory == null) return 'Aucun résultat';
    
    final winningTeam = _bombHistory!.finalStats.winningTeam;
    switch (winningTeam) {
      case 'ATTACK':
        return '🔥 Victoire des Terroristes';
      case 'DEFENSE':
        return '🛡️ Victoire des Anti-terroristes';
      default:
        return '🤝 Match nul';
    }
  }
  
  @override
  bool get hasData => _bombHistory != null;
  
  @override
  String get scenarioName => _bombHistory?.scenarioName ?? 'Bomb Operation';
  
  @override
  String get scenarioType => 'BOMB_OPERATION';
  
  @override
  void dispose() {
    _bombHistory = null;
    _currentSitesState.clear();
    _visibleEvents.clear();
    _currentTime = null;
  }
}

