import 'package:flutter/material.dart';
import 'colors.dart';

ThemeData buildRadioV2Theme() {
  const colorScheme = ColorScheme.dark(
    primary: RadioV2Colors.accent,
    onPrimary: Colors.white,
    secondary: RadioV2Colors.accent,
    onSecondary: Colors.white,
    surface: RadioV2Colors.surface,
    onSurface: RadioV2Colors.onSurface,
    error: RadioV2Colors.error,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: RadioV2Colors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: RadioV2Colors.background,
      foregroundColor: RadioV2Colors.onBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: RadioV2Colors.surface,
      indicatorColor: RadioV2Colors.accent.withAlpha(40),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: RadioV2Colors.accent);
        }
        return const IconThemeData(color: RadioV2Colors.onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: RadioV2Colors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }
        return const TextStyle(
          color: RadioV2Colors.onSurfaceVariant,
          fontSize: 12,
        );
      }),
    ),
    cardTheme: const CardThemeData(
      color: RadioV2Colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: RadioV2Colors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: RadioV2Colors.onSurfaceVariant),
      prefixIconColor: RadioV2Colors.onSurfaceVariant,
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      iconColor: RadioV2Colors.onSurfaceVariant,
    ),
    iconTheme: const IconThemeData(color: RadioV2Colors.onSurface),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: RadioV2Colors.accent,
    ),
    dividerTheme: const DividerThemeData(
      color: RadioV2Colors.divider,
      space: 1,
      thickness: 1,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: RadioV2Colors.onBackground,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: RadioV2Colors.onBackground,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: RadioV2Colors.onBackground,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: RadioV2Colors.onBackground, fontSize: 16),
      bodyMedium: TextStyle(color: RadioV2Colors.onSurface, fontSize: 14),
      bodySmall: TextStyle(color: RadioV2Colors.onSurfaceVariant, fontSize: 12),
      labelLarge: TextStyle(
        color: RadioV2Colors.accent,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
