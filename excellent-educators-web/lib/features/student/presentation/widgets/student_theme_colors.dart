import 'package:excellent_educators_web/app/theme/student_colors.dart';
import 'package:flutter/material.dart';

export 'package:excellent_educators_web/app/theme/student_colors.dart';

/// Standardized card surface wrapper for the student learning portal.
class StudentCard extends StatefulWidget {
  const StudentCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final r = widget.borderRadius ?? BorderRadius.circular(isMobile ? 14 : 16);
    final border = Border.all(
      color: _hover
          ? (widget.borderColor ?? StudentColors.forest.withValues(alpha: 0.35))
          : (widget.borderColor ?? StudentColors.border),
      width: 1.2,
    );

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: widget.padding ?? EdgeInsets.all(isMobile ? 13 : 17),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? StudentColors.surface,
        borderRadius: r,
        border: border,
        boxShadow: _hover
            ? StudentColors.cardShadowHover
            : StudentColors.cardShadow,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) {
      return container;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? 1.01 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: container,
        ),
      ),
    );
  }
}
