import 'dart:math' as math;

import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:excellent_educators_web/features/onboarding/presentation/widgets/onboarding_static_content.dart';
import 'package:flutter/material.dart';

/// Luminous 360° circular orbital showcase of the 9 learning pillars.
/// Places the Excellent Educators logo in the center with all 9 pillars
/// gracefully orbiting in an open, balanced ellipse with generous spacing.
class OnboardingIllustrationWidget extends StatefulWidget {
  const OnboardingIllustrationWidget({
    super.key,
    this.stickyWords = const [],
    this.pillars = OnboardingStaticContent.learningPillars,
  });

  /// Kept for call-site compatibility.
  final List<String> stickyWords;
  final List<String> pillars;

  @override
  State<OnboardingIllustrationWidget> createState() =>
      _OnboardingIllustrationWidgetState();
}

class _OnboardingIllustrationWidgetState
    extends State<OnboardingIllustrationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _active = 0;
  int? _hovered;

  // Symmetrically tuned angles (in degrees) for the 9 pillars to guarantee
  // generous breathing room all around, particularly separating Creativity
  // and Decision-making at the bottom.
  static const List<double> _customAnglesDeg = [
    -90.0, // 0: Interests (Top center)
    -52.0, // 1: Confidence (Upper right)
    -12.0, // 2: Leadership (Middle right)
    26.0,  // 3: Communication (Lower right)
    64.0,  // 4: Decision-making (Bottom right — comfortably spaced)
    116.0, // 5: Creativity (Bottom left — comfortably spaced)
    154.0, // 6: Curiosity (Lower left)
    192.0, // 7: Teamwork (Middle left)
    232.0, // 8: Future Aspirations (Upper left)
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted && _hovered == null) {
            setState(() {
              _active = (_active + 1) % math.max(widget.pillars.length, 1);
            });
          }
          _controller
            ..reset()
            ..forward();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPillarTapped(int index) {
    setState(() {
      _active = index;
    });
    _controller
      ..reset()
      ..forward();
  }

  double _angleRadFor(int index, int total) {
    if (index < _customAnglesDeg.length) {
      return _customAnglesDeg[index] * math.pi / 180.0;
    }
    const startAngle = -math.pi / 2;
    return startAngle + (index * 2 * math.pi / total);
  }

  @override
  Widget build(BuildContext context) {
    final pillars = widget.pillars;
    if (pillars.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentIndex = _hovered ?? _active;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(290.0, 360.0);
        final height = width * 0.98;
        final center = Offset(width / 2, height / 2);
        // Slightly wider horizontal radius for maximum horizontal breathing room
        final radiusX = width * 0.40;
        final radiusY = height * 0.36;
        final logoSize = width * 0.25;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 1. Soft Warm Ambient Aura (replaces harsh dark blue box)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFEF3C7).withValues(alpha: 0.55),
                          const Color(0xFFE0F2FE).withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Celestial Orbital Rings & Energy Beam to the Active Pillar
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final activeAngle = _angleRadFor(currentIndex, pillars.length);
                    final activePos = Offset(
                      center.dx + math.cos(activeAngle) * radiusX,
                      center.dy + math.sin(activeAngle) * radiusY,
                    );

                    return CustomPaint(
                      painter: _OrbitCelestialPainter(
                        center: center,
                        radiusX: radiusX,
                        radiusY: radiusY,
                        innerRadius: width * 0.17,
                        activePos: activePos,
                        pulse: _controller.value,
                      ),
                    );
                  },
                ),
              ),

              // 3. Center Brand Medallion with pulsing aura & active status badge
              _CenterBrandMedallion(
                size: logoSize,
                activePillar: pillars[currentIndex],
                pulse: _controller.value,
              ),

              // 4. Nine Pillars distributed in full 360° orbit with ample spacing
              for (var i = 0; i < pillars.length; i++)
                _buildOrbitalPillar(
                  index: i,
                  total: pillars.length,
                  label: pillars[i],
                  center: center,
                  radiusX: radiusX,
                  radiusY: radiusY,
                  isActive: i == currentIndex,
                  isHovered: i == _hovered,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrbitalPillar({
    required int index,
    required int total,
    required String label,
    required Offset center,
    required double radiusX,
    required double radiusY,
    required bool isActive,
    required bool isHovered,
  }) {
    final angle = _angleRadFor(index, total);
    final x = center.dx + math.cos(angle) * radiusX;
    final y = center.dy + math.sin(angle) * radiusY;

    return Positioned(
      left: x,
      top: y,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = index),
          onExit: (_) => setState(() => _hovered = null),
          child: GestureDetector(
            onTap: () => _onPillarTapped(index),
            child: _PillarOrbitalChip(
              label: label,
              isActive: isActive,
              isHovered: isHovered,
            ),
          ),
        ),
      ),
    );
  }
}

/// Upright, readable pill chip with natural intrinsic padding.
class _PillarOrbitalChip extends StatelessWidget {
  const _PillarOrbitalChip({
    required this.label,
    required this.isActive,
    required this.isHovered,
  });

  final String label;
  final bool isActive;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(label, isActive);

    return AnimatedScale(
      scale: isActive ? 1.08 : (isHovered ? 1.04 : 0.96),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: style.backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: style.borderColor,
            width: isActive ? 1.8 : 1.1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: style.accentColor.withValues(alpha: 0.35),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              )
            else
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              style.icon,
              size: 13,
              color: style.iconColor,
            ),
            const SizedBox(width: 4.5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: label.length > 13 ? 9.2 : 10.2,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                color: style.textColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _PillarStyle _styleFor(String label, bool active) {
    final key = label.toLowerCase();
    IconData icon;
    Color accent;

    if (key.contains('interest')) {
      icon = Icons.favorite_rounded;
      accent = const Color(0xFF059669); // Emerald
    } else if (key.contains('confidence')) {
      icon = Icons.emoji_events_rounded;
      accent = const Color(0xFFD97706); // Amber
    } else if (key.contains('leader')) {
      icon = Icons.groups_rounded;
      accent = const Color(0xFF2563EB); // Royal Blue
    } else if (key.contains('communicat')) {
      icon = Icons.forum_rounded;
      accent = const Color(0xFF0D9488); // Teal
    } else if (key.contains('decision')) {
      icon = Icons.alt_route_rounded;
      accent = const Color(0xFF7C3AED); // Violet
    } else if (key.contains('creativ')) {
      icon = Icons.auto_awesome_rounded;
      accent = const Color(0xFFE11D48); // Rose
    } else if (key.contains('curios')) {
      icon = Icons.lightbulb_rounded;
      accent = const Color(0xFFEA580C); // Warm Orange
    } else if (key.contains('team')) {
      icon = Icons.handshake_rounded;
      accent = const Color(0xFF0284C7); // Sky
    } else if (key.contains('future') || key.contains('aspir')) {
      icon = Icons.rocket_launch_rounded;
      accent = const Color(0xFF4F46E5); // Indigo
    } else {
      icon = Icons.star_rounded;
      accent = const Color(0xFFE5A024);
    }

    if (active) {
      return _PillarStyle(
        icon: icon,
        accentColor: accent,
        backgroundColor: Colors.white,
        borderColor: accent,
        iconColor: accent,
        textColor: const Color(0xFF0F172A),
      );
    }

    return _PillarStyle(
      icon: icon,
      accentColor: accent,
      backgroundColor: Colors.white.withValues(alpha: 0.94),
      borderColor: const Color(0xFFE2E8F0),
      iconColor: accent.withValues(alpha: 0.8),
      textColor: const Color(0xFF334155),
    );
  }
}

class _PillarStyle {
  const _PillarStyle({
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });

  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
}

/// Center Brand Logo surrounded by gold/mint concentric rings.
class _CenterBrandMedallion extends StatelessWidget {
  const _CenterBrandMedallion({
    required this.size,
    required this.activePillar,
    required this.pulse,
  });

  final double size;
  final String activePillar;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFE5A024),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE5A024).withValues(alpha: 0.28),
                blurRadius: 18,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.contain,
            child: AppLogo(height: size * 0.72),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFF03162B),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF03162B).withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 9.5,
                color: Color(0xFFFBBF24),
              ),
              const SizedBox(width: 4),
              Text(
                activePillar,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for astronomical circular orbit tracks and connection pulse.
class _OrbitCelestialPainter extends CustomPainter {
  const _OrbitCelestialPainter({
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.innerRadius,
    required this.activePos,
    required this.pulse,
  });

  final Offset center;
  final double radiusX;
  final double radiusY;
  final double innerRadius;
  final Offset activePos;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Outer main orbit track (subtle dashed golden ring)
    final orbitPaint = Paint()
      ..color = const Color(0xFFE5A024).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radiusX * 2,
        height: radiusY * 2,
      ),
      orbitPaint,
    );

    // 2. Inner supportive orbit track
    final innerPaint = Paint()
      ..color = const Color(0xFF059669).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, innerRadius, innerPaint);

    // 3. Delicate cardinal star nodes along the orbit
    final nodePaint = Paint()
      ..color = const Color(0xFFE5A024).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final p = Offset(
        center.dx + math.cos(a) * radiusX,
        center.dy + math.sin(a) * radiusY,
      );
      canvas.drawCircle(p, 2.0, nodePaint);
    }

    // 4. Subtle luminous connection beam to active pillar
    final beamPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFE5A024).withValues(alpha: 0.0),
          const Color(0xFFE5A024).withValues(alpha: 0.30 + 0.15 * (1 - pulse)),
        ],
      ).createShader(Rect.fromPoints(center, activePos))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawLine(center, activePos, beamPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitCelestialPainter oldDelegate) =>
      oldDelegate.activePos != activePos || oldDelegate.pulse != pulse;
}
