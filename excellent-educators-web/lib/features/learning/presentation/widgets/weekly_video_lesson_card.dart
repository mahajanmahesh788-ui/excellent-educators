import 'dart:math' as math;

import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cinematic weekly lesson video card.
/// Split layout on desktop:
/// - Left side: Illustrated "Road of Clarity" showing multiple roads (one with a lone student, one with students together).
/// - Right side: Full-height title card with big bold typography and action button.
/// - Mobile: Gracefully stacked with compact proportions.
class WeeklyVideoLessonCard extends StatefulWidget {
  const WeeklyVideoLessonCard({
    super.key,
    required this.videoUrl,
    this.title,
    this.compact = false,
  });

  final String videoUrl;
  final String? title;
  final bool compact;

  @override
  State<WeeklyVideoLessonCard> createState() => _WeeklyVideoLessonCardState();
}

class _WeeklyVideoLessonCardState extends State<WeeklyVideoLessonCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pulse;

  String get _title {
    final value = widget.title?.trim();
    if (value != null && value.isNotEmpty) return value;
    return AppStrings.weeklyVideoLesson;
  }

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _pulse.stop();
      _pulse.value = 0.55;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri == null) return;
    await launchUrl(uri, webOnlyWindowName: AppStrings.blank);
  }

  @override
  Widget build(BuildContext context) {
    // Keep UI properly scaled in window/desktop instead of sprawling full-screen
    final maxCardWidth = widget.compact ? 620.0 : 840.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCardWidth),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _open,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF7EC8E8).withValues(alpha: 0.35),
                  width: 1.15,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Brand.navy.withValues(alpha: 0.32),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isHorizontal = constraints.maxWidth >= 580;

                    return AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) {
                        final t = 0.45 + (_pulse.value * 0.55);

                        if (isHorizontal) {
                          // Desktop Split: Left side image, Right side full-height big title
                          return SizedBox(
                            height: widget.compact ? 270 : 310,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left Side: Visual scene with multiple roads
                                Expanded(
                                  flex: 11,
                                  child: _SceneSection(
                                    pulse: t,
                                    pressed: _pressed,
                                    compact: true,
                                  ),
                                ),
                                // Vertical divider line with gold tint
                                Container(
                                  width: 1.2,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                // Right Side: Full-height title card
                                Expanded(
                                  flex: 10,
                                  child: _TitleSidePanel(
                                    title: _title,
                                    compact: widget.compact,
                                    pulse: t,
                                    onPlay: _open,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Mobile Stacked: Top image, Bottom title panel
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: _SceneSection(
                                pulse: t,
                                pressed: _pressed,
                                compact: true,
                              ),
                            ),
                            Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            _TitleSidePanel(
                              title: _title,
                              compact: true,
                              pulse: t,
                              onPlay: _open,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The left visual artwork section containing:
/// - Custom painted scene with multiple roads (one lone student, one student group)
/// - Top brand seal
/// - Center glowing gold play button
class _SceneSection extends StatelessWidget {
  const _SceneSection({
    required this.pulse,
    required this.pressed,
    required this.compact,
  });

  final double pulse;
  final bool pressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Cinematic multi-road illustration
        _CinematicScene(pulse: pulse),
        // Soft gradient veil
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.20),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.50),
              ],
              stops: const [0.0, 0.40, 1.0],
            ),
          ),
        ),
        // Top-center brand seal
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: _BrandEmblem(
                compact: compact,
                glow: pulse,
              ),
            ),
          ),
        ),
        // Center gold play button
        Center(
          child: AnimatedScale(
            scale: pressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOut,
            child: _GoldPlayButton(
              size: compact ? 52 : 62,
              glow: pulse,
            ),
          ),
        ),
      ],
    );
  }
}

/// Right side full-height title panel:
/// Features large title, eyebrow badge, subtitle, and CTA button.
class _TitleSidePanel extends StatelessWidget {
  const _TitleSidePanel({
    required this.title,
    required this.compact,
    required this.pulse,
    required this.onPlay,
  });

  final String title;
  final bool compact;
  final double pulse;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 22,
        compact ? 16 : 20,
        compact ? 16 : 22,
        compact ? 16 : 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF031020),
            Color(0xFF071C35),
            Color(0xFF041224),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top metadata
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Brand.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Brand.gold.withValues(alpha: 0.40),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5.5,
                      height: 5.5,
                      decoration: const BoxDecoration(
                        color: Brand.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5.5),
                    const Text(
                      'FROM CONFUSION TO CLARITY',
                      style: TextStyle(
                        color: Color(0xFFF6D67A),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 10 : 14),

              // Big Title covering full visual space
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 18.0 : 22.0,
                  height: 1.25,
                  letterSpacing: -0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),

              // Inspiring subtitle / helper
              const Text(
                'Watch our approach · Master core concepts with guided clarity',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF9FB6D0),
                  fontSize: 12.0,
                  height: 1.35,
                ),
              ),
            ],
          ),

          // Bottom Action CTA
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    color: Brand.navy,
                    size: 18,
                  ),
                  label: const Text(
                    'Watch lesson',
                    style: TextStyle(
                      color: Brand.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF6D67A),
                    foregroundColor: Brand.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                    shadowColor: Brand.gold.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Video lesson',
                  style: TextStyle(
                    color: Color(0xFF7E97B4),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Top brand lockup: AppLogo in a round gold-ringed seal.
class _BrandEmblem extends StatelessWidget {
  const _BrandEmblem({
    required this.compact,
    required this.glow,
  });

  final bool compact;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final seal = compact ? 46.0 : 56.0;
    final logoH = compact ? 22.0 : 27.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: seal,
          height: seal,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Brand.gold.withValues(alpha: 0.40 * glow),
                blurRadius: 16 * glow,
                spreadRadius: 1.5,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _SealRingPainter(intensity: glow),
            child: Padding(
              padding: EdgeInsets.all(compact ? 6 : 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF16324A),
                      Brand.navy.withValues(alpha: 0.95),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Center(child: AppLogo(height: logoH)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'EXCELLENT',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.96),
            fontSize: compact ? 7.5 : 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            height: 1,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          '— EDUCATORS —',
          style: TextStyle(
            color: Brand.gold.withValues(alpha: 0.95),
            fontSize: compact ? 6.5 : 7.2,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _SealRingPainter extends CustomPainter {
  _SealRingPainter({required this.intensity});

  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = SweepGradient(
        colors: [
          const Color(0xFFF5D78E),
          Brand.gold,
          const Color(0xFFB8860B),
          Brand.gold,
          const Color(0xFFF5D78E),
        ],
        transform: GradientRotation(intensity * math.pi * 0.4),
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r - 1.0, ring);

    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Brand.gold.withValues(alpha: 0.35 + 0.25 * intensity);
    canvas.drawCircle(c, r - 3.8, outer);
  }

  @override
  bool shouldRepaint(covariant _SealRingPainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}

class _GoldPlayButton extends StatelessWidget {
  const _GoldPlayButton({
    required this.size,
    required this.glow,
  });

  final double size;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF6D67A),
            Brand.gold,
            Color(0xFFC98A12),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Brand.gold.withValues(alpha: 0.45 * glow),
            blurRadius: 24 * glow,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: Brand.navy,
        size: size * 0.58,
      ),
    );
  }
}

/// Cinematic "Road of Clarity" scene:
/// - Multiple roads:
///   1. Left solitary road: one lone student walking with backpack.
///   2. Right guided highway: multiple students walking together with backpacks toward the glowing city!
/// - Radiant city skyline across the glowing horizon.
/// - Twinkling cosmic sky with twilight horizon bloom.
class _CinematicScene extends StatelessWidget {
  const _CinematicScene({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CinematicScenePainter(pulse: pulse),
      child: const SizedBox.expand(),
    );
  }
}

class _CinematicScenePainter extends CustomPainter {
  _CinematicScenePainter({required this.pulse});

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.46;

    // 1. Atmospheric Deep Night Sky
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF020712), // Deep cosmos navy
          Color(0xFF051428),
          Color(0xFF09213F),
          Color(0xFF0E325C), // Radiant dusk horizon
        ],
        stops: const [0.0, 0.38, 0.72, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, horizonY + 20));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY + 20), sky);

    // 2. Horizon Glow (The city beacon of clarity)
    final horizonGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE5A83B).withValues(alpha: 0.30 + 0.12 * pulse),
          const Color(0xFF3B82F6).withValues(alpha: 0.14),
          Colors.transparent,
        ],
        stops: const [0.0, 0.38, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.52, horizonY),
          radius: size.width * 0.48,
        ),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY + 30), horizonGlow);

    // 3. Twinkling Stars
    final starPaint = Paint()..color = Colors.white;
    final rng = math.Random(55);
    for (var i = 0; i < 32; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * (horizonY * 0.82);
      final r = 0.5 + rng.nextDouble() * 1.0;
      final opacity = 0.25 + 0.50 * rng.nextDouble() + 0.15 * math.sin(pulse * math.pi + i);
      starPaint.color = Colors.white.withValues(alpha: opacity.clamp(0.1, 0.85));
      canvas.drawCircle(Offset(sx, sy), r, starPaint);
    }

    // 4. Distant City Skyline Silhouettes (Background Layer)
    final farSkyline = Paint()..color = const Color(0xFF07192D);
    final farPath = Path()..moveTo(0, horizonY);
    final farTowers = <(double, double, double)>[
      (0.14, 0.08, 0.040),
      (0.22, 0.12, 0.045),
      (0.32, 0.15, 0.035),
      (0.42, 0.22, 0.030),
      (0.50, 0.29, 0.026),
      (0.56, 0.25, 0.028),
      (0.64, 0.18, 0.034),
      (0.74, 0.14, 0.038),
      (0.84, 0.09, 0.042),
    ];
    for (final (cx, h, w) in farTowers) {
      final left = size.width * (cx - w / 2);
      final top = horizonY - size.height * h;
      final right = size.width * (cx + w / 2);
      farPath.addRRect(RRect.fromLTRBR(left, top, right, horizonY, const Radius.circular(1.5)));
    }
    canvas.drawPath(farPath, farSkyline);

    // 5. Midground City Skyline with Spires & Windows
    final midSkyline = Paint()..color = const Color(0xFF0B223C);
    final midSilhouette = Path()..moveTo(0, horizonY);
    final midTowers = <(double, double, double, bool)>[
      (0.18, 0.06, 0.035, false),
      (0.28, 0.11, 0.032, true),
      (0.38, 0.18, 0.028, true),
      (0.46, 0.26, 0.024, true),
      (0.51, 0.34, 0.020, true), // Center primary spire
      (0.58, 0.24, 0.024, true),
      (0.68, 0.16, 0.028, true),
      (0.78, 0.10, 0.032, false),
    ];

    final windowPaint = Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.55);
    final spirePaint = Paint()
      ..color = Brand.gold.withValues(alpha: 0.75)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final (cx, h, w, hasWindows) in midTowers) {
      final left = size.width * (cx - w / 2);
      final top = horizonY - size.height * h;
      final right = size.width * (cx + w / 2);
      midSilhouette.addRRect(RRect.fromLTRBR(left, top, right, horizonY, const Radius.circular(2.0)));

      // Architectural spire tip
      if (h > 0.15) {
        canvas.drawLine(
          Offset(size.width * cx, top),
          Offset(size.width * cx, top - size.height * 0.04),
          spirePaint,
        );
        // Beacon light
        canvas.drawCircle(
          Offset(size.width * cx, top - size.height * 0.04),
          1.3,
          Paint()..color = Brand.gold.withValues(alpha: 0.85 + 0.15 * pulse),
        );
      }

      // Glowing window dots
      if (hasWindows) {
        final rows = (h * 16).clamp(2, 5).toInt();
        for (var r = 1; r <= rows; r++) {
          final wy = top + (horizonY - top) * (r / (rows + 1));
          canvas.drawCircle(Offset(size.width * cx - 1.4, wy), 0.85, windowPaint);
          canvas.drawCircle(Offset(size.width * cx + 1.4, wy), 0.85, windowPaint);
        }
      }
    }
    canvas.drawPath(midSilhouette, midSkyline);

    // 6. Horizon Light Veil / Mist
    final mist = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF0F3660).withValues(alpha: 0.35),
          const Color(0xFF04101E).withValues(alpha: 0.80),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, horizonY - 10, size.width, 30));
    canvas.drawRect(Rect.fromLTWH(0, horizonY - 10, size.width, 30), mist);

    // 7. Ground Plane
    final ground = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF051222),
          Color(0xFF020912),
          Color(0xFF010408),
        ],
      ).createShader(Rect.fromLTRB(0, horizonY, size.width, size.height));
    canvas.drawRect(Rect.fromLTRB(0, horizonY, size.width, size.height), ground);

    // 8. MULTIPLE ROADS:
    // Road 1 (Left): Solitary Winding Road (a student is alone)
    final leftSolitaryRoad = Path()
      ..moveTo(size.width * 0.04, size.height)
      ..cubicTo(
        size.width * 0.10, size.height * 0.82,
        size.width * 0.18, size.height * 0.68,
        size.width * 0.36, horizonY + 2,
      )
      ..lineTo(size.width * 0.39, horizonY + 2)
      ..cubicTo(
        size.width * 0.24, size.height * 0.68,
        size.width * 0.20, size.height * 0.82,
        size.width * 0.22, size.height,
      )
      ..close();

    final solitaryRoadPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0D253E).withValues(alpha: 0.40),
          const Color(0xFF061424).withValues(alpha: 0.65),
          const Color(0xFF040D18).withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromLTRB(0, horizonY, size.width, size.height));
    canvas.drawPath(leftSolitaryRoad, solitaryRoadPaint);

    // Solitary road soft cyan/slate edge glow (symbolizing lonely questioning)
    final solitaryBorder = Path()
      ..moveTo(size.width * 0.04, size.height)
      ..cubicTo(
        size.width * 0.10, size.height * 0.82,
        size.width * 0.18, size.height * 0.68,
        size.width * 0.36, horizonY + 2,
      );
    canvas.drawPath(
      solitaryBorder,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF5BA3CB).withValues(alpha: 0.35),
    );

    // Road 2 (Right & Center): Guided Luminous Highway (multiple students together)
    final rightGuidedHighway = Path()
      ..moveTo(size.width * 0.32, size.height)
      ..cubicTo(
        size.width * 0.40, size.height * 0.80,
        size.width * 0.47, size.height * 0.65,
        size.width * 0.495, horizonY + 2,
      )
      ..lineTo(size.width * 0.545, horizonY + 2)
      ..cubicTo(
        size.width * 0.57, size.height * 0.65,
        size.width * 0.72, size.height * 0.80,
        size.width * 0.92, size.height,
      )
      ..close();

    final guidedSurface = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1E4878).withValues(alpha: 0.55),
          const Color(0xFF0F2C4C).withValues(alpha: 0.80),
          const Color(0xFF08182B).withValues(alpha: 0.95),
        ],
      ).createShader(Rect.fromLTRB(0, horizonY, size.width, size.height));
    canvas.drawPath(rightGuidedHighway, guidedSurface);

    // Glowing Neon Golden Borders along the Guided Highway
    final leftGuidedBorder = Path()
      ..moveTo(size.width * 0.32, size.height)
      ..cubicTo(
        size.width * 0.40, size.height * 0.80,
        size.width * 0.47, size.height * 0.65,
        size.width * 0.495, horizonY + 2,
      );
    final rightGuidedBorder = Path()
      ..moveTo(size.width * 0.92, size.height)
      ..cubicTo(
        size.width * 0.72, size.height * 0.80,
        size.width * 0.57, size.height * 0.65,
        size.width * 0.545, horizonY + 2,
      );

    final goldenGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFF9DC8A).withValues(alpha: 0.85 + 0.15 * pulse),
          Brand.gold.withValues(alpha: 0.65),
          const Color(0xFF64D2FF).withValues(alpha: 0.40),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.85, 1.0],
      ).createShader(Rect.fromLTRB(0, horizonY, size.width, size.height));

    final goldenBloom = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..color = Brand.gold.withValues(alpha: 0.16 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawPath(leftGuidedBorder, goldenBloom);
    canvas.drawPath(rightGuidedBorder, goldenBloom);
    canvas.drawPath(leftGuidedBorder, goldenGlow);
    canvas.drawPath(rightGuidedBorder, goldenGlow);

    // Guided highway dashed lane markings
    final centerDashes = [0.86, 0.77, 0.68, 0.60, 0.53];
    for (var i = 0; i < centerDashes.length; i++) {
      final tNorm = centerDashes[i];
      final dy = size.height * tNorm;
      final len = 6.0 * tNorm;
      final dx = size.width * (0.52 + (1.0 - tNorm) * 0.10);
      final dashPaint = Paint()
        ..color = const Color(0xFFF9DC8A).withValues(alpha: (0.45 + 0.25 * pulse) * (tNorm * 0.9))
        ..strokeWidth = 1.3 * tNorm
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(dx, dy), Offset(dx, dy - len), dashPaint);
    }

    // 9. STUDENT SILHOUETTES:
    // (A) ROAD 1 (Left): ONE STUDENT IS ALONE
    _drawStudentSilhouette(
      canvas,
      Offset(size.width * 0.14, size.height * 0.77),
      (size.height * 0.0022).clamp(0.60, 0.95),
      illuminated: false,
      pulse: pulse,
    );

    // (B) ROAD 2 (Right): MULTIPLE STUDENTS TOGETHER
    // Student 1 (leader, closer to horizon)
    _drawStudentSilhouette(
      canvas,
      Offset(size.width * 0.54, size.height * 0.69),
      (size.height * 0.0019).clamp(0.55, 0.85),
      illuminated: true,
      pulse: pulse,
    );
    // Student 2 (mid-pack, walking alongside)
    _drawStudentSilhouette(
      canvas,
      Offset(size.width * 0.63, size.height * 0.74),
      (size.height * 0.0023).clamp(0.65, 1.00),
      illuminated: true,
      pulse: pulse,
    );
    // Student 3 (foreground, walking with backpack in the group)
    _drawStudentSilhouette(
      canvas,
      Offset(size.width * 0.72, size.height * 0.80),
      (size.height * 0.0026).clamp(0.72, 1.15),
      illuminated: true,
      pulse: pulse,
    );

    // 10. Ambient Vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.40),
        ],
        stops: const [0.70, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  /// Helper to draw a proportional student with backpack silhouette
  void _drawStudentSilhouette(
    Canvas canvas,
    Offset pos,
    double s, {
    required bool illuminated,
    required double pulse,
  }) {
    final fx = pos.dx;
    final fy = pos.dy;

    // Head
    final headRect = Rect.fromCenter(
      center: Offset(fx, fy - 48 * s),
      width: 10 * s,
      height: 12 * s,
    );

    // Body & backpack
    final body = Path()
      ..moveTo(fx - 2.5 * s, fy - 41 * s)
      ..lineTo(fx - 12 * s, fy - 36 * s)
      ..lineTo(fx - 10 * s, fy - 22 * s)
      ..lineTo(fx - 7 * s, fy - 18 * s)
      ..lineTo(fx - 6 * s, fy)
      ..lineTo(fx - 1.5 * s, fy)
      ..lineTo(fx - 0.5 * s, fy - 17 * s)
      ..lineTo(fx + 0.5 * s, fy - 17 * s)
      ..lineTo(fx + 1.5 * s, fy)
      ..lineTo(fx + 6 * s, fy)
      ..lineTo(fx + 7 * s, fy - 18 * s)
      ..lineTo(fx + 10 * s, fy - 22 * s)
      ..lineTo(fx + 12 * s, fy - 36 * s)
      ..lineTo(fx + 2.5 * s, fy - 41 * s)
      ..close();

    final backpack = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(fx, fy - 29 * s),
          width: 13 * s,
          height: 16 * s,
        ),
        Radius.circular(3.5 * s),
      ));

    // Ground contact shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(fx, fy + 1 * s),
        width: 18 * s,
        height: 4.5 * s,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    // Silhouette fill
    final fillPaint = Paint()..color = const Color(0xFF030B17);
    canvas.drawOval(headRect, fillPaint);
    canvas.drawPath(body, fillPaint);
    canvas.drawPath(backpack, fillPaint);

    // Golden rim highlight from city ahead (only on illuminated guided road)
    if (illuminated) {
      final rimPaint = Paint()
        ..color = Brand.gold.withValues(alpha: 0.35 + 0.20 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * s;

      canvas.drawArc(headRect, math.pi * 0.9, math.pi * 1.2, false, rimPaint);
      final shoulderRim = Path()
        ..moveTo(fx - 12 * s, fy - 36 * s)
        ..lineTo(fx, fy - 40 * s)
        ..lineTo(fx + 12 * s, fy - 36 * s);
      canvas.drawPath(shoulderRim, rimPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CinematicScenePainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}
