import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

import 'package:excellent_educators_web/app/theme/breakpoints.dart';

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          elevation: 0,
          color: Brand.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            side: BorderSide(color: Brand.creamDark.withValues(alpha: 0.9)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 18 : 28,
              isMobile ? 22 : 32,
              isMobile ? 18 : 28,
              isMobile ? 20 : 28,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
