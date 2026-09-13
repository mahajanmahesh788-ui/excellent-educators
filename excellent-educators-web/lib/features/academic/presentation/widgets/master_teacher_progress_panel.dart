import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/time/app_clock.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:excellent_educators_web/features/feedback/data/dto/feedback_dtos.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/feedback_charts.dart';
import 'package:flutter/material.dart';

class MasterTeacherProgressPanel extends StatelessWidget {
  const MasterTeacherProgressPanel({
    super.key,
    required this.data,
    this.onPendingStudentTap,
    this.onRateStudent,
    this.onEditStudentRating,
    this.onNotRatedTap,
    this.onAssessmentPendingTap,
    this.pendingStudentsTitle = 'Students awaiting rating',
    this.showPendingStudents = true,
  });

  final MasterTeacherDashboardDto data;
  final ValueChanged<MasterTeacherPendingStudentDto>? onPendingStudentTap;
  final ValueChanged<MasterTeacherPendingStudentDto>? onRateStudent;
  final ValueChanged<MasterTeacherPendingStudentDto>? onEditStudentRating;
  final VoidCallback? onNotRatedTap;
  final VoidCallback? onAssessmentPendingTap;
  final String pendingStudentsTitle;
  final bool showPendingStudents;

  @override
  Widget build(BuildContext context) {
    final counts = data.counts;
    final monthLabel = AppClock.monthLabel(data.currentMonth.year, data.currentMonth.month);
    final trendMonths = _trendMonths(data.byMonth);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MasterTeacherProgressHero(counts: counts, monthLabel: monthLabel),
        const SizedBox(height: 20),
        const Text(
          'This month',
          style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: wide ? 4 : 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: wide ? 2.2 : 1.8,
          children: [
            StatTile(label: 'Assigned students', value: '${counts.assignedStudents}'),
            StatTile(label: 'Rated this month', value: '${counts.ratedThisMonth}'),
            StatTile(label: 'Not rated yet', value: '${counts.notRatedThisMonth}'),
            StatTile(label: 'Completion', value: '${counts.completionPercent}%'),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Needs attention',
          style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 8),
        AttentionCard(
          label: 'Meetings held, not rated yet',
          count: counts.notRatedThisMonth,
          onTap: onNotRatedTap ?? () {},
        ),
        if (counts.studentsAssessmentPending > 0) ...[
          const SizedBox(height: 6),
          AttentionCard(
            label: 'Students — assessment pending',
            count: counts.studentsAssessmentPending,
            onTap: onAssessmentPendingTap ?? () {},
          ),
        ],
        if (showPendingStudents && data.pendingStudents.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            pendingStudentsTitle,
            style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          ...data.pendingStudents.map((student) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE6DCCB)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onPendingStudentTap == null ? null : () => onPendingStudentTap!(student),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.fullName,
                                style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                student.studentCode,
                                style: const TextStyle(color: Brand.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (student.canEditRating && onEditStudentRating != null)
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              backgroundColor: const Color(0xFFFEF3C7),
                              foregroundColor: const Color(0xFFB45309),
                            ),
                            onPressed: () => onEditStudentRating!(student),
                            child: const Text('Edit rating'),
                          )
                        else if (student.canRate && onRateStudent != null)
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              backgroundColor: const Color(0xFFFEF3C7),
                              foregroundColor: const Color(0xFFB45309),
                            ),
                            onPressed: () => onRateStudent!(student),
                            child: const Text('Rate'),
                          )
                        else if (onPendingStudentTap != null)
                          const Icon(Icons.chevron_right_rounded, color: Brand.muted),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 20),
        const Text(
          'Rating activity',
          style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 8),
        FeedbackMonthlyVolumeChart(months: trendMonths),
        const SizedBox(height: 12),
        FeedbackMonthlyTrendChart(months: trendMonths),
      ],
    );
  }

  List<FeedbackMonthSummaryDto> _trendMonths(List<MasterTeacherDashboardMonthDto> months) {
    return months
        .map(
          (month) => FeedbackMonthSummaryDto(
            year: month.year,
            month: month.month,
            averageRating: month.averageRating,
            sessionCount: month.studentsRated,
          ),
        )
        .toList();
  }
}

class MasterTeacherProgressHero extends StatelessWidget {
  const MasterTeacherProgressHero({super.key, required this.counts, required this.monthLabel});

  final MasterTeacherDashboardCountsDto counts;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final average = counts.overallAverage;
    final progress = counts.completionRate.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2744), Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall average',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        average == null ? '—' : average.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Brand.gold,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 6, bottom: 6),
                        child: Text('/ 10', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${counts.totalRatings}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                  const Text('total ratings', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white24,
                    color: Brand.gold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${counts.completionPercent}%',
                style: const TextStyle(color: Brand.gold, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${counts.ratedThisMonth} of ${counts.ratedThisMonth + counts.notRatedThisMonth} held meetings rated this month',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
