import 'dart:math' as math;

import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cinematic weekly lesson video card.
/// Full-image placeholder presentation:
/// - Background: High-resolution cinematic artwork (`assets/images/excellent_educators_placeholder.jpg`).
/// - Center: Highlighted cinematic gold play button with pulsing multi-ring bloom.
/// - Right side: Highlighted title overlaid on the photo with soft contrast scrim.
/// - Whole card is window-constrained and clickable to launch video.
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
      duration: const Duration(milliseconds: 3000),
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
    // Proportional window-sized width with native 16:9 video aspect ratio
    final maxCardWidth = widget.compact ? 580.0 : 680.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCardWidth),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final t = 0.45 + (_pulse.value * 0.55);

            return LayoutBuilder(
              builder: (context, outerConstraints) {
                final playSize = outerConstraints.maxWidth > 540 ? 64.0 : 56.0;
                final halfPlay = playSize / 2;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image frame + overlays; play sits on the bottom edge
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _open,
                            onHighlightChanged: (v) =>
                                setState(() => _pressed = v),
                            borderRadius: BorderRadius.circular(20),
                            child: Ink(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFF6D67A)
                                      .withValues(alpha: 0.40),
                                  width: 1.25,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFC98A12)
                                        .withValues(alpha: 0.25),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(19),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isHorizontal =
                                          constraints.maxWidth >= 480;

                                      return Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.asset(
                                            'assets/images/excellent_educators_placeholder.jpg',
                                            fit: BoxFit.cover,
                                            alignment: Alignment.center,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) =>
                                                Container(
                                              color: const Color(0xFF07172A),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.smart_display_rounded,
                                                  size: 54,
                                                  color: Color(0xFFD4AF37),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: isHorizontal
                                                    ? LinearGradient(
                                                        begin:
                                                            Alignment.centerLeft,
                                                        end: Alignment
                                                            .centerRight,
                                                        colors: [
                                                          Colors.transparent,
                                                          Colors.transparent,
                                                          Colors.black
                                                              .withValues(
                                                            alpha: 0.22,
                                                          ),
                                                          Colors.black
                                                              .withValues(
                                                            alpha: 0.55,
                                                          ),
                                                        ],
                                                        stops: const [
                                                          0.0,
                                                          0.38,
                                                          0.58,
                                                          1.0,
                                                        ],
                                                      )
                                                    : LinearGradient(
                                                        begin: Alignment
                                                            .topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: [
                                                          Colors.transparent,
                                                          Colors.black
                                                              .withValues(
                                                            alpha: 0.25,
                                                          ),
                                                          Colors.black
                                                              .withValues(
                                                            alpha: 0.55,
                                                          ),
                                                        ],
                                                        stops: const [
                                                          0.0,
                                                          0.45,
                                                          1.0,
                                                        ],
                                                      ),
                                              ),
                                            ),
                                          ),
                                          // Title — more room now that play is at bottom
                                          if (isHorizontal)
                                            Positioned(
                                              top: 20,
                                              bottom: playSize * 0.65,
                                              right: 0,
                                              width:
                                                  constraints.maxWidth * 0.58,
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  left: 8,
                                                  right: constraints.maxWidth >
                                                          540
                                                      ? 28
                                                      : 18,
                                                ),
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: _VideoTitlePlate(
                                                    title: _title,
                                                    titleSize: constraints
                                                                .maxWidth >
                                                            560
                                                        ? 44.0
                                                        : 36.0,
                                                    glow: t,
                                                    centered: false,
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            Positioned(
                                              left: 16,
                                              right: 16,
                                              top: 18,
                                              child: _VideoTitlePlate(
                                                title: _title,
                                                titleSize: 28.0,
                                                glow: t,
                                                centered: true,
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Play — half inside image, half outside bottom edge
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: -halfPlay,
                          child: Center(
                            child: GestureDetector(
                              onTap: _open,
                              child: AnimatedScale(
                                scale: _pressed ? 0.92 : 1.0,
                                duration: const Duration(milliseconds: 130),
                                curve: Curves.easeOut,
                                child: _CinematicPlayButton(
                                  size: playSize,
                                  glow: t,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Reserve space for the protruding half of the play button
                    SizedBox(height: halfPlay + 4),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Large title only — no plate, eyebrow, or CTA.
class _VideoTitlePlate extends StatelessWidget {
  const _VideoTitlePlate({
    required this.title,
    required this.titleSize,
    required this.glow,
    required this.centered,
  });

  final String title;
  final double titleSize;
  final double glow;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      textAlign: centered ? TextAlign.center : TextAlign.left,
      style: GoogleFonts.playfairDisplay(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: titleSize,
        height: 1.08,
        letterSpacing: -0.4,
        shadows: [
          Shadow(
            color: Brand.gold.withValues(alpha: 0.45 * glow),
            blurRadius: 22,
          ),
          Shadow(
            color: Colors.black.withValues(alpha: 0.95),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

/// Highlighted cinematic glowing play button with multi-ring golden bloom
class _CinematicPlayButton extends StatelessWidget {
  const _CinematicPlayButton({
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
        boxShadow: [
          // Outer wide ambient golden aura
          BoxShadow(
            color: Brand.gold.withValues(alpha: 0.55 * glow),
            blurRadius: 32 * glow,
            spreadRadius: 3.5,
          ),
          // Inner focused glow
          BoxShadow(
            color: const Color(0xFFF6D67A).withValues(alpha: 0.70 * glow),
            blurRadius: 16 * glow,
            spreadRadius: 1.0,
          ),
          // Contact depth shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Pulsing gold ring
          CustomPaint(
            painter: _CinematicRingPainter(glow: glow),
          ),

          // Metallic gradient core
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.25, -0.3),
                  radius: 0.9,
                  colors: [
                    Color(0xFFFFF0B3),
                    Color(0xFFF6D67A),
                    Brand.gold,
                    Color(0xFFB57C0A),
                  ],
                  stops: [0.0, 0.35, 0.70, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.65),
                  width: 1.6,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: const Color(0xFF041224),
                  size: size * 0.56,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CinematicRingPainter extends CustomPainter {
  _CinematicRingPainter({required this.glow});

  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    final outerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = SweepGradient(
        colors: [
          const Color(0xFFFFF0B3).withValues(alpha: 0.9),
          Brand.gold.withValues(alpha: 0.8),
          const Color(0xFFB57C0A).withValues(alpha: 0.9),
          Brand.gold.withValues(alpha: 0.8),
          const Color(0xFFFFF0B3).withValues(alpha: 0.9),
        ],
        transform: GradientRotation(glow * math.pi * 0.5),
      ).createShader(Rect.fromCircle(center: c, radius: r));

    canvas.drawCircle(c, r - 0.8, outerRing);
  }

  @override
  bool shouldRepaint(covariant _CinematicRingPainter oldDelegate) =>
      oldDelegate.glow != glow;
}
