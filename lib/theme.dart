import 'package:flutter/material.dart';

/// Builds the app theme from the accent colour picked in Settings.
ThemeData buildTheme(Color accent, Brightness brightness) {
  final bool dark = brightness == Brightness.dark;
  final ColorScheme scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? scheme.surface : const Color(0xFFF4F6FA),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? scheme.surfaceContainerHigh : scheme.primary,
      foregroundColor: dark ? scheme.onSurface : scheme.onPrimary,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: dark ? scheme.onSurface : scheme.onPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: dark ? scheme.surfaceContainer : Colors.white,
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
