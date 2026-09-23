import 'package:excellent_educators_web/app/theme/app_colors.dart';
import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:flutter/material.dart';

/// Premium container card for authentication forms (Login, Forgot Password).
/// Responsively styled for desktop, tablet, and mobile screens.
class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 480,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 18 : 24),
            border: Border.all(
              color: AppColors.border,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: isMobile ? 0.06 : 0.09),
                blurRadius: isMobile ? 24 : 36,
                offset: Offset(0, isMobile ? 8 : 14),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: isMobile ? 12 : 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            isMobile ? 18 : 36,
            isMobile ? 20 : 36,
            isMobile ? 18 : 36,
            isMobile ? 20 : 36,
          ),
          child: child,
        ),
      ),
    );
  }
}
