import 'package:flutter/material.dart';

class AppTheme {
  // Stitch Design System Colors
  static const Color _background = Color(0xFF0E1513); // Deep dark slate
  static const Color _surface = Color(0xFF1A211F); // Slightly lighter slate
  static const Color _primary = Color(0xFF57F1DB); // Tech Teal
  static const Color _primaryContainer = Color(0xFF2DD4BF);
  static const Color _secondary = Color(0xFF7BD0FF); // Sky Blue
  static const Color _error = Color(0xFFFFB4AB);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _background,
        colorScheme: const ColorScheme.dark(
          primary: _primary,
          primaryContainer: _primaryContainer,
          secondary: _secondary,
          surface: _surface,
          error: _error,
          onPrimary: Color(0xFF003731),
          onSecondary: Color(0xFF00354A),
          onSurface: Color(0xFFDDE4E1),
        ),
        cardTheme: CardThemeData(
          color: Colors.transparent, // Cards will handle their own glassmorphism
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryContainer,
            foregroundColor: const Color(0xFF0E1513),
            minimumSize: const Size(double.infinity, 56), // Minimum touch target
            shape: const StadiumBorder(), // Pill shape
            elevation: 8,
            shadowColor: _primaryContainer.withValues(alpha: 0.3), // AI Glow
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _secondary,
            side: const BorderSide(color: _secondary, width: 1.5),
            minimumSize: const Size(double.infinity, 56),
            shape: const StadiumBorder(), // Pill shape
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surface,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)), // Pill shape
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)),
            borderSide: BorderSide(color: _primary, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)),
            borderSide: BorderSide(color: _error, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          labelStyle: const TextStyle(color: Color(0xFF859490)), // Outline color
          prefixIconColor: const Color(0xFF859490),
          suffixIconColor: const Color(0xFF859490),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Color(0xFFDDE4E1),
          ),
          iconTheme: IconThemeData(color: Color(0xFFDDE4E1)),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFFDDE4E1),
          ),
          headlineSmall: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFFDDE4E1),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFDDE4E1),
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            color: Color(0xFFBACAC5),
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Color(0xFF859490),
            height: 1.6,
          ),
        ),
      );
}