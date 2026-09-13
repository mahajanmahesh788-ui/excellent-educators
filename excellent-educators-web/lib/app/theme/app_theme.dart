import 'package:flutter/material.dart';

abstract final class Brand {
  static const navy = Color(0xFF0E2744);
  static const navyDeep = Color(0xFF091C32);
  static const gold = Color(0xFFC6A15B);
  static const goldDark = Color(0xFF9C7A36);
  static const cream = Color(0xFFF7F1E6);
  static const creamDark = Color(0xFFE8DCC8);
  static const ink = Color(0xFF1C2430);
  static const muted = Color(0xFF5C6570);
}

abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Brand.navy,
      onPrimary: Colors.white,
      secondary: Brand.gold,
      onSecondary: Brand.navyDeep,
      tertiary: Brand.goldDark,
      onTertiary: Colors.white,
      error: Color(0xFFB42318),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Brand.ink,
      onSurfaceVariant: Brand.muted,
      outline: Color(0xFFD7CDBB),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Brand.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: Brand.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 48,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Brand.navyDeep,
        useIndicator: false,
        indicatorColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: Brand.gold, size: 22),
        unselectedIconTheme: IconThemeData(color: Color(0xB3FFFFFF), size: 22),
        selectedLabelTextStyle: TextStyle(color: Brand.gold, fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelTextStyle: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Brand.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD7CDBB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD7CDBB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Brand.gold, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Brand.navy,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Brand.navy,
          minimumSize: const Size(88, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          side: const BorderSide(color: Color(0xFFC9D4E3)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Brand.navy,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Brand.navy,
        foregroundColor: Colors.white,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        titleTextStyle: TextStyle(
          color: Brand.navy,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: Brand.muted,
          fontSize: 14,
        ),
        actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 16),
      ),
    );
  }
}
