import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dark Palette
  static const Color darkBackground = Color(0xFF0A0F1D);
  static const Color darkSurfaceLow = Color(0xFF121829);
  static const Color darkSurfaceMedium = Color(0xFF1A2238);
  static const Color darkSurfaceHigh = Color(0xFF232D48);
  static const Color darkBorder = Color(0xFF242E47);
  static const Color darkPrimary = Color(0xFF1AD1D1);
  static const Color darkSecondary = Color(0xFF00F5D4);
  static const Color darkTextMain = Colors.white;
  static const Color darkTextMuted = Color(0xFF8A99AD);

  // Light Palette
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurfaceLow = Color(0xFFFFFFFF);
  static const Color lightSurfaceMedium = Color(0xFFEDF1F6);
  static const Color lightSurfaceHigh = Color(0xFFE2E7EF);
  static const Color lightBorder = Color(0xFFD4DBE6);
  static const Color lightPrimary = Color(0xFF0E8A8A);
  static const Color lightSecondary = Color(0xFF00B49D);
  static const Color lightTextMain = Color(0xFF111726);
  static const Color lightTextMuted = Color(0xFF6C7C93);

  // Legacy compatibility references
  static const Color background = darkBackground;
  static const Color surfaceLow = darkSurfaceLow;
  static const Color surfaceMedium = darkSurfaceMedium;
  static const Color surfaceHigh = darkSurfaceHigh;
  static const Color primary = darkPrimary;
  static const Color secondary = darkSecondary;
  static const Color textMain = darkTextMain;
  static const Color textMuted = darkTextMuted;
  static const Color borderSide = darkBorder;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: darkPrimary,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkSurfaceLow,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: darkTextMain,
        outline: darkBorder,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkTextMain,
          letterSpacing: -0.5,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkTextMain,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          color: darkTextMain,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 12,
          color: darkTextMuted,
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: darkPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceLow,
        selectedItemColor: darkPrimary,
        unselectedItemColor: darkTextMuted,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: lightPrimary,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightSurfaceLow,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextMain,
        outline: lightBorder,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: lightTextMain,
          letterSpacing: -0.5,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: lightTextMain,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          color: lightTextMain,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 12,
          color: lightTextMuted,
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: lightPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurfaceLow,
        selectedItemColor: lightPrimary,
        unselectedItemColor: lightTextMuted,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

