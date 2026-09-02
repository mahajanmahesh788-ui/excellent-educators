import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          elevation: 0,
          color: Brand.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Brand.creamDark.withValues(alpha: 0.9)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: child,
          ),
        ),
      ),
    );
  }
}
