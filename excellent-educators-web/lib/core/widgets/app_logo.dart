import 'package:flutter/material.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 120,
    this.semanticLabel = AppStrings.excellentEducators,
  });

  static const assetPath = 'assets/images/app_logo.png';

  final double height;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Image.asset(
        assetPath,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
