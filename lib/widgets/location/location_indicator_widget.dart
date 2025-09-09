import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';

import '../../services/location/advanced_location_service.dart';
import '../../services/location/location_models.dart';
import '../../services/player_location_service.dart';

/// Widget indicateur GPS compact
class LocationIndicatorWidget extends StatefulWidget {
  /// Active l’affichage d’informations techniques de débogage
  /// (compteur de positions reçues / filtrées).
  /// Utile uniquement en mode développement pour analyser la qualité
  /// du flux GPS. À laisser `false` en production.
  final bool showDebugInfo;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const LocationIndicatorWidget({
    Key? key,
    this.showDebugInfo = false,
    this.onTap,
    this.padding,
  }) : super(key: key);

  @override
  State<LocationIndicatorWidget> createState() =>
      _LocationIndicatorWidgetState();
}

class _LocationIndicatorWidgetState extends State<LocationIndicatorWidget> {
  StreamSubscription<EnhancedPosition>? _positionSubscription;
  StreamSubscription<LocationQualityMetrics>? _metricsSubscription;

  AdvancedLocationService get _locationService =>
      GetIt.I<PlayerLocationService>().advancedLocationService;
  EnhancedPosition? _currentPosition =
      GetIt.I<PlayerLocationService>().advancedLocationService.latestPosition;
  LocationQualityMetrics? _currentMetrics;

  @override
  void initState() {
    super.initState();
    _subscribeToLocationUpdates();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _metricsSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToLocationUpdates() {
    if (mounted && _locationService.latestPosition != null) {
      setState(() {
        _currentPosition = _locationService.latestPosition;
      });
    }
    _positionSubscription = _locationService.rawPositionStream.listen(
      (position) {
        print('[LocationIndicatorWidget] 📍 🧪 Raw position received : $position'); // ⬅️
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      },
    );

    _metricsSubscription = _locationService.metricsStream.listen(
      (metrics) {
        if (mounted) {
          setState(() {
            _currentMetrics = metrics;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding:
            widget.padding ?? EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _getBorderColor(), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGpsIcon(),
            SizedBox(width: 8),
            _buildSignalBars(),
            SizedBox(width: 8),
            _buildLocationInfo(),
            if (widget.showDebugInfo) ...[
              SizedBox(width: 8),
              _buildDebugInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGpsIcon() {
    IconData iconData;
    Color iconColor;

    if (!_locationService.isActive || _currentPosition == null) {
      iconData = Icons.gps_off;
      iconColor = Colors.red;
    } else {
      switch (_currentPosition!.quality) {
        case LocationQuality.excellent:
        case LocationQuality.good:
          iconData = Icons.gps_fixed;
          iconColor = Colors.green;
          break;
        case LocationQuality.fair:
          iconData = Icons.gps_not_fixed;
          iconColor = Colors.orange;
          break;
        case LocationQuality.poor:
        case LocationQuality.unusable:
          iconData = Icons.gps_off;
          iconColor = Colors.red;
          break;
      }
    }

    return Icon(iconData, size: 16, color: iconColor);
  }

  Widget _buildSignalBars() {
    return Row(
      children: List.generate(5, (index) {
        bool isActive = _getSignalStrength() > index;
        return Container(
          width: 3,
          height: 8 + (index * 2),
          margin: EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: isActive ? _getSignalColor() : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  Widget _buildLocationInfo() {
    if (!_locationService.isActive) {
      return Text(
        'GPS: Inactif',
        style: TextStyle(
            fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500),
      );
    }

    if (_currentPosition == null) {
      return Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
          const SizedBox(width: 6),
          Text(
            'Recherche signal...',
            style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500),
          ),
        ],
      );
    }

    String accuracyText = '${_currentPosition!.accuracy.toStringAsFixed(0)}m';
    String speedText = _currentPosition!.isStationary
        ? 'Immobile'
        : '${(_currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h';

    String statusIcon = _getAirsoftMovementIcon();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'GPS: $accuracyText',
              style: TextStyle(
                  fontSize: 11,
                  color: _getTextColor(),
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(width: 4),
            Text(statusIcon, style: TextStyle(fontSize: 10)),
          ],
        ),
        Text(
          speedText,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildDebugInfo() {
    if (_currentMetrics == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Reçus: ${_currentMetrics!.totalPositions}',
            style: TextStyle(fontSize: 9, color: Colors.grey)),
        Text('Filtrés: ${_currentMetrics!.filteredPositions}',
            style: TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  String _getAirsoftMovementIcon() {
    if (_currentPosition == null) return '❓';

    if (_currentPosition!.isStationary) return '🛑';

    double speedKmh = _currentPosition!.speed * 3.6;
    if (speedKmh < 1.0) return '🛑'; // Très lent = immobile
    if (speedKmh < 3.0) return '🏃'; // Mouvement tactique
    if (speedKmh < 6.0) return '🚶'; // Marche
    return '🏃';
  }

  int _getSignalStrength() {
    if (!_locationService.isActive || _currentPosition == null) return 0;

    switch (_currentPosition!.quality) {
      case LocationQuality.excellent:
        return 5;
      case LocationQuality.good:
        return 4;
      case LocationQuality.fair:
        return 3;
      case LocationQuality.poor:
        return 2;
      case LocationQuality.unusable:
        return 1;
    }
  }

  Color _getSignalColor() {
    if (!_locationService.isActive || _currentPosition == null)
      return Colors.red;

    switch (_currentPosition!.quality) {
      case LocationQuality.excellent:
      case LocationQuality.good:
        return Colors.green;
      case LocationQuality.fair:
        return Colors.orange;
      case LocationQuality.poor:
      case LocationQuality.unusable:
        return Colors.red;
    }
  }

  Color _getBackgroundColor() {
    if (!_locationService.isActive || _currentPosition == null)
      return Colors.red.shade50;

    switch (_currentPosition!.quality) {
      case LocationQuality.excellent:
      case LocationQuality.good:
        return Colors.green.shade50;
      case LocationQuality.fair:
        return Colors.orange.shade50;
      case LocationQuality.poor:
      case LocationQuality.unusable:
        return Colors.red.shade50;
    }
  }

  Color _getBorderColor() {
    if (!_locationService.isActive || _currentPosition == null)
      return Colors.red.shade200;

    switch (_currentPosition!.quality) {
      case LocationQuality.excellent:
      case LocationQuality.good:
        return Colors.green.shade200;
      case LocationQuality.fair:
        return Colors.orange.shade200;
      case LocationQuality.poor:
      case LocationQuality.unusable:
        return Colors.red.shade200;
    }
  }

  Color _getTextColor() {
    if (!_locationService.isActive || _currentPosition == null)
      return Colors.red.shade700;

    switch (_currentPosition!.quality) {
      case LocationQuality.excellent:
      case LocationQuality.good:
        return Colors.green.shade700;
      case LocationQuality.fair:
        return Colors.orange.shade700;
      case LocationQuality.poor:
      case LocationQuality.unusable:
        return Colors.red.shade700;
    }
  }
}
