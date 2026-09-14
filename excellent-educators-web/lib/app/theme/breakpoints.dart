import 'package:flutter/material.dart';

abstract final class Breakpoints {
  static const mobile = 600.0;
  static const tablet = 1024.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobile && w < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
}

abstract final class AppSpacing {
  static double screenPadding(BuildContext context) =>
      Breakpoints.isMobile(context) ? 12.0 : 20.0;

  static double cardPadding(BuildContext context) =>
      Breakpoints.isMobile(context) ? 12.0 : 16.0;

  static const double gapXs = 4.0;
  static const double gapSm = 8.0;
  static const double gapMd = 12.0;
  static const double gapLg = 16.0;
  static const double gapXl = 20.0;
}
