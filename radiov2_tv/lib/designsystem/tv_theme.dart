import 'package:flutter/material.dart';
import 'tv_colors.dart';

ThemeData buildTvTheme() {
  const colorScheme = ColorScheme.dark(
    primary: TvColors.accent,
    onPrimary: Colors.white,
    secondary: TvColors.accent,
    onSecondary: Colors.white,
    surface: TvColors.surface,
    onSurface: TvColors.onSurface,
    error: TvColors.error,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: TvColors.background,
    focusColor: TvColors.focusOverlay,
    hoverColor: TvColors.focusOverlay,
    appBarTheme: const AppBarTheme(
      backgroundColor: TvColors.background,
      foregroundColor: TvColors.onBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: TvColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    iconTheme: const IconThemeData(color: TvColors.onSurface),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TvColors.accent,
    ),
    dividerTheme: const DividerThemeData(
      color: TvColors.divider,
      space: 1,
      thickness: 1,
    ),
    // TV-scaled typography
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: TvColors.onBackground,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: TvColors.onBackground,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: TvColors.onBackground,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: TvColors.onBackground,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: TvColors.onBackground, fontSize: 20),
      bodyMedium: TextStyle(color: TvColors.onSurface, fontSize: 18),
      bodySmall: TextStyle(color: TvColors.onSurfaceVariant, fontSize: 16),
      labelLarge: TextStyle(
        color: TvColors.accent,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
