import 'package:excellent_educators_web/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

export 'package:excellent_educators_web/app/theme/app_colors.dart';

/// Compatibility layer providing aliases to [AppColors].
/// 
/// Note: To customize theme colors for the entire application,
/// edit [AppColors] in `lib/app/theme/app_colors.dart`.
abstract final class StudentColors {
  // ── Canvas & surfaces ──────────────────────────────────────────────
  static const canvas = AppColors.canvas;
  static const canvasSoft = AppColors.canvasSoft;
  static const surface = AppColors.surface;
  static const surfaceMuted = AppColors.surfaceMuted;
  static const surfaceWarm = AppColors.surfaceWarm;
  static const border = AppColors.border;
  static const borderHover = AppColors.borderHover;
  static const borderWarm = AppColors.border;

  // ── Primary Brand (Aliases) ─────────────────────────────────────────
  static const primary = AppColors.primary;
  static const forest = AppColors.primary;
  static const forestDark = AppColors.primaryDark;
  static const forestDeep = AppColors.primaryDeep;
  static const forestMid = AppColors.primaryMid;
  static const forestSoft = AppColors.primarySoft;
  static const forestLight = AppColors.primaryLight;
  static const forestTint = AppColors.primarySoft;
  static const forestBorder = AppColors.primaryBorder;

  // Backward-compatible aliases (older student widgets used "indigo").
  static const indigoPrimary = AppColors.primary;
  static const indigoDark = AppColors.primaryDark;
  static const indigoDeep = AppColors.primaryDeep;
  static const indigoLight = AppColors.primaryLight;
  static const indigoSoft = AppColors.primarySoft;

  // ── Success / live / completed ─────────────────────────────────────
  static const emeraldPrimary = AppColors.success;
  static const emeraldDark = AppColors.successDark;
  static const emeraldLight = AppColors.successLight;
  static const emeraldBorder = AppColors.successBorder;
  static const success = AppColors.success;
  static const successSoft = AppColors.successLight;
  static const successBorder = AppColors.successBorder;

  // ── Accent gold / amber ────────────────────────────────────────────
  static const gold = AppColors.accent;
  static const goldDark = AppColors.accentDark;
  static const goldSoft = AppColors.accentLight;
  static const amberPrimary = AppColors.accent;
  static const amberDark = AppColors.accentDark;
  static const amberDeep = AppColors.accentDeep;
  static const amberLight = AppColors.accentLight;
  static const amberBorder = AppColors.accentBorder;
  static const amberWarm = AppColors.accentWarm;

  // ── Info / media ───────────────────────────────────────────────────
  static const skyPrimary = AppColors.info;
  static const skyDark = AppColors.infoDark;
  static const skyLight = AppColors.infoLight;
  static const skyBorder = AppColors.infoBorder;

  // ── Journal / reflection ───────────────────────────────────────────
  static const slate = Color(0xFF4E7187);
  static const slateDark = Color(0xFF36586C);
  static const slateLight = Color(0xFFEEF4F6);
  static const slateBorder = Color(0xFFD3E1E6);
  static const violetPrimary = Color(0xFF8B5CF6);
  static const violetDark = Color(0xFF7C3AED);
  static const violetLight = Color(0xFFF5F3FF);
  static const violetBorder = Color(0xFFDDD6FE);

  // ── Attention / danger ─────────────────────────────────────────────
  static const danger = AppColors.danger;
  static const dangerSoft = AppColors.dangerLight;
  static const dangerBorder = AppColors.dangerBorder;
  static const bookmark = Color(0xFFE11D48);
  static const orangeSoft = Color(0xFFFFF7ED);
  static const orangeBorder = Color(0xFFFED7AA);
  static const orangeText = Color(0xFFC2410C);
  static const amberBrown = AppColors.accentDeep;
  static const amberInk = Color(0xFF78350F);
  static const amberWash = AppColors.accentSoft;
  static const live = AppColors.success;
  static const liveDeep = AppColors.successDark;
  static const liveSoft = Color(0xFF6EE7B7);
  static const goldBrand = AppColors.accent;
  static const goldBrandSoft = AppColors.accentLight;
  static const disabled = Color(0xFFD9D3C8);
  static const skeleton = Color(0xFFEDE7DB);
  static const hoverMint = Color(0xFFAFCABD);
  static const progressGold = AppColors.accent;

  // ── Typography ─────────────────────────────────────────────────────
  static const textPrimary = AppColors.textPrimary;
  static const textSecondary = AppColors.textSecondary;
  static const textMuted = AppColors.textMuted;
  static const textOnDark = AppColors.textOnPrimary;
  static const textOnGold = AppColors.textOnAccent;

  // ── Hero / dark panel gradients ────────────────────────────────────
  static const heroGradient = AppColors.heroGradient;
  static const panelGradient = AppColors.heroGradient;
  static const canvasGradient = AppColors.canvasGradient;
  static const motivationalGradient = AppColors.motivationalGradient;

  // ── Shadows ────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => AppColors.cardShadow;
  static List<BoxShadow> get cardShadowHover => AppColors.cardShadowHover;
  static List<BoxShadow> glow(Color color, {double opacity = 0.22, double blur = 20}) =>
      AppColors.glow(color, opacity: opacity, blur: blur);
}
