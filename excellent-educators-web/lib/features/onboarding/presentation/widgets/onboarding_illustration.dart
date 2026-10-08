import 'dart:math' as math;
import 'package:flutter/material.dart';

class OnboardingIllustrationWidget extends StatelessWidget {
  const OnboardingIllustrationWidget({
    super.key,
    required this.stickyWords,
  });

  final List<String> stickyWords;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / 320).clamp(0.75, 1.15);

        return Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 320,
            height: 250,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Soft background glow circle
                Positioned(
                  left: 60,
                  top: 50,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                    ),
                  ),
                ),

                // Floating gold geometric accents & sparkles
                Positioned(
                  left: 20,
                  top: 15,
                  child: _SparkleStar(color: const Color(0xFFF59E0B), size: 16),
                ),
                Positioned(
                  right: 40,
                  top: 2,
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFDE68A),
                        shape: BoxShape.rectangle,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 15,
                  top: 70,
                  child: _SparkleStar(color: const Color(0xFFFBBF24), size: 13),
                ),

                // Plant on left
                Positioned(
                  left: 6,
                  bottom: 25,
                  child: _PottedPlant(),
                ),

                // Stack of Books & Graduation Cap (Center)
                Positioned(
                  left: 55,
                  bottom: 12,
                  child: _BookStackWithCap(),
                ),

                // Pen Holder Cup (in front of books on left)
                Positioned(
                  left: 45,
                  bottom: 10,
                  child: _PenCup(),
                ),

                // Sticky Note on the right
                Positioned(
                  right: 2,
                  bottom: 45,
                  child: _StickyNote(words: stickyWords),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SparkleStar extends StatelessWidget {
  const _SparkleStar({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star_rounded,
      color: color,
      size: size,
    );
  }
}

class _BookStackWithCap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Graduation Cap (Mortarboard)
        SizedBox(
          width: 120,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Mortarboard Diamond Top
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateX(0.95)
                  ..rotateZ(0.785),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // Cap Skull Base
              Positioned(
                bottom: 8,
                child: Container(
                  width: 44,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),

              // Center Gold Button & Tassel
              Positioned(
                top: 14,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Gold Tassel String & Pendant
              Positioned(
                left: 36,
                top: 18,
                child: CustomPaint(
                  size: const Size(26, 26),
                  painter: _TasselPainter(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 2),

        // Top Book: Royal Blue with rounded spine
        Container(
          width: 124,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF172554),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 95,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),

        const SizedBox(height: 3),

        // Middle Book: Dark Navy
        Container(
          width: 136,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF020617),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    bottomLeft: Radius.circular(5),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 106,
                height: 15,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),

        const SizedBox(height: 3),

        // Bottom Book: Warm Gold / Amber
        Container(
          width: 148,
          height: 25,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x28B45309),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFFD97706),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 116,
                height: 17,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ],
    );
  }
}

class _TasselPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(22, 2)
      ..quadraticBezierTo(8, 8, 4, 18);

    canvas.drawPath(path, paint);

    // Tassel end drop
    final brush = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(4, 21), width: 4.5, height: 7),
      brush,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PenCup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pens sticking out
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Transform.rotate(
              angle: -0.22,
              child: Container(
                width: 4,
                height: 22,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(width: 2),
            Container(
              width: 4.5,
              height: 26,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 2),
            Transform.rotate(
              angle: 0.25,
              child: Container(
                width: 4,
                height: 20,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        // Cup Body
        Container(
          width: 28,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFDE68A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PottedPlant extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Plant Leaves
        SizedBox(
          width: 36,
          height: 60,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Stem
              Container(
                width: 2.5,
                height: 52,
                color: const Color(0xFF1E3A8A),
              ),
              // Left leaf
              Positioned(
                left: 2,
                bottom: 24,
                child: Transform.rotate(
                  angle: -0.5,
                  child: Container(
                    width: 14,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
              ),
              // Right leaf
              Positioned(
                right: 2,
                bottom: 34,
                child: Transform.rotate(
                  angle: 0.5,
                  child: Container(
                    width: 14,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
              ),
              // Top leaf
              Positioned(
                top: 0,
                child: Container(
                  width: 9,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Pot
        Container(
          width: 24,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
        ),
      ],
    );
  }
}

class _StickyNote extends StatelessWidget {
  const _StickyNote({required this.words});

  final List<String> words;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.06,
      child: Container(
        width: 82,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFCE8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFEF08A), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 8,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final word in words) ...[
              Text(
                word,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                  height: 1.3,
                  letterSpacing: -0.1,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Container(
              height: 2.2,
              width: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
