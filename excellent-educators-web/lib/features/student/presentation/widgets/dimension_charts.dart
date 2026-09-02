import 'dart:math' as math;

import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:flutter/material.dart';

class DimensionRadarChart extends StatelessWidget {
  const DimensionRadarChart({super.key, required this.dimensions, this.size = 260});

  final List<DimensionScoreDto> dimensions;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (dimensions.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Complete your assessment to see your profile chart.')),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RadarPainter(dimensions: dimensions),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < dimensions.length; i++)
              _LegendDot(
                color: _RadarPainter.chartColors[i % _RadarPainter.chartColors.length],
                label: dimensions[i].name,
              ),
          ],
        ),
      ],
    );
  }
}

class DimensionBarChart extends StatelessWidget {
  const DimensionBarChart({super.key, required this.dimensions});

  final List<DimensionScoreDto> dimensions;

  @override
  Widget build(BuildContext context) {
    if (dimensions.isEmpty) {
      return const Text('No dimension scores yet.');
    }

    final maxScore = dimensions.map((d) => d.score).fold<int>(1, math.max);

    return Column(
      children: [
        for (var i = 0; i < dimensions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BarRow(
              label: dimensions[i].name,
              score: dimensions[i].score,
              maxScore: maxScore,
              color: _RadarPainter.chartColors[i % _RadarPainter.chartColors.length],
            ),
          ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.score,
    required this.maxScore,
    required this.color,
  });

  final String label;
  final int score;
  final int maxScore;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = score / maxScore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            Text(
              '$score',
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                Container(color: const Color(0xFFEDE4D4)),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.05, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Brand.muted)),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.dimensions});

  final List<DimensionScoreDto> dimensions;

  static const chartColors = [
    Color(0xFFC6A15B),
    Color(0xFF4E8BC9),
    Color(0xFF5BB98C),
    Color(0xFFE07A5F),
    Color(0xFF9B5DE5),
    Color(0xFF00BBF9),
    Color(0xFFF15BB5),
    Color(0xFFFEE440),
    Color(0xFF00F5D4),
    Color(0xFFFB5607),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 28;
    final count = dimensions.length;
    if (count == 0) {
      return;
    }

    final maxScore = dimensions.map((d) => d.score).fold<int>(1, math.max);

    final gridPaint = Paint()
      ..color = const Color(0xFFD7CDBB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (var i = 0; i < count; i++) {
        final angle = _angle(i, count);
        final point = _polar(center, r, angle);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (var i = 0; i < count; i++) {
      final angle = _angle(i, count);
      final end = _polar(center, radius, angle);
      canvas.drawLine(center, end, gridPaint);
    }

    final dataPath = Path();
    for (var i = 0; i < count; i++) {
      final value = dimensions[i].score / maxScore;
      final angle = _angle(i, count);
      final point = _polar(center, radius * value, angle);
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();

    canvas.drawPath(
      dataPath,
      Paint()
        ..color = Brand.gold.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = Brand.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    for (var i = 0; i < count; i++) {
      final value = dimensions[i].score / maxScore;
      final angle = _angle(i, count);
      final point = _polar(center, radius * value, angle);
      canvas.drawCircle(point, 4, Paint()..color = chartColors[i % chartColors.length]);
    }

    final textStyle = TextStyle(color: Brand.navy.withValues(alpha: 0.85), fontSize: 9, fontWeight: FontWeight.w600);
    for (var i = 0; i < count; i++) {
      final angle = _angle(i, count);
      final labelPoint = _polar(center, radius + 16, angle);
      final label = dimensions[i].name.split(' ').first;
      final painter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, labelPoint - Offset(painter.width / 2, painter.height / 2));
    }
  }

  double _angle(int index, int count) => (math.pi * 2 * index / count) - math.pi / 2;

  Offset _polar(Offset center, double radius, double angle) {
    return Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.dimensions != dimensions;
}
