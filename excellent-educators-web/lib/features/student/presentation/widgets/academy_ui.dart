import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

/// Layout helpers for student pages. Palette lives in [StudentColors].
abstract final class Academy {
  static const canvas = StudentColors.canvas;
  static const ink = StudentColors.textPrimary;
  static const muted = StudentColors.textSecondary;
  static const line = StudentColors.border;
  static const goldSoft = StudentColors.goldSoft;

  static const pagePadding = EdgeInsets.fromLTRB(24, 24, 24, 48);

  static EdgeInsets pageInsets(double width) {
    if (width >= 1280) return const EdgeInsets.fromLTRB(16, 18, 16, 40);
    if (width >= 900) return const EdgeInsets.fromLTRB(14, 16, 14, 36);
    if (width >= 600) return const EdgeInsets.fromLTRB(12, 12, 12, 28);
    return const EdgeInsets.fromLTRB(8, 8, 8, 16);
  }
}

class AcademyLabel extends StatelessWidget {
  const AcademyLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
        color: Academy.muted,
      ),
    );
  }
}

class AcademySurface extends StatefulWidget {
  const AcademySurface({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  State<AcademySurface> createState() => _AcademySurfaceState();
}

class _AcademySurfaceState extends State<AcademySurface> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final effectivePadding =
        widget.padding ??
        (isMobile ? const EdgeInsets.all(12) : const EdgeInsets.all(18));

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
        border: Border.all(
          color: _hover ? StudentColors.hoverMint : Academy.line,
        ),
        boxShadow: [
          BoxShadow(
            color: Brand.navy.withValues(alpha: _hover ? 0.08 : 0.04),
            blurRadius: _hover ? 22 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: widget.child,
    );

    if (widget.onTap == null) {
      return card;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? 1.01 : 1,
          duration: const Duration(milliseconds: 180),
          child: card,
        ),
      ),
    );
  }
}

class AcademyButton extends StatefulWidget {
  const AcademyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.busy = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool busy;
  final Color? color;

  @override
  State<AcademyButton> createState() => _AcademyButtonState();
}

class _AcademyButtonState extends State<AcademyButton> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.busy;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: !disabled && _hover ? 1.02 : 1,
        duration: const Duration(milliseconds: 160),
        child: FilledButton(
          onPressed: disabled ? null : widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: widget.outlined
                ? Colors.white
                : (widget.color ?? StudentColors.forest),
            foregroundColor: widget.outlined
                ? StudentColors.forest
                : Colors.white,
            disabledBackgroundColor: StudentColors.disabled,
            minimumSize: Size(0, isMobile ? 38 : 46),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 18,
              vertical: isMobile ? 8 : 12,
            ),
            side: BorderSide(
              color: widget.outlined ? Academy.line : Colors.transparent,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            ),
            textStyle: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: widget.busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class AcademyAvatar extends StatelessWidget {
  const AcademyAvatar({super.key, required this.name, this.size = 64});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [StudentColors.forestMid, StudentColors.textPrimary],
        ),
        border: Border.all(
          color: Brand.gold.withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: Brand.gold,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

class AcademyEmpty extends StatelessWidget {
  const AcademyEmpty({
    super.key,
    required this.title,
    required this.body,
    this.action,
    this.icon = Icons.auto_awesome_outlined,
  });

  final String title;
  final String body;
  final Widget? action;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AcademySurface(
      child: Column(
        children: [
          Icon(icon, size: 36, color: Brand.goldDark),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Academy.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Academy.muted, height: 1.5),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

class AcademyError extends StatelessWidget {
  const AcademyError({
    super.key,
    required this.onRetry,
    this.message = AppStrings.somethingWentWrongWhileLoadingThisPage,
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AcademyEmpty(
      icon: Icons.cloud_off_outlined,
      title: AppStrings.weCouldNotLoadThisJustNow,
      body: message,
      action: AcademyButton(label: AppStrings.tryAgain, onPressed: onRetry),
    );
  }
}

class AcademySkeleton extends StatelessWidget {
  const AcademySkeleton({super.key, this.height = 160});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: StudentColors.skeleton,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}
