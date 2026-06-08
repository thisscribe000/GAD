import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF004ac6);
  static const _primaryContainer = Color(0xFF2563eb);
  static const _onPrimary = Color(0xFFffffff);
  static const _onPrimaryContainer = Color(0xFFeeefff);
  static const _secondary = Color(0xFF505f76);
  static const _secondaryContainer = Color(0xFFd0e1fb);
  static const _onSecondaryContainer = Color(0xFF54647a);
  static const _surface = Color(0xFFfaf8ff);
  static const _onSurface = Color(0xFF191b23);
  static const _onSurfaceVariant = Color(0xFF434655);
  static const _outline = Color(0xFF737686);
  static const _outlineVariant = Color(0xFFc3c6d7);
  static const _error = Color(0xFFba1a1a);
  static const _errorContainer = Color(0xFFffdad6);
  static const _surfaceDim = Color(0xFFd9d9e5);
  static const _surfaceBright = Color(0xFFfaf8ff);
  static const _surfaceContainerLowest = Color(0xFFffffff);
  static const _surfaceContainerLow = Color(0xFFf3f3fe);
  static const _surfaceContainer = Color(0xFFededf9);
  static const _surfaceContainerHigh = Color(0xFFe7e7f3);
  static const _surfaceContainerHighest = Color(0xFFe1e2ed);
  static const _inverseSurface = Color(0xFF2e3039);
  static const _inverseOnSurface = Color(0xFFf0f0fb);
  static const _inversePrimary = Color(0xFFb4c5ff);
  static const _tertiaryContainer = Color(0xFFbc4800);

  static const _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _primary,
    onPrimary: _onPrimary,
    primaryContainer: _primaryContainer,
    onPrimaryContainer: _onPrimaryContainer,
    secondary: _secondary,
    onSecondary: _onPrimary,
    secondaryContainer: _secondaryContainer,
    onSecondaryContainer: _onSecondaryContainer,
    tertiary: _tertiaryContainer,
    onTertiary: _onPrimary,
    tertiaryContainer: _tertiaryContainer,
    onTertiaryContainer: _onPrimary,
    error: _error,
    onError: _onPrimary,
    errorContainer: _errorContainer,
    onErrorContainer: _error,
    surface: _surface,
    onSurface: _onSurface,
    surfaceContainerHighest: _surfaceContainerHighest,
    onSurfaceVariant: _onSurfaceVariant,
    outline: _outline,
    outlineVariant: _outlineVariant,
    inverseSurface: _inverseSurface,
    onInverseSurface: _inverseOnSurface,
    inversePrimary: _inversePrimary,
    surfaceDim: _surfaceDim,
    surfaceBright: _surfaceBright,
    surfaceContainerLowest: _surfaceContainerLowest,
    surfaceContainerLow: _surfaceContainerLow,
    surfaceContainer: _surfaceContainer,
    surfaceContainerHigh: _surfaceContainerHigh,
  );

  static const _regular = FontWeight.w400;
  static const _semiBold = FontWeight.w600;
  static const _bold = FontWeight.w700;

  static const _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 24,
      fontWeight: _bold,
      letterSpacing: -0.02,
      height: 32 / 24,
    ),
    displayMedium: TextStyle(
      fontSize: 24,
      fontWeight: _bold,
      letterSpacing: -0.02,
      height: 32 / 24,
    ),
    headlineLarge: TextStyle(
      fontSize: 20,
      fontWeight: _bold,
      letterSpacing: -0.01,
      height: 28 / 20,
    ),
    headlineMedium: TextStyle(
      fontSize: 16,
      fontWeight: _bold,
      height: 24 / 16,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: _semiBold,
      height: 20 / 14,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: _regular,
      height: 24 / 16,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: _regular,
      height: 20 / 14,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: _semiBold,
      letterSpacing: 0.01,
      height: 16 / 12,
    ),
  );

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: _surface,
      textTheme: _textTheme,
      dividerTheme: const DividerThemeData(
        color: _outlineVariant,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _surface,
        foregroundColor: _onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _primary,
          height: 24 / 16,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: _surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _outlineVariant, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide.none,
        ),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _onSurface,
        ),
        backgroundColor: _surfaceContainerHighest,
        selectedColor: _primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryContainer,
          foregroundColor: _onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 24 / 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _primary),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 16 / 12,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surface,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primary,
        unselectedItemColor: _secondary,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 16 / 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 16 / 12,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _error),
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _onSurfaceVariant,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryContainer,
        foregroundColor: _onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: _surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
