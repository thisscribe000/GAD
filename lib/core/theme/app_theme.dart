import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: const Color(0xFF2563EB), // premium blue
    );

    final cs = base.colorScheme;

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: TextStyle(color: cs.onSurface),
        backgroundColor: cs.surfaceContainerHighest,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFF0F172A),
        displayColor: const Color(0xFF0F172A),
      ),
    );
  }

  // ✅ Keep darkTheme for later (unused for now)
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xFF2563EB),
    );
  }
}
