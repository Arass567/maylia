import 'package:flutter/material.dart';

/// 🎨 Thème Application 2025 - Material Design 3 Complet
/// Basé sur les meilleures pratiques UI/UX de fin 2025

class AppTheme2025 {
  // ============================================================================
  // COULEURS
  // ============================================================================

  /// Nouvelle Palette - Combination No. 140 (Modern Professional Design)
  static const Color goldenYellow = Color(0xFFF3A257);  // Golden Yellow - Couleur principale
  static const Color antwarpBlue = Color(0xFF007190);   // Antwarp Blue - Accents
  static const Color slateColor = Color(0xFF34454C);    // Slate Color - Textes/éléments sombres
  static const Color lightCream = Color(0xFFFAF8F3);    // Fond beige/crème clair
  static const Color paleCream = Color(0xFFFFF5E9);     // Crème très pâle (bulles utilisateur)

  // Alias pour compatibilité avec code existant
  static const Color laPosteYellow = goldenYellow;
  static const Color laPosteBlue = antwarpBlue;

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
      seedColor: goldenYellow,
      brightness: Brightness.light,
      primary: goldenYellow,
      secondary: antwarpBlue,
      error: error,
      // Contraste WCAG AA garanti
      surface: Colors.white,
      onSurface: slateColor, // Texte Slate Color pour un look moderne
      onPrimary: Colors.white, // Texte blanc sur fond orange
    ),

    // Fond global - Crème clair pour un look moderne et chaleureux
    scaffoldBackgroundColor: lightCream, // Beige/crème clair

    // Typographie Material 3
    textTheme: _buildTextTheme(Brightness.light),

    // AppBar - Style moderne avec fond Golden Yellow
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: level0,
      scrolledUnderElevation: level0,
      backgroundColor: Colors.transparent, // << NEUTRAL
      foregroundColor: slateColor, // << Dark text for light background
      iconTheme: IconThemeData(color: slateColor), // << Dark icons
      surfaceTintColor: Colors.transparent,
    ),

    // Cards - Arrondies avec ombres légères pour profondeur
    cardTheme: CardThemeData(
      elevation: level1, // Légère élévation pour un effet de profondeur
      shadowColor: Colors.black12, // Ombre très subtile
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg), // 16dp - Arrondi moderne
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

    // Floating Action Button - Golden Yellow avec icône blanche
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: level2,
      backgroundColor: goldenYellow,
      foregroundColor: Colors.white, // Icône blanche
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radiusLg)), // Arrondi au lieu de circulaire pur
      ),
    ),

    // Elevated Button - Golden Yellow moderne
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: goldenYellow,
        foregroundColor: Colors.white, // Texte blanc
        elevation: level1, // Légère élévation
        shadowColor: Colors.black12,
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
        backgroundColor: goldenYellow,
        foregroundColor: Colors.white,
        elevation: level1,
        shadowColor: Colors.black12,
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

    // Bottom Navigation - Style moderne
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: level1, // Légère élévation
      backgroundColor: Colors.white,
      selectedItemColor: goldenYellow, // Icône sélectionnée en Golden Yellow
      unselectedItemColor: slateColor, // Icônes non sélectionnées en Slate
      type: BottomNavigationBarType.fixed,
    ),

    // Divider
    dividerTheme: DividerThemeData(
      thickness: 1,
      color: Colors.grey[300],
    ),

    // Chip - Style moderne avec Antwarp Blue pour les badges
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[200],
      selectedColor: antwarpBlue, // Utilisation d'Antwarp Blue pour les chips sélectionnés
      labelStyle: TextStyle(fontSize: 12, color: slateColor),
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
      seedColor: goldenYellow,
      brightness: Brightness.dark,
      primary: goldenYellow,
      secondary: antwarpBlue,
      error: error,
      // Fond sombre avec Slate Color
      surface: slateColor,
      onSurface: const Color(0xFFE0E0E0), // Contraste WCAG AA
    ),

    // Typographie
    textTheme: _buildTextTheme(Brightness.dark),

    // AppBar - Fond Golden Yellow également en mode sombre
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: level0,
      scrolledUnderElevation: level1,
      backgroundColor: goldenYellow,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // Cards - Slate Color
    cardTheme: CardThemeData(
      elevation: level1,
      color: const Color(0xFF2A3740), // Version légèrement plus claire du Slate
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A3740),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: goldenYellow, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: md,
        vertical: md,
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: level3,
      backgroundColor: slateColor,
      selectedItemColor: goldenYellow,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // ============================================================================
  // TYPOGRAPHIE
  // ============================================================================

  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.light
        ? slateColor // Utilisation de Slate Color pour le texte en mode clair
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
