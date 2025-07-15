import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Thème global DIY/Militaire pour Game Map Master
/// S'applique automatiquement à tous les widgets sans modification de code
class GlobalMilitaryTheme {
  // Couleurs principales
  static const Color primaryMetal = Color(0xFF4A5568);
  static const Color darkMetal = Color(0xFF2D3748);
  static const Color lightMetal = Color(0xFF718096);
  static const Color accentGreen = Color(0xFF48BB78);
  static const Color warningOrange = Color(0xFFED8936);
  static const Color dangerRed = Color(0xFFE53E3E);
  static const Color textLight = Color(0xFFF7FAFC);
  static const Color textDark = Color(0xFF1A202C);
  
  // Assets paths
  static const String backgroundHome = 'assets/images/theme/background_home.png';
  static const String logoMilitary = 'assets/images/theme/logo_military.png';
  
  /// Thème principal de l'application
  static ThemeData get themeData {
    return ThemeData(
      // Configuration de base
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Couleurs principales
      colorScheme: ColorScheme.dark(
        primary: primaryMetal,
        primaryContainer: darkMetal,
        secondary: accentGreen,
        secondaryContainer: accentGreen.withOpacity(0.3),
        surface: darkMetal,
        background: Color(0xFF1A1A1A),
        error: dangerRed,
        onPrimary: textLight,
        onSecondary: textLight,
        onSurface: textLight,
        onBackground: textLight,
        onError: textLight,
      ),
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryMetal,
        foregroundColor: textLight,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        iconTheme: IconThemeData(
          color: textLight,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      
      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMetal,
          foregroundColor: textLight,
          elevation: 4,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textLight,
          side: BorderSide(color: primaryMetal, width: 2),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentGreen,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Cartes et conteneurs
      cardTheme: CardThemeData(
        color: darkMetal,
        elevation: 6,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primaryMetal.withOpacity(0.3), width: 1),
        ),
      ),
      
      // Champs de texte
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkMetal,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryMetal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryMetal.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: dangerRed),
        ),
        labelStyle: TextStyle(color: textLight.withOpacity(0.8)),
        hintStyle: TextStyle(color: textLight.withOpacity(0.6)),
        prefixIconColor: accentGreen,
        suffixIconColor: lightMetal,
      ),
      
      // Typographie
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: textLight,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
        displayMedium: TextStyle(
          color: textLight,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        displaySmall: TextStyle(
          color: textLight,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        headlineLarge: TextStyle(
          color: textLight,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
        headlineMedium: TextStyle(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
        headlineSmall: TextStyle(
          color: textLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        titleLarge: TextStyle(
          color: textLight,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        titleMedium: TextStyle(
          color: textLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        titleSmall: TextStyle(
          color: textLight,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          color: textLight,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: textLight,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: textLight.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: textLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          color: textLight,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
        labelSmall: TextStyle(
          color: textLight.withOpacity(0.8),
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
      
      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: darkMetal,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryMetal, width: 2),
        ),
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        contentTextStyle: TextStyle(
          color: textLight,
          fontSize: 16,
        ),
      ),
      
      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkMetal,
        selectedItemColor: accentGreen,
        unselectedItemColor: lightMetal,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          letterSpacing: 0.2,
        ),
      ),
      
      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: accentGreen,
        unselectedLabelColor: lightMetal,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: accentGreen, width: 3),
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          letterSpacing: 0.3,
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentGreen,
        foregroundColor: textLight,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Switch et Checkbox
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentGreen;
          }
          return lightMetal;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentGreen.withOpacity(0.5);
          }
          return lightMetal.withOpacity(0.3);
        }),
      ),
      
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentGreen;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(textLight),
        side: BorderSide(color: primaryMetal, width: 2),
      ),
      
      // Progress Indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentGreen,
        linearTrackColor: primaryMetal.withOpacity(0.3),
        circularTrackColor: primaryMetal.withOpacity(0.3),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkMetal,
        contentTextStyle: TextStyle(color: textLight),
        actionTextColor: accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: primaryMetal.withOpacity(0.5),
        thickness: 1,
        space: 16,
      ),
    );
  }
  
  /// Précharge les assets du thème
  static Future<void> precacheAssets(BuildContext context) async {
    await Future.wait([
      precacheImage(AssetImage(backgroundHome), context),
      precacheImage(AssetImage(logoMilitary), context),
    ]);
  }
  
  /// Configuration de la barre de statut
  static void configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: darkMetal,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
}

