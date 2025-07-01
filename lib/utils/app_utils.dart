import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';
class AppUtils {
  /// Convertit une distance en mètres en pixels sur la carte selon le niveau de zoom
  static double metersToPixels(double meters, double latitude, double zoom) {
    // Constante pour la circonférence de la Terre en mètres
    const earthCircumference = 40075016.686;

    // Calcul du nombre de pixels par mètre à l'équateur au niveau de zoom actuel
    final metersPerPixel = earthCircumference * math.cos(latitude * math.pi / 180) / math.pow(2, zoom + 8);

    //logger.d('📌 [AppUtils] metersToPixels: meters=$meters, latitude=$latitude, zoom=$zoom, metersPerPixel=$metersPerPixel');
    // Conversion des mètres en pixels
    return meters / metersPerPixel;
  }

  static double metersToPixelsForReplay(double meters, double latitude, double zoom) {
    const earthCircumference = 40075016.686;
    final latitudeRad = latitude * math.pi / 180;
    final metersPerPixel = (earthCircumference * math.cos(latitudeRad)) / (256 * math.pow(2, zoom));
    return meters / metersPerPixel;
  }

  static double computeDistanceMeters(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const R = 6371000; // Rayon de la Terre en mètres
    final dLat = degToRad(lat2 - lat1);
    final dLon = degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(degToRad(lat1)) *
            math.cos(degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double degToRad(double deg) => deg * math.pi / 180;

  static Color parsePoiColor(String? color) {
    if (color != null && color.length == 7 && color.startsWith('#')) {
      try {
        return Color(int.parse(color.replaceAll('#', '0xFF')));
      } catch (e) {
        // log possible ici
        return Colors.orange;
      }
    }
    return Colors.orange;
  }

  static shortenDescription(String s, {required int maxLength}) {
    if (s.length <= maxLength) return s;
    return '${s.substring(0, maxLength).trim()}...';
  }

  static LocaleType getDatePickerLocale(Locale flutterLocale) {
    switch (flutterLocale.languageCode) {
      case 'fr':
        return LocaleType.fr;
      case 'de':
        return LocaleType.de;
      case 'es':
        return LocaleType.es;
      case 'it':
        return LocaleType.it;
      case 'ja':
        return LocaleType.jp;
      case 'nl':
        return LocaleType.nl;
      case 'no':
        return LocaleType.no;
      case 'pl':
        return LocaleType.pl;
      case 'pt':
        return LocaleType.pt;
      case 'sv':
        return LocaleType.sv;
      default:
        return LocaleType.en; // fallback
    }
  }
}