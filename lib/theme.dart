import 'package:flutter/material.dart';

enum AppTheme { auto, light, dark, cute, fresh, liquidGlass }

class BrandColors {
  static const primary = Color(0xFF5B8CFF);
  static const secondary = Color(0xFF51E1A7);
  static const tertiary = Color(0xFFFFA07A);
  static const surface = Color(0xFFF7F8FC);
  static const textStrong = Color(0xFF1A1F36);
}

class CuteColors {
  static const primary = Color(0xFFFFB6C1); // Light pink
  static const secondary = Color(0xFFA8D8A8); // Softer muted green (更柔和的绿色)
  static const tertiary = Color(0xFF87CEFA); // Light sky blue
  static const surface = Color(0xFFFFF0F5); // Lavender blush
  static const accent = Color(0xFFFFD700); // Gold
  static const textStrong = Color(0xFF8B4513); // Saddle brown
  static const textMedium = Color(0xFF696969); // Dim gray
}

class FreshColors {
  static const primary = Color(0xFF4CAF50); // Fresh green
  static const secondary = Color(0xFF81C784); // Light green
  static const tertiary = Color(0xFFA5D6A7); // Lighter green
  static const surface = Color(0xFFF1F8F4); // Very light green background
  static const accent = Color(0xFF66BB6A); // Medium green
  static const textStrong = Color(0xFF1B5E20); // Dark green
  static const textMedium = Color(0xFF388E3C); // Medium dark green
}

ThemeData buildLightTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: BrandColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: BrandColors.primary,
        secondary: BrandColors.secondary,
        surface: BrandColors.surface,
        onSurface: BrandColors.textStrong,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: scheme.surface.withValues(alpha: 0.95),
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        letterSpacing: -0.5,
      ),
    ),
    scaffoldBackgroundColor: scheme.surface,
    textTheme: Typography.blackMountainView.copyWith(
      displayLarge: const TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      ),
      titleMedium: const TextStyle(fontWeight: FontWeight.w600),
      bodyMedium: const TextStyle(height: 1.4),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      iconColor: scheme.primary,
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: BrandColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: BrandColors.primary.withValues(alpha: 0.9),
        secondary: BrandColors.secondary.withValues(alpha: 0.9),
        surface: const Color(0xFF1A1F36),
        onSurface: const Color(0xFFF7F8FC),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: scheme.surface.withValues(alpha: 0.95),
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        letterSpacing: -0.5,
      ),
    ),
    scaffoldBackgroundColor: scheme.surface,
    textTheme: Typography.whiteMountainView.copyWith(
      displayLarge: const TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      ),
      titleMedium: const TextStyle(fontWeight: FontWeight.w600),
      bodyMedium: const TextStyle(height: 1.4),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: scheme.surface.withValues(alpha: 0.8),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface.withValues(alpha: 0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      iconColor: scheme.primary,
    ),
  );
}

ThemeData buildCuteTheme() {
  final scheme = ColorScheme.light(
    primary: CuteColors.primary,
    secondary: CuteColors.secondary,
    tertiary: CuteColors.tertiary,
    surface: CuteColors.surface,
    onSurface: CuteColors.textStrong,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: CuteColors.surface.withValues(alpha: 0.95),
      foregroundColor: CuteColors.textStrong,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: CuteColors.textStrong,
        letterSpacing: -0.5,
      ),
    ),
    scaffoldBackgroundColor: CuteColors.surface,
    textTheme: Typography.blackMountainView.copyWith(
      displayLarge: const TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: CuteColors.textStrong,
        fontFamily: 'ComicSansMS',
      ),
      titleMedium: const TextStyle(
        fontWeight: FontWeight.w600,
        color: CuteColors.textStrong,
      ),
      bodyMedium: const TextStyle(height: 1.4, color: CuteColors.textMedium),
      bodySmall: const TextStyle(color: CuteColors.textMedium),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: CuteColors.primary.withValues(alpha: 0.2)),
      ),
      color: Colors.white,
      shadowColor: CuteColors.primary.withValues(alpha: 0.1),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CuteColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
        shadowColor: CuteColors.primary.withValues(alpha: 0.3),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: CuteColors.primary.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: CuteColors.primary.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: CuteColors.primary, width: 2),
      ),
      labelStyle: const TextStyle(color: CuteColors.textMedium),
      hintStyle: TextStyle(color: CuteColors.textMedium.withValues(alpha: 0.6)),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      iconColor: CuteColors.primary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: CuteColors.accent,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: CuteColors.secondary.withValues(alpha: 0.2),
      selectedColor: CuteColors.secondary,
      labelStyle: const TextStyle(color: CuteColors.textStrong),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

ThemeData buildFreshTheme() {
  final scheme = ColorScheme.light(
    primary: FreshColors.primary,
    secondary: FreshColors.secondary,
    tertiary: FreshColors.tertiary,
    surface: FreshColors.surface,
    onSurface: FreshColors.textStrong,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: FreshColors.surface.withValues(alpha: 0.95),
      foregroundColor: FreshColors.textStrong,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 24,
        color: FreshColors.textStrong,
        letterSpacing: -0.5,
      ),
    ),
    scaffoldBackgroundColor: FreshColors.surface,
    textTheme: Typography.blackMountainView.copyWith(
      displayLarge: const TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: FreshColors.textStrong,
      ),
      titleMedium: const TextStyle(
        fontWeight: FontWeight.w600,
        color: FreshColors.textStrong,
      ),
      bodyMedium: const TextStyle(height: 1.4, color: FreshColors.textMedium),
      bodySmall: const TextStyle(color: FreshColors.textMedium),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: FreshColors.secondary.withValues(alpha: 0.2)),
      ),
      color: Colors.white,
      shadowColor: FreshColors.primary.withValues(alpha: 0.08),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FreshColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 1,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: FreshColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: FreshColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: FreshColors.primary, width: 2),
      ),
      labelStyle: const TextStyle(color: FreshColors.textMedium),
      hintStyle: TextStyle(color: FreshColors.textMedium.withValues(alpha: 0.6)),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      iconColor: FreshColors.primary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: FreshColors.accent,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

ThemeData buildLiquidGlassTheme() {
  final scheme = ColorScheme.light(
    primary: const Color(0xFF007AFF), // iOS blue
    secondary: const Color(0xFF5856D6), // iOS purple
    tertiary: const Color(0xFFFF2D55), // iOS pink
    surface: const Color(0xFFF2F2F7), // iOS background
    onSurface: const Color(0xFF000000),
    surfaceContainerHighest: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
  );
  
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white.withValues(alpha: 0.3),
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: Color(0xFF000000),
      ),
    ),
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: Typography.blackCupertino.copyWith(
      displayLarge: const TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      titleMedium: const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      bodyMedium: const TextStyle(
        height: 1.4,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withValues(alpha: 0.6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      iconColor: scheme.primary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      backgroundColor: scheme.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      elevation: 0,
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

ThemeData getThemeData(AppTheme theme) {
  switch (theme) {
    case AppTheme.auto:
    case AppTheme.light:
      return buildLightTheme();
    case AppTheme.dark:
      return buildDarkTheme();
    case AppTheme.cute:
      return buildCuteTheme();
    case AppTheme.fresh:
      return buildFreshTheme();
    case AppTheme.liquidGlass:
      return buildLiquidGlassTheme();
  }
}
