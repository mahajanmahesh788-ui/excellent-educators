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
  static const slate = AppColors.slate;
  static const slateDark = AppColors.slateDark;
  static const slateLight = AppColors.slateLight;
  static const slateBorder = AppColors.slateBorder;
  static const violetPrimary = AppColors.violet;
  static const violetDark = AppColors.violetDark;
  static const violetLight = AppColors.violetLight;
  static const violetBorder = AppColors.violetBorder;

  // ── Attention / danger ─────────────────────────────────────────────
  static const danger = AppColors.danger;
  static const dangerSoft = AppColors.dangerLight;
  static const dangerBorder = AppColors.dangerBorder;
  static const bookmark = AppColors.bookmark;
  static const orangeSoft = AppColors.warningOrangeLight;
  static const orangeBorder = AppColors.warningOrangeSoft;
  static const orangeText = AppColors.warningOrange;
  static const amberBrown = AppColors.accentDeep;
  static const amberInk = AppColors.amberInk;
  static const amberWash = AppColors.accentSoft;
  static const live = AppColors.success;
  static const liveDeep = AppColors.successDark;
  static const liveSoft = AppColors.liveSoft;
  static const goldBrand = AppColors.accent;
  static const goldBrandSoft = AppColors.accentLight;
  static const disabled = AppColors.disabled;
  static const skeleton = AppColors.skeleton;
  static const hoverMint = AppColors.hoverMint;
  static const progressGold = AppColors.accent;
  static const parchment = AppColors.parchment;
  static const parchmentBorder = AppColors.parchmentBorder;
  static const parchmentSoft = AppColors.parchmentSoft;
  static const surfaceMist = AppColors.surfaceMist;

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
