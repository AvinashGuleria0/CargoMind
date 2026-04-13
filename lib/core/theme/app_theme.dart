import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core Colors
  static const Color slate900 = Color(0xFF0F172A); 
  static const Color slate800 = Color(0xFF1E293B); 
  static const Color slate700 = Color(0xFF334155); 
  
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50  = Color(0xFFF8FAFC);
  static const Color slate200 = Color(0xFFE2E8F0);

  // Status Colors
  static const Color routeGreen = Color(0xFF10B981); // Emerald (softer, professional)
  static const Color routeRed = Color(0xFFEF4444);   // Rose

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();
    final monoFontFamily = GoogleFonts.jetBrainsMono().fontFamily;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: slate50,
      colorScheme: const ColorScheme.light(
        primary: routeGreen,
        secondary: routeRed,
        surface: Colors.white,
        background: slate50,
        onSurface: slate900,
        outline: slate200,
      ),
      dividerColor: slate200,
      cardColor: Colors.white,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: slate900),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: slate900),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: slate900),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: slate700),
      ).apply(
        bodyColor: slate900,
        displayColor: slate900,
      ),
      extensions: [
        ThemeStatsExtension(monoFontFamily: monoFontFamily!),
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: slate900),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();
    final monoFontFamily = GoogleFonts.jetBrainsMono().fontFamily;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: slate900,
      colorScheme: const ColorScheme.dark(
        primary: routeGreen,
        secondary: routeRed,
        surface: slate800,
        background: slate900,
        onSurface: slate50,
        outline: slate700,
      ),
      dividerColor: slate700,
      cardColor: slate800,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: slate50),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: slate50),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: slate50),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: slate200),
      ).apply(
        bodyColor: slate50,
        displayColor: slate50,
      ),
      extensions: [
        ThemeStatsExtension(monoFontFamily: monoFontFamily!),
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: slate900,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}

class ThemeStatsExtension extends ThemeExtension<ThemeStatsExtension> {
  final String monoFontFamily;

  ThemeStatsExtension({required this.monoFontFamily});

  @override
  ThemeExtension<ThemeStatsExtension> copyWith({String? monoFontFamily}) {
    return ThemeStatsExtension(
      monoFontFamily: monoFontFamily ?? this.monoFontFamily,
    );
  }

  @override
  ThemeExtension<ThemeStatsExtension> lerp(ThemeExtension<ThemeStatsExtension>? other, double t) {
    if (other is! ThemeStatsExtension) return this;
    return ThemeStatsExtension(
      monoFontFamily: other.monoFontFamily,
    );
  }
}
