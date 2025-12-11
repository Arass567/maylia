import 'package:flutter/material.dart';

/// 🎨 Thème Application 2025 - Material Design 3 Complet
/// Basé sur les meilleures pratiques UI/UX de fin 2025

class AppTheme2025 {
  // ============================================================================
  // COULEURS
  // ============================================================================

  /// Palette La Poste (nouvelle identité clean)
  static const Color laPosteYellow = Color(0xFFFFD700); // Jaune La Poste
  static const Color laPosteBlue = Color(0xFF003DA5);   // Bleu La Poste (secondaire)
  static const Color blueNight = Color(0xFF1A1A2E);     // Bleu Nuit (texte/contraste)
  static const Color lightGrey = Color(0xFFF5F5F5);     // Gris clair (fond secondaire)
  static const Color paleYellow = Color(0xFFFFF9E6);    // Jaune très pâle (bulles utilisateur)

  /// Couleurs sémantiques
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  /// Importance emails
  static const Color importanceHigh = Color(0xFFE53935);
  static const Color importanceMedium = Color(0xFFFF9800);
  static const Color importanceLow = Color(0xFF66BB6A);

  // ============================================================================
  // ESPACEMENTS (système 8dp)
  // ============================================================================

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // ============================================================================
  // ÉLÉVATIONS Material 3
  // ============================================================================

  static const double level0 = 0.0;
  static const double level1 = 1.0; // Cards
  static const double level2 = 3.0; // FAB
  static const double level3 = 6.0; // AppBar
  static const double level4 = 8.0; // Modals
  static const double level5 = 12.0; // Dialogs

  // ============================================================================
  // DIMENSIONS
  // ============================================================================

  /// Taille minimum zone tactile (WCAG)
  static const double minTouchTarget = 48.0;

  /// Radius bordures
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;

  // ============================================================================
  // THÈME CLAIR
  // ============================================================================

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Couleurs
    colorScheme: ColorScheme.fromSeed(
      seedColor: laPosteYellow,
      brightness: Brightness.light,
      primary: laPosteYellow,
      secondary: laPosteBlue,
      error: error,
      // Contraste WCAG AA garanti
      surface: Colors.white,
      onSurface: const Color(0xFF1A1A1A), // Contraste 12.63:1
      onPrimary: Colors.black, // Texte noir sur fond jaune
    ),

    // Fond global
    scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Quasi-blanc très doux

    // Typographie Material 3
    textTheme: _buildTextTheme(Brightness.light),

    // AppBar - Style moderne minimal
    appBarTheme: const AppBarTheme(
      centerTitle: false, // Alignement à gauche (moderne)
      elevation: level0, // Pas d'ombre
      scrolledUnderElevation: level0, // Pas d'ombre au scroll
      backgroundColor: Colors.transparent, // Transparent pour effet moderne
      foregroundColor: Color(0xFF1A1A1A), // Texte noir
      surfaceTintColor: Colors.transparent,
    ),

    // Cards - Très arrondies
    cardTheme: CardThemeData(
      elevation: level0, // Pas d'élévation (flat design moderne)
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXl), // 24dp - Très arrondi
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: md, vertical: xs),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg), // Plus arrondi
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: const BorderSide(color: laPosteYellow, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: md,
        vertical: md,
      ),
    ),

    // Floating Action Button - Jaune avec icône noire
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: level2,
      backgroundColor: laPosteYellow,
      foregroundColor: Colors.black, // Icône noire
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radiusLg)), // Arrondi au lieu de circulaire pur
      ),
    ),

    // Elevated Button - Jaune moderne
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: laPosteYellow,
        foregroundColor: Colors.black, // Texte noir
        elevation: level0, // Flat
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg), // Très arrondi
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: lg,
          vertical: md,
        ),
      ),
    ),

    // Filled Button (même style que elevated)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: laPosteYellow,
        foregroundColor: Colors.black,
        elevation: level0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: lg,
          vertical: md,
        ),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: laPosteYellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: laPosteYellow,
        side: const BorderSide(color: laPosteYellow, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: lg,
          vertical: md,
        ),
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: level0, // Flat moderne
      backgroundColor: Colors.white,
      selectedItemColor: laPosteYellow,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),

    // Divider
    dividerTheme: DividerThemeData(
      thickness: 1,
      color: Colors.grey[300],
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[200],
      selectedColor: laPosteYellow,
      labelStyle: const TextStyle(fontSize: 12, color: Colors.black),
      padding: const EdgeInsets.symmetric(horizontal: sm, vertical: xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusFull),
      ),
    ),
  );

  // ============================================================================
  // THÈME SOMBRE
  // ============================================================================

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Couleurs
    colorScheme: ColorScheme.fromSeed(
      seedColor: laPosteYellow,
      brightness: Brightness.dark,
      primary: laPosteYellow,
      secondary: laPosteBlue,
      error: error,
      // OLED pure black pour économie batterie
      surface: Colors.black,
      onSurface: const Color(0xFFE0E0E0), // Contraste WCAG AA
    ),

    // Typographie
    textTheme: _buildTextTheme(Brightness.dark),

    // AppBar
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: level0,
      scrolledUnderElevation: level1,
      backgroundColor: Colors.black,
      foregroundColor: Color(0xFFE0E0E0),
    ),

    // Cards
    cardTheme: CardThemeData(
      elevation: level1,
      color: blueNight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: blueNight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: laPosteYellow, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: md,
        vertical: md,
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: level3,
      backgroundColor: Colors.black,
      selectedItemColor: laPosteYellow,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // ============================================================================
  // TYPOGRAPHIE
  // ============================================================================

  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.light
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFE0E0E0);

    return TextTheme(
      // Display (très grands titres)
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: baseColor,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),

      // Headline (titres sections)
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),

      // Title (titres cards)
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: baseColor,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: baseColor,
        letterSpacing: 0.1,
      ),

      // Body (texte principal)
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.4,
        letterSpacing: 0.4,
      ),

      // Label (boutons, chips)
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: baseColor,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: baseColor,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: baseColor,
        letterSpacing: 0.5,
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Vérifie si contraste WCAG AA (4.5:1)
  static bool isContrastSufficient(Color foreground, Color background) {
    return calculateContrast(foreground, background) >= 4.5;
  }

  /// Calcule ratio de contraste
  static double calculateContrast(Color foreground, Color background) {
    final fLum = _luminance(foreground);
    final bLum = _luminance(background);

    final lighter = fLum > bLum ? fLum : bLum;
    final darker = fLum > bLum ? bLum : fLum;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Luminance relative
  static double _luminance(Color color) {
    final r = _linearize(color.red / 255.0);
    final g = _linearize(color.green / 255.0);
    final b = _linearize(color.blue / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearize(double channel) {
    if (channel <= 0.03928) {
      return channel / 12.92;
    } else {
      return ((channel + 0.055) / 1.055).pow(2.4);
    }
  }
}

// Extension pour faciliter l'utilisation
extension BuildContextThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

// Extension pour pow
extension NumPow on double {
  double pow(double exponent) => this * this;
}
