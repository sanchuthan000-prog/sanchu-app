import 'package:flutter/material.dart';

class AppTheme {
  // Dark/Navy Gaming Palette
  static const Color background = Color(0xFF090D1A);
  static const Color surface = Color(0xFF10172A);
  static const Color surfaceLight = Color(0xFF17223C);
  static const Color cardBg = Color(0xFF131B2E);
  static const Color cardBorder = Color(0xFF223052);

  // Accents as specified
  static const Color primaryBlue = Color(0xFF2563EB); // #2563EB for primary actions
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color emeraldGreen = Color(0xFF10B981); // #10B981 for Income & Profits
  static const Color roseRed = Color(0xFFEF4444); // #EF4444 for Expenses & Losses
  static const Color amberWarning = Color(0xFFF59E0B); // #F59E0B for Dues/Warnings

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color dividerColor = Color(0xFF1E293B);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryBlue,
      cardColor: cardBg,
      dividerColor: dividerColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: neonCyan),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: neonCyan,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: emeraldGreen,
        surface: surface,
        error: roseRed,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
    );
  }
}
