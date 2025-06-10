import 'dart:math' as math;

import 'package:airsoft_game_map/utils/logger.dart';
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
}