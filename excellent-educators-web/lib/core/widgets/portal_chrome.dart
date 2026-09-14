import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:flutter/material.dart';

class AnimatedPortalBackdrop extends StatefulWidget {
  const AnimatedPortalBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedPortalBackdrop> createState() => _AnimatedPortalBackdropState();
}

class _AnimatedPortalBackdropState extends State<AnimatedPortalBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t, -1),
              end: Alignment(1 - t, 1),
              colors: [
                Color.lerp(const Color(0xFFF4F7FB), const Color(0xFFEEF3F9), t)!,
                Color.lerp(const Color(0xFFE8EEF6), const Color(0xFFF7F1E6), t)!,
                const Color(0xFFF8FAFC),
              ],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class PortalHero extends StatefulWidget {
  const PortalHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  State<PortalHero> createState() => _PortalHeroState();
}

class _PortalHeroState extends State<PortalHero> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          width: double.infinity,
          padding: isMobile
              ? const EdgeInsets.fromLTRB(14, 14, 14, 14)
              : const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
            gradient: LinearGradient(
              begin: Alignment(-1 + (t * 0.4), -1),
              end: Alignment(1, 0.8 - (t * 0.3)),
              colors: [
                Color.lerp(const Color(0xFF0B1F36), const Color(0xFF123152), t)!,
                Color.lerp(const Color(0xFF163A5C), const Color(0xFF0E2744), t)!,
                const Color(0xFF1E4A73),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Brand.navy.withValues(alpha: 0.22),
                blurRadius: isMobile ? 14 : 22,
                offset: Offset(0, isMobile ? 5 : 10),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMobile ? 32 : 42,
            height: 3,
            decoration: BoxDecoration(
              color: Brand.gold,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            widget.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: isMobile ? 12 : 13.5,
              height: 1.35,
            ),
          ),
          if (widget.actions.isNotEmpty) ...[
            SizedBox(height: isMobile ? 10 : 16),
            Wrap(spacing: 8, runSpacing: 8, children: widget.actions),
          ],
        ],
      ),
    );
  }
}

class PortalCard extends StatelessWidget {
  const PortalCard({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final resolvedPadding = padding ?? (isMobile ? const EdgeInsets.all(12) : const EdgeInsets.all(18));

    return Container(
      width: double.infinity,
      padding: resolvedPadding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(color: const Color(0xFFE4EAF1)),
        boxShadow: [
          BoxShadow(
            color: Brand.navy.withValues(alpha: 0.05),
            blurRadius: isMobile ? 10 : 18,
            offset: Offset(0, isMobile ? 3 : 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PortalButton extends StatelessWidget {
  const PortalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final disabled = busy || onPressed == null;
    final child = busy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: isMobile ? 14 : 16),
                const SizedBox(width: 6),
              ],
              Text(label),
            ],
          );

    if (outlined) {
      return OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Brand.navy,
          side: const BorderSide(color: Color(0xFFC9D4E3)),
          minimumSize: Size(0, isMobile ? 36 : 40),
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 14, vertical: isMobile ? 7 : 10),
          textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: isMobile ? 12 : 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: child,
      );
    }

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2744), Color(0xFF1A4A73)],
        ),
        boxShadow: [
          BoxShadow(
            color: Brand.navy.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 7 : 10),
            child: DefaultTextStyle(
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: isMobile ? 12 : 13),
              child: IconTheme(
                data: const IconThemeData(color: Colors.white, size: 16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
