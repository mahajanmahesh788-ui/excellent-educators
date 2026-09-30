import 'package:flutter/material.dart';

/// Rounded outline border that keeps floating labels inside the field.
///
/// [OutlineInputBorder] reports [isOutline] `true`, so Flutter places the
/// floating label on the top border and paints it outside the field's layout
/// box. Scroll views, cards, and some web compositing layers clip that
/// overflow — which cuts the top of every floating label.
///
/// Returning [isOutline] `false` reserves space for the label inside the field
/// while still painting a full rounded outline (no border notch).
class AppOutlineInputBorder extends OutlineInputBorder {
  const AppOutlineInputBorder({
    super.borderSide = const BorderSide(),
    super.borderRadius = const BorderRadius.all(Radius.circular(12)),
    super.gapPadding = 4.0,
  });

  @override
  bool get isOutline => false;

  @override
  AppOutlineInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) {
    return AppOutlineInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
      gapPadding: gapPadding ?? this.gapPadding,
    );
  }

  @override
  AppOutlineInputBorder scale(double t) {
    return AppOutlineInputBorder(
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius * t,
      gapPadding: gapPadding * t,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is AppOutlineInputBorder) {
      return AppOutlineInputBorder(
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        gapPadding: a.gapPadding,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is AppOutlineInputBorder) {
      return AppOutlineInputBorder(
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        gapPadding: gapPadding,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    // Ignore the floating-label gap so the outline stays a full rounded rect.
    super.paint(
      canvas,
      rect,
      gapStart: null,
      gapExtent: 0,
      gapPercentage: 0,
      textDirection: textDirection,
    );
  }
}
