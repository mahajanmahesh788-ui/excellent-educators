import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:flutter/material.dart';

/// Centered empty-state panel with icon, title, optional subtitle and action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.fillHeight = true,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;
  /// When true, vertically centers within available space (use inside [Expanded] or full-page bodies).
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 28,
        vertical: isMobile ? 16 : 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isMobile ? 64 : 88,
            height: isMobile ? 64 : 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Brand.navy.withValues(alpha: 0.08),
                  Brand.gold.withValues(alpha: 0.18),
                ],
              ),
              border: Border.all(color: Brand.gold.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, size: isMobile ? 30 : 40, color: Brand.navy.withValues(alpha: 0.72)),
          ),
          SizedBox(height: isMobile ? 12 : 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Brand.navy,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Brand.muted,
                    height: 1.45,
                  ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 22),
            action!,
          ],
        ],
      ),
    );

    if (!fillHeight) {
      return Center(child: content);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : 280.0;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}

/// Preset icons for common empty states.
abstract final class EmptyIcons {
  static const students = Icons.school_outlined;
  static const teachers = Icons.badge_outlined;
  static const batches = Icons.groups_outlined;
  static const assessments = Icons.quiz_outlined;
  static const requests = Icons.support_agent_outlined;
  static const feedback = Icons.forum_outlined;
  static const ratings = Icons.star_outline_rounded;
  static const results = Icons.insights_outlined;
  static const search = Icons.search_off_rounded;
  static const list = Icons.inbox_outlined;
}
