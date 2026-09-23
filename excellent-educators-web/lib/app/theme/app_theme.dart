import 'package:excellent_educators_web/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

export 'app_colors.dart';
export 'student_colors.dart';

/// Compatibility layer mapping legacy Brand tokens to [AppColors].
/// To customize theme colors for the whole application, edit [AppColors]
/// in `lib/app/theme/app_colors.dart`.
abstract final class Brand {
  static const navy = AppColors.primary;
  static const navyDeep = AppColors.primaryDark;
  static const gold = AppColors.accent;
  static const goldDark = AppColors.accentDark;
  static const cream = AppColors.canvas;
  static const creamDark = AppColors.canvasSoft;
  static const ink = AppColors.textPrimary;
  static const muted = AppColors.textSecondary;
}

abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.primaryDark,
      tertiary: AppColors.accentDark,
      onTertiary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
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
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Brand.navyDeep,
        useIndicator: false,
        indicatorColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: Brand.gold, size: 22),
        unselectedIconTheme: IconThemeData(color: Color(0xB3FFFFFF), size: 22),
        selectedLabelTextStyle: TextStyle(
          color: Brand.gold,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Color(0xB3FFFFFF),
          fontSize: 12,
        ),
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
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.1,
          ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        titleTextStyle: TextStyle(
          color: Brand.navy,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(color: Brand.muted, fontSize: 14),
        actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 16),
      ),
    );
  }

  static ThemeData compact(ThemeData base) {
    return base.copyWith(
      visualDensity: VisualDensity.compact,
      appBarTheme: base.appBarTheme.copyWith(
        toolbarHeight: 44,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: (base.filledButtonTheme.style ?? const ButtonStyle()).merge(
          FilledButton.styleFrom(
            minimumSize: const Size(72, 40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        titleTextStyle: const TextStyle(
          color: Brand.navy,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }
}
