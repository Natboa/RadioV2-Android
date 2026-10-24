import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';

ThemeData buildRadioV2Theme({Brightness brightness = Brightness.dark}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
          seedColor: RadioV2Colors.seed,
          brightness: brightness,
          dynamicSchemeVariant: DynamicSchemeVariant.vibrant)
      .copyWith(
    surface: dark ? const Color(0xFF121215) : const Color(0xFFFAF8F9),
    surfaceContainerLowest: dark ? const Color(0xFF0D0D10) : Colors.white,
    surfaceContainerLow:
        dark ? const Color(0xFF1B1B1F) : const Color(0xFFF3F0F2),
    surfaceContainer: dark ? const Color(0xFF222226) : const Color(0xFFEDE9EC),
    surfaceContainerHigh:
        dark ? const Color(0xFF2B2B30) : const Color(0xFFE7E3E6),
    surfaceContainerHighest:
        dark ? const Color(0xFF343439) : const Color(0xFFE0DCDF),
    onSurface: dark ? const Color(0xFFF5F1F4) : const Color(0xFF211D22),
    onSurfaceVariant: dark ? const Color(0xFFBEB7BF) : const Color(0xFF635B65),
    inverseSurface: dark ? const Color(0xFFE9E5E8) : const Color(0xFF302C31),
    onInverseSurface: dark ? const Color(0xFF302C31) : const Color(0xFFF5F1F4),
    outlineVariant: dark ? const Color(0xFF39363D) : const Color(0xFFD8D1D9),
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final text = base.textTheme.copyWith(
    headlineLarge: base.textTheme.headlineLarge
        ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.1),
    headlineMedium: base.textTheme.headlineMedium
        ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -.7),
    titleLarge: base.textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -.4),
    titleMedium:
        base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall:
        base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    bodySmall:
        base.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
  );
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 24,
      toolbarHeight: 72,
      titleTextStyle: text.headlineMedium,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: scheme.surface,
        systemNavigationBarDividerColor: scheme.surface,
        systemNavigationBarIconBrightness:
            dark ? Brightness.light : Brightness.dark,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: scheme.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant)),
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          text.labelMedium?.copyWith(
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant)),
    ),
    navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.5)),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
    ),
    listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 4)),
    iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48))),
    dividerTheme:
        DividerThemeData(color: scheme.outlineVariant, thickness: .5, space: 1),
    cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        surfaceTintColor: Colors.transparent),
    snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating),
    progressIndicatorTheme:
        ProgressIndicatorThemeData(color: scheme.primary, strokeWidth: 2.5),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder()
    }),
  );
}
