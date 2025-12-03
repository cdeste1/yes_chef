import 'package:flutter/material.dart';

//  static const Color flameOrange = Color(0xFFF58220);
//  static const Color background = Color(0xFF121212);
//  static const Color background = Color(0xFF141413)
//  static const Color surface = Color(0xFF1E1E1E);
//  static const Color textPrimary = Color(0xFFFFFFFF);
//  static const Color textSecondary = Color(0xFFC8C8C8);
//  static const Color accentGold = Color(0xFFFFD580);
//  static const Color successGreen = Color(0xFF7EC850);
//  static const Color alertRed = Color(0xFFE54B4B);


class YesChefTheme {
  static ThemeData buildTheme() {
    const primary = Color(0xFFF58220); // your orange flame color
    const surface = Color(0xFF1E1E1E); // dark card / background surface
    const background = Color(0xFF121212); // full app background

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      useMaterial3: true,

      // --- AppBar / Header ---
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // --- Cards / Surfaces ---
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // --- Text ---
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),

      // --- Buttons ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // --- TextFields / SearchBars ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white, // white background for search bar
        hintStyle: TextStyle(color: Colors.grey[600]),
        labelStyle: TextStyle(color: Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIconColor: Colors.grey[700],
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),

      // --- Icons ---
      iconTheme: const IconThemeData(color: Colors.white70),

      // --- Floating Action Buttons ---
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),

      // --- Color scheme base ---
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primary,
        surface: surface,
      ),
    );
  }
}
