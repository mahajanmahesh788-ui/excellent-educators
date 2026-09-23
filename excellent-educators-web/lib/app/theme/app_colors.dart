import 'package:flutter/material.dart';

// =============================================================================
// 🎨 EXCELLENT EDUCATORS — CENTRAL THEME CONFIGURATION
//
// This is the SINGLE SOURCE OF TRUTH for the entire application's theme colors.
// You can customize the primary brand color, accent color, background,
// gradients, and cards here to restyle the WHOLE application.
// =============================================================================

abstract final class AppColors {
  // ── 1. Primary Brand Palette (Deep Emerald & Midnight Ocean) ────────────────
  // Deep Oceanic Emerald and Midnight Navy as inspired by the mentor showcase.
  static const primary = Color(0xFF03162B);      // Deep Oceanic Emerald
  static const primaryDark = Color(0xFF091C32);  // Midnight Navy Ocean
  static const primaryDeep = Color(0xFF071424);  // Midnight Slate Ink
  static const primaryMid = Color(0xFF15533F);   // Deep Forest Emerald Teal
  static const primaryLight = Color(0xFFDDF3E8); // Soft Mint / Sage Tint
  static const primarySoft = Color(0xFFE8F7F0);  // Subtle Mint Wash
  static const primaryBorder = Color(0xFFA7F3D0);// Mint / Seafoam Border

  // ── 2. Accent / Action Palette (Golden Amber & Sunlight) ───────────────────
  // Warm golden amber for category overlines, streak stars, and radiant sparks.
  static const accent = Color(0xFFE5A024);       // Warm Golden Amber (Brand.gold)
  static const accentDark = Color(0xFFD97706);   // Deep Warm Amber
  static const accentDeep = Color(0xFF92400E);   // Amber Ink / Warning Text
  static const accentLight = Color(0xFFFEF3C7);  // Soft Buttercream Amber
  static const accentSoft = Color(0xFFFFFBEB);   // Gentle Amber Wash
  static const accentBorder = Color(0xFFFDE68A); // Amber Border
  static const accentWarm = Color(0xFFFBBF24);   // Radiant Golden Highlight

  // ── 2.5 Mint & Seafoam Hero Accents ────────────────────────────────────────
  // Text and ambient highlights on dark hero surfaces.
  static const mintText = Color(0xFFBDE8D2);     // Soft Seafoam / Mint Subtitle on dark hero
  static const mintHighlight = Color(0xFF55C98C);// Mint Gradient Highlight
  static const mintGlow = Color(0xFF49D58A);     // Ambient Mint Radial Glow

  // ── 3. Canvas & Surfaces ───────────────────────────────────────────────────
  // Change [canvas] for the main screen background and [surface] for cards.
  static const canvas = Color(0xFFF8FAFC);       // Modern Luminous Canvas
  static const canvasSoft = Color(0xFFF1F5F9);   // Subtle Contrast Canvas
  static const surface = Colors.white;           // Crisp Card Surface
  static const surfaceMuted = Color(0xFFF8FAFC); // Subdued Card Background
  static const surfaceWarm = Color(0xFFFFFBF4);  // Warm Tinted Surface
  static const border = Color(0xFFE2E8F0);       // Standard Border
  static const borderHover = Color(0xFFBBCBE6);  // Hover Border
  static const borderLight = Color(0xFFF1F5F9);  // Faint Border

  // ── 4. Typography ──────────────────────────────────────────────────────────
  // Consistent, readable typography hierarchy across all portals.
  static const textPrimary = Color(0xFF0F172A);  // Slate 900 (High contrast headlines)
  static const textSecondary = Color(0xFF475569);// Slate 600 (Body copy & descriptions)
  static const textMuted = Color(0xFF94A3B8);    // Slate 400 (Subtitles, captions & locks)
  static const textOnPrimary = Colors.white;     // White text on primary gradients
  static const textOnAccent = Color(0xFF0F172A); // Dark readable text on gold/amber buttons

  // ── 5. Status & Utility Colors ─────────────────────────────────────────────
  static const success = Color(0xFF1E7654);      // Deep Emerald Green
  static const successDark = Color(0xFF134E3C);  // Forest Emerald
  static const successLight = Color(0xFFDDF3E8); // Soft Mint Background
  static const successBorder = Color(0xFFA7F3D0);// Mint Border

  static const info = Color(0xFF0284C7);         // Sky Blue (Links, Info, Calendar)
  static const infoDark = Color(0xFF0369A1);     // Deep Sky Blue
  static const infoLight = Color(0xFFE0F2FE);    // Sky Tint Background
  static const infoBorder = Color(0xFFBAE6FD);   // Sky Border

  static const danger = Color(0xFFEF4444);       // Red (Errors, Danger, Delete)
  static const dangerDark = Color(0xFFB42318);   // Dark Red
  static const dangerLight = Color(0xFFFEF2F2);  // Soft Red Background
  static const dangerBorder = Color(0xFFFECACA); // Red Border

  // ── 6. Educational Category / Discovery Sparks ─────────────────────────────
  // Distinct cheerful colors for student interests and discovery categories.
  static const categoryInterests = Color(0xFF1E7654); // Emerald
  static const categoryInterestsBg = Color(0xFFDDF3E8);
  static const categoryInterestsBorder = Color(0xFFA7F3D0);

  static const categoryHobbies = Color(0xFF0D9488);   // Deep Teal
  static const categoryHobbiesBg = Color(0xFFCCFBF1);
  static const categoryHobbiesBorder = Color(0xFF99F6E4);

  static const categoryFocus = Color(0xFF0284C7);     // Sky Blue
  static const categoryFocusBg = Color(0xFFE0F2FE);
  static const categoryFocusBorder = Color(0xFFBAE6FD);

  static const categoryMindset = Color(0xFFE5A024);   // Golden Amber
  static const categoryMindsetBg = Color(0xFFFEF3C7);
  static const categoryMindsetBorder = Color(0xFFFDE68A);

  // ── 7. Luminous Gradients ──────────────────────────────────────────────────
  // Hero & banner gradient: Deep Midnight Navy into Slate Teal into Forest Emerald.
  static const heroGradient = <Color>[
    Color(0xFF091C32), // Deep Midnight Navy Ocean
    Color(0xFF102F4C), // Deep Ocean Slate / Steel Teal
    Color(0xFF15533F), // Rich Forest Emerald
  ];

  // Creative discovery questionnaire header gradient.
  static const discoveryHeaderGradient = <Color>[
    Color(0xFFF7FAF8), // Soft bright canvas
    Color(0xFFEDF8F2), // Delicate mint wash
    Color(0xFFFEF3C7), // Sunny warm peach wash
  ];

  static const canvasGradient = <Color>[
    Color(0xFFF8FAF9),
    Color(0xFFF4F8F6),
    Color(0xFFEDF4F1),
  ];

  static const motivationalGradient = <Color>[
    Color(0xFFEDF8F2),
    Color(0xFFF2F9F5),
    Color(0xFFFFFBEB),
  ];

  // ── 8. Soft Shadows & Glows ────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: primary.withValues(alpha: 0.02),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get cardShadowHover => [
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: primary.withValues(alpha: 0.06),
      blurRadius: 36,
      offset: const Offset(0, 14),
    ),
  ];

  static List<BoxShadow> glow(Color color, {double opacity = 0.22, double blur = 20}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: blur,
      offset: const Offset(0, 6),
    ),
  ];
}
