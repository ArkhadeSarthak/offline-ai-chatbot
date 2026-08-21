import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Deep dark palette
  static const Color darkBackground = Color(0xFF090D16);
  static const Color darkSurfaceLow = Color(0xFF111726);
  static const Color darkSurfaceMedium = Color(0xFF182035);
  static const Color darkSurfaceHigh = Color(0xFF222C46);
  static const Color darkBorder = Color(0xFF23304D);
  static const Color darkPrimary = Color(0xFF00E5FF);
  static const Color darkSecondary = Color(0xFF00F5D4);
  static const Color darkAccentPurple = Color(0xFF7C4DFF);
  static const Color darkTextMain = Color(0xFFF1F5F9);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Light palette
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurfaceLow = Color(0xFFFFFFFF);
  static const Color lightSurfaceMedium = Color(0xFFF1F5F9);
  static const Color lightSurfaceHigh = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0xFFCBD5E1);
  static const Color lightPrimary = Color(0xFF0284C7);
  static const Color lightSecondary = Color(0xFF0D9488);
  static const Color lightAccentPurple = Color(0xFF6D28D9);
  static const Color lightTextMain = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Status Colors
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusError = Color(0xFFEF4444);
  static const Color statusInfo = Color(0xFF3B82F6);

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
        error: statusError,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkTextMain,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkTextMain,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkTextMain,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: darkTextMain,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          color: darkTextMain,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          color: darkTextMuted,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 11,
          color: darkTextMuted,
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: darkPrimary,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: darkTextMuted,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceLow,
        selectedItemColor: darkPrimary,
        unselectedItemColor: darkTextMuted,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceLow,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: darkTextMain,
        ),
        iconTheme: const IconThemeData(color: darkTextMain),
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
        error: statusError,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: lightTextMain,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: lightTextMain,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: lightTextMain,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: lightTextMain,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          color: lightTextMain,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          color: lightTextMuted,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 11,
          color: lightTextMuted,
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: lightPrimary,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: lightTextMuted,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurfaceLow,
        selectedItemColor: lightPrimary,
        unselectedItemColor: lightTextMuted,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurfaceLow,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: lightTextMain,
        ),
        iconTheme: const IconThemeData(color: lightTextMain),
      ),
    );
  }
}
