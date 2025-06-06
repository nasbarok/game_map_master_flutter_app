import 'dart:math' as math;

class AppUtils {
  /// Convertit une distance en mètres en pixels sur la carte selon le niveau de zoom
  static double metersToPixels(double meters, double latitude, double zoom) {
    // Constante pour la circonférence de la Terre en mètres
    const earthCircumference = 40075016.686;

    // Calcul du nombre de pixels par mètre à l'équateur au niveau de zoom actuel
    final metersPerPixel = earthCircumference * math.cos(latitude * math.pi / 180) / math.pow(2, zoom + 8);

    // Conversion des mètres en pixels
    return meters / metersPerPixel;
  }

}