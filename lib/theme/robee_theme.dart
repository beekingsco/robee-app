import 'package:flutter/material.dart';

/// RoBee Design System — Sprint 4
/// Tesla aesthetic: flat dark panels, single amber accent, surgical.
class RoBeeTheme {
  RoBeeTheme._();

  // ── Core Colors ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0C0A09);
  static const Color panel = Color(0xFF141210);       // card backgrounds
  static const Color border = Color(0x1AFFFFFF);      // white/10
  static const Color amber = Color(0xFFD98639);
  static const Color amberDark = Color(0xFFB8702B);

  // ── Text opacity tokens ────────────────────────────────────────────────────
  // Kept as-is — used throughout for text/icon alpha values
  static const Color glassWhite5 = Color(0x0DFFFFFF);
  static const Color glassWhite10 = Color(0x1AFFFFFF);
  static const Color glassWhite20 = Color(0x33FFFFFF);
  static const Color glassWhite60 = Color(0x99FFFFFF);

  // ── Status Colors ──────────────────────────────────────────────────────────
  static const Color alertRed = Color(0x1AEF4444);
  static const Color alertRedBorder = Color(0x33EF4444);
  static const Color healthGreen = Color(0xFF4ADE80);
  static const Color healthYellow = Color(0xFFFACC15);
  static const Color healthRed = Color(0xFFEF4444);
  static const Color signalPurple = Color(0xFFA855F7);

  // ── Active state: amber glow (ONLY for active/scanning) ───────────────────
  static List<BoxShadow> get amberGlow => [
        BoxShadow(
          color: amber.withOpacity(0.35),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get amberGlowSubtle => [
        BoxShadow(
          color: amber.withOpacity(0.18),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ];

  // ── Text Styles ────────────────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    color: Colors.white,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Colors.white,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: Colors.white,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: Colors.white,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: glassWhite60,
  );

  // Section labels: ALL CAPS, letterSpacing 1.5
  static const TextStyle labelLarge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: glassWhite60,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: glassWhite60,
  );

  // Monospace for ALL telemetry values
  static const TextStyle monoLarge = TextStyle(
    fontSize: 14,
    fontFamily: 'monospace',
    fontWeight: FontWeight.w600,
    color: amber,
    letterSpacing: 0.5,
  );

  static const TextStyle monoSmall = TextStyle(
    fontSize: 11,
    fontFamily: 'monospace',
    fontWeight: FontWeight.w500,
    color: glassWhite60,
    letterSpacing: 0.5,
  );

  // ── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: amber,
        onPrimary: background,
        secondary: amberDark,
        onSecondary: Colors.white,
        surface: panel,
        onSurface: Colors.white,
        error: healthRed,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        labelLarge: labelLarge,
        labelSmall: labelSmall,
      ),
      iconTheme: const IconThemeData(color: glassWhite60),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: amber, width: 1.5),
        ),
        labelStyle: const TextStyle(color: glassWhite60),
        hintStyle: const TextStyle(color: glassWhite60),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: panel,
        selectedColor: amber.withOpacity(0.15),
        labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: panel,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: amber,
          foregroundColor: background,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(0, 48),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: amber,
          foregroundColor: background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(0, 48),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return amber;
          return glassWhite60;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return amber.withOpacity(0.3);
          return border;
        }),
      ),
    );
  }

  // ── Health color helper ────────────────────────────────────────────────────
  static Color healthColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
      case 'good':
        return healthGreen;
      case 'warning':
      case 'moderate':
        return healthYellow;
      case 'critical':
      case 'poor':
        return healthRed;
      default:
        return glassWhite60;
    }
  }
}
