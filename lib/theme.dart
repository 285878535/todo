import 'package:flutter/material.dart';

enum AppTheme { light, dark, cute }

class BrandColors {
  static const primary = Color(0xFF5B8CFF);
  static const secondary = Color(0xFF51E1A7);
  static const tertiary = Color(0xFFFFA07A);
  static const surface = Color(0xFFF7F8FC);
  static const textStrong = Color(0xFF1A1F36);
}

class CuteColors {
  static const primary = Color(0xFFFFB6C1); // Light pink
  static const secondary = Color(0xFF98FB98); // Pale green
  static const tertiary = Color(0xFF87CEFA); // Light sky blue
  static const surface = Color(0xFFFFF0F5); // Lavender blush
  static const accent = Color(0xFFFFD700); // Gold
  static const textStrong = Color(0xFF8B4513); // Saddle brown
  static const textMedium = Color(0xFF696969); // Dim gray
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
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      centerTitle: true,
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
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      centerTitle: true,
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
      backgroundColor: Colors.transparent,
      foregroundColor: CuteColors.textStrong,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: CuteColors.textStrong,
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

ThemeData getThemeData(AppTheme theme) {
  switch (theme) {
    case AppTheme.light:
      return buildLightTheme();
    case AppTheme.dark:
      return buildDarkTheme();
    case AppTheme.cute:
      return buildCuteTheme();
  }
}
