import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_journey.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';

class ProgressOverviewWidget extends StatelessWidget {
  const ProgressOverviewWidget({
    super.key,
    required this.student,
    required this.snapshot,
    this.learning,
  });

  final StudentDto student;
  final StudentJourneySnapshot snapshot;
  final LearningDashboardDto? learning;

  @override
  Widget build(BuildContext context) {
    final completedWeeks =
        learning?.completedWeeks ?? (snapshot.introductionCompleted ? 1 : 0);
    final totalWeeks = (learning?.totalWeeks ?? 0) > 0
        ? learning!.totalWeeks
        : 12;
    final levelProgress = (completedWeeks / (totalWeeks > 0 ? totalWeeks : 1))
        .clamp(0.0, 1.0);

    final allotment = snapshot.masterClassAllotment <= 0
        ? 1
        : snapshot.masterClassAllotment;
    final remaining = snapshot.masterClassRemaining;
    final usedThisMonth = (allotment - remaining).clamp(0, allotment);

    final totalAttended = student.feedbackTotalSessions > 0
        ? student.feedbackTotalSessions
        : (snapshot.introductionCompleted ? 1 : 0) + snapshot.masterThisMonth;

    final overallRating = student.feedbackOverallAverage;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return StudentCard(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: StudentColors.amberLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        size: 18,
                        color: StudentColors.amberDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PERFORMANCE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: StudentColors.amberDark,
                            ),
                          ),
                          Text(
                            'My Progress & Stats',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: StudentColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (overallRating != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: StudentColors.amberLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: StudentColors.amberWarm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: StudentColors.amberDark,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        overallRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: StudentColors.amberBrown,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // Central Circular Progress & Monthly Quota Ring
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: StudentColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: StudentColors.border),
            ),
            child: Row(
              children: [
                // Circular Ring
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(72, 72),
                        painter: _ProgressRingPainter(
                          progress: levelProgress,
                          backgroundColor: Colors.white,
                          gradientColors: const [
                            StudentColors.forest,
                            StudentColors.forestSoft,
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(levelProgress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: StudentColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Level',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: StudentColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Level Milestone Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.level != null && !student.level!.isEmpty
                            ? student.level!.label
                            : 'Active Level',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: StudentColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$completedWeeks of $totalWeeks weeks completed',
                        style: const TextStyle(
                          color: StudentColors.indigoPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Master Classes: $usedThisMonth of $allotment used this month',
                        style: const TextStyle(
                          color: StudentColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Metric Badges Strip
          Row(
            children: [
              Expanded(
                child: _StatMiniCard(
                  icon: Icons.check_circle_outline_rounded,
                  value: '$totalAttended',
                  label: 'Classes Attended',
                  color: StudentColors.emeraldDark,
                  bg: StudentColors.emeraldLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatMiniCard(
                  icon: Icons.calendar_today_rounded,
                  value: '$remaining',
                  label: 'Classes Left This Month',
                  color: remaining > 0
                      ? StudentColors.indigoPrimary
                      : StudentColors.textMuted,
                  bg: remaining > 0
                      ? StudentColors.indigoLight
                      : StudentColors.surfaceMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: StudentColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.gradientColors,
  });

  final double progress;
  final Color backgroundColor;
  final List<Color> gradientColors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    const strokeWidth = 8.0;

    // Background track
    final bgPaint = Paint()
      ..color = StudentColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    // Progress arc with gradient
    final sweepAngle = 2 * math.pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepGradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: gradientColors,
    );

    final progressPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
