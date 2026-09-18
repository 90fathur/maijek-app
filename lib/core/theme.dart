import 'package:flutter/material.dart';

class AppTheme {
  // Official Maijek 3-Color Identity Scheme
  // 1. Midnight Deep Navy (Primary structure, header, app bar)
  static const Color primaryNavy = Color(0xFF0E1B38);
  static const Color navyDark = Color(0xFF080F20);
  static const Color navyLight = Color(0xFF162B56);
  static const Color primaryBlue = primaryNavy; // Backwards compatible alias
  static const Color secondaryBlue = Color(0xFF162B56);

  // 2. Vibrant Golden Amber / Radiant Gold (Logo accent, arrow, i/j dots, top-up, highlights)
  static const Color accentGold = Color(0xFFFDB813);
  static const Color goldDark = Color(0xFFE5A000);
  static const Color goldLight = Color(0xFFFFF8E7);
  static const Color accentBlue = accentGold; // Backwards compatible alias

  // 3. Crisp White & Modern Neutrals
  static const Color surfaceWhite = Colors.white;
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textMain = Color(0xFF0F172A); // Deep slate
  static const Color textMuted = Color(0xFF64748B); // Slate muted gray

  // Status Indicators
  static const Color warning = Color(0xFFDD6B20); // Warm orange
  static const Color error = Color(0xFFE53E3E); // Soft red
  static const Color success = Color(0xFF38A169); // Soft green

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryNavy,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryNavy,
        secondary: accentGold,
        surface: cardColor,
        error: error,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textMain,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: textMain),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 10,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryNavy, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted),
      ),
    );
  }
}
