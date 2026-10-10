import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:excellent_educators_web/features/onboarding/presentation/widgets/onboarding_illustration.dart';
import 'package:excellent_educators_web/features/onboarding/presentation/widgets/onboarding_static_content.dart';
import 'package:flutter/material.dart';

class OnboardingScaffoldLayout extends StatelessWidget {
  const OnboardingScaffoldLayout({
    super.key,
    required this.sideTitlePrefix,
    required this.sideTitleHighlight,
    required this.sideDescription,
    required this.sideStickyWords,
    required this.formContent,
  });

  final String sideTitlePrefix;
  final String sideTitleHighlight;
  final String sideDescription;
  final List<String> sideStickyWords;
  final Widget formContent;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 980;
    final compact = screenWidth < 640;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Doodles and Decorative Shapes
          Positioned.fill(
            child: CustomPaint(
              painter: _EducationalDoodleBackgroundPainter(),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 28,
                vertical: compact ? 12 : 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Navigation Branding Bar
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 4 : 8,
                          vertical: compact ? 4 : 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo + Title + Subtitle
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppLogo(height: compact ? 34 : 44),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppStrings.excellentEducators,
                                      style: TextStyle(
                                        fontSize: compact ? 15 : 18,
                                        fontWeight: FontWeight.w800,
                                        color: Brand.navy,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      OnboardingStaticContent.appSubtitle,
                                      style: TextStyle(
                                        fontSize: compact ? 10.5 : 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF64748B),
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Right: Student Onboarding Badge with yellow bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  OnboardingStaticContent.topBadgeText,
                                  style: TextStyle(
                                    fontSize: compact ? 11.5 : 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  width: 28,
                                  height: 3.2,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: compact ? 10 : 18),

                      // Main Rounded White Container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(compact ? 16 : 24),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0C03162B),
                              blurRadius: 36,
                              offset: Offset(0, 14),
                            ),
                          ],
                        ),
                        child: isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Column: The Form (62% width)
                                  Expanded(
                                    flex: 13,
                                    child: Padding(
                                      padding: const EdgeInsets.all(28),
                                      child: formContent,
                                    ),
                                  ),

                                  // Subtle vertical border divider
                                  Container(
                                    width: 1.2,
                                    color: const Color(0xFFF1F5F9),
                                  ),

                                  // Right Column: Side Showcase Card (38% width)
                                  Expanded(
                                    flex: 8,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: 36,
                                        bottom: 24,
                                        left: 28,
                                        right: 28,
                                      ),
                                      child: _SideShowcaseCard(
                                        titlePrefix: sideTitlePrefix,
                                        titleHighlight: sideTitleHighlight,
                                        description: sideDescription,
                                        stickyWords: sideStickyWords,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Padding(
                                padding: EdgeInsets.all(compact ? 14 : 22),
                                child: formContent,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideShowcaseCard extends StatelessWidget {
  const _SideShowcaseCard({
    required this.titlePrefix,
    required this.titleHighlight,
    required this.description,
    required this.stickyWords,
  });

  final String titlePrefix;
  final String titleHighlight;
  final String description;
  final List<String> stickyWords;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Headline: e.g. "Discover\nYour Interests"
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -0.5,
              fontFamily: 'sans-serif',
            ),
            children: [
              TextSpan(
                text: titlePrefix,
                style: const TextStyle(color: Color(0xFF0B192C)),
              ),
              TextSpan(
                text: titleHighlight,
                style: const TextStyle(color: Color(0xFFF59E0B)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Yellow Accent Line
        Container(
          width: 32,
          height: 3.5,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        const SizedBox(height: 14),

        // Static Description Text
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 24),

        // Cinematic 9-pillar fan with app logo (replaces old book art)
        const Center(
          child: OnboardingIllustrationWidget(),
        ),
      ],
    );
  }
}

class _EducationalDoodleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Subtle warm organic pastel wave in bottom corners
    final wavePaint = Paint()
      ..color = const Color(0xFFFEF3C7).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // Bottom-left soft hill
    final leftPath = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.12,
        size.height * 0.72,
        size.width * 0.18,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(leftPath, wavePaint);

    // Bottom-right soft hill
    final rightPath = Path()
      ..moveTo(size.width, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.74,
        size.width * 0.80,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(rightPath, wavePaint);

    // 2. Educational Doodles in light blue line art
    final doodlePaint = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.30)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final goldStarPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.32)
      ..style = PaintingStyle.fill;

    // Open Book Doodle (Left side)
    final bookCenter = Offset(size.width * 0.08, size.height * 0.28);
    _drawOpenBook(canvas, bookCenter, doodlePaint);

    // Lightbulb Doodle (Left lower)
    final bulbCenter = Offset(size.width * 0.09, size.height * 0.50);
    _drawLightbulb(canvas, bulbCenter, doodlePaint);

    // Graduation Cap Doodle (Top right)
    final capCenter = Offset(size.width * 0.92, size.height * 0.16);
    _drawGradCap(canvas, capCenter, doodlePaint);

    // Pencil Doodle (Right side)
    final pencilCenter = Offset(size.width * 0.93, size.height * 0.44);
    _drawPencil(canvas, pencilCenter, doodlePaint);

    // Puzzle Piece Doodle (Right lower)
    final puzzleCenter = Offset(size.width * 0.92, size.height * 0.62);
    _drawPuzzlePiece(canvas, puzzleCenter, doodlePaint);

    // Scattered gold stars
    _drawStar(canvas, Offset(size.width * 0.07, size.height * 0.12), 8, goldStarPaint);
    _drawStar(canvas, Offset(size.width * 0.03, size.height * 0.54), 6, goldStarPaint);
    _drawStar(canvas, Offset(size.width * 0.89, size.height * 0.31), 7, goldStarPaint);
  }

  void _drawOpenBook(Canvas canvas, Offset center, Paint paint) {
    final path = Path()
      // Spine
      ..moveTo(center.dx, center.dy - 18)
      ..lineTo(center.dx, center.dy + 18)
      // Left Page Top
      ..moveTo(center.dx, center.dy - 18)
      ..quadraticBezierTo(center.dx - 18, center.dy - 24, center.dx - 36, center.dy - 14)
      ..lineTo(center.dx - 36, center.dy + 20)
      ..quadraticBezierTo(center.dx - 18, center.dy + 12, center.dx, center.dy + 18)
      // Right Page Top
      ..moveTo(center.dx, center.dy - 18)
      ..quadraticBezierTo(center.dx + 18, center.dy - 24, center.dx + 36, center.dy - 14)
      ..lineTo(center.dx + 36, center.dy + 20)
      ..quadraticBezierTo(center.dx + 18, center.dy + 12, center.dx, center.dy + 18);

    canvas.drawPath(path, paint);

    // Page lines
    canvas.drawLine(Offset(center.dx - 28, center.dy - 6), Offset(center.dx - 8, center.dy - 4), paint);
    canvas.drawLine(Offset(center.dx - 28, center.dy + 2), Offset(center.dx - 8, center.dy + 4), paint);
    canvas.drawLine(Offset(center.dx + 8, center.dy - 4), Offset(center.dx + 28, center.dy - 6), paint);
    canvas.drawLine(Offset(center.dx + 8, center.dy + 4), Offset(center.dx + 28, center.dy + 2), paint);
  }

  void _drawLightbulb(Canvas canvas, Offset center, Paint paint) {
    canvas.drawCircle(Offset(center.dx, center.dy - 6), 14, paint);
    // Base
    canvas.drawLine(Offset(center.dx - 6, center.dy + 8), Offset(center.dx + 6, center.dy + 8), paint);
    canvas.drawLine(Offset(center.dx - 4, center.dy + 12), Offset(center.dx + 4, center.dy + 12), paint);
    // Glow Rays
    canvas.drawLine(Offset(center.dx - 22, center.dy - 6), Offset(center.dx - 16, center.dy - 6), paint);
    canvas.drawLine(Offset(center.dx + 16, center.dy - 6), Offset(center.dx + 22, center.dy - 6), paint);
    canvas.drawLine(Offset(center.dx - 14, center.dy - 20), Offset(center.dx - 10, center.dy - 16), paint);
    canvas.drawLine(Offset(center.dx + 10, center.dy - 16), Offset(center.dx + 14, center.dy - 20), paint);
  }

  void _drawGradCap(Canvas canvas, Offset center, Paint paint) {
    final diamond = Path()
      ..moveTo(center.dx, center.dy - 12)
      ..lineTo(center.dx + 28, center.dy)
      ..lineTo(center.dx, center.dy + 10)
      ..lineTo(center.dx - 28, center.dy)
      ..close();
    canvas.drawPath(diamond, paint);

    // Skull arc
    final arc = Path()
      ..moveTo(center.dx - 16, center.dy + 4)
      ..quadraticBezierTo(center.dx, center.dy + 18, center.dx + 16, center.dy + 4);
    canvas.drawPath(arc, paint);

    // Tassel
    canvas.drawLine(Offset(center.dx, center.dy), Offset(center.dx + 22, center.dy + 14), paint);
  }

  void _drawPencil(Canvas canvas, Offset center, Paint paint) {
    final path = Path()
      ..moveTo(center.dx - 12, center.dy - 20)
      ..lineTo(center.dx + 10, center.dy + 16)
      ..lineTo(center.dx + 4, center.dy + 20)
      ..lineTo(center.dx - 18, center.dy - 16)
      ..close();
    canvas.drawPath(path, paint);

    // Tip
    final tip = Path()
      ..moveTo(center.dx - 18, center.dy - 16)
      ..lineTo(center.dx - 24, center.dy - 22)
      ..lineTo(center.dx - 12, center.dy - 20)
      ..close();
    canvas.drawPath(tip, paint);
  }

  void _drawPuzzlePiece(Canvas canvas, Offset center, Paint paint) {
    final rect = Rect.fromCenter(center: center, width: 28, height: 28);
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(5));
    canvas.drawRRect(r, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
