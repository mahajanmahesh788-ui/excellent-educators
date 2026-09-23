import 'dart:math' as math;
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class JourneyRibbon extends StatelessWidget {
  const JourneyRibbon({
    super.key,
    required this.levelName,
    required this.currentWeek,
    required this.weekCount,
  });

  final String levelName;
  final int currentWeek;
  final int weekCount;

  @override
  Widget build(BuildContext context) {
    final shown = List.generate(weekCount.clamp(1, 8), (index) => index + 1);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF10243A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            levelName.toUpperCase(),
            style: const TextStyle(
              color: Brand.gold,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final week in shown)
                _WeekChip(
                  week: week,
                  current: week == currentWeek,
                  done: week < currentWeek,
                ),
              if (weekCount > shown.length)
                Text(
                  '+${weekCount - shown.length} more',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekChip extends StatelessWidget {
  const _WeekChip({
    required this.week,
    required this.current,
    required this.done,
  });

  final int week;
  final bool current;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: current ? Brand.gold : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: current ? Brand.gold : Colors.white24),
      ),
      child: Text(
        done ? '✓ Week $week' : 'Week $week',
        style: TextStyle(
          color: current ? Brand.navy : Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class LearningJournalTable extends StatelessWidget {
  const LearningJournalTable({
    super.key,
    required this.journal,
    required this.staffView,
    required this.onOpenWeek,
  });

  final LearningJournalDto journal;
  final bool staffView;
  final void Function(LearningLevelGroupDto group, LearningWeekDto week)
  onOpenWeek;

  @override
  Widget build(BuildContext context) {
    if (journal.levels.isEmpty) {
      return const AcademySurface(
        child: Text(
          AppStrings.yourLearningJourneyWillAppearOnceALevelJourneyStarts,
        ),
      );
    }

    if (!staffView) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final group in journal.levels) ...[
            _StudentJourneyGrid(group: group, onOpenWeek: onOpenWeek),
            const SizedBox(height: 24),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (final group in journal.levels) ...[
          _LevelHeader(group: group),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final displayedWeeks = group.weeks.toList()
                ..sort((a, b) => b.weekNumber.compareTo(a.weekNumber));

              if (constraints.maxWidth < 680) {
                return _MobileStaffWeekList(
                  group: group,
                  weeks: displayedWeeks,
                  onOpenWeek: onOpenWeek,
                );
              }

              final tableWidth = math.max(constraints.maxWidth, 780.0);
              final dynamicSpacing = math.max(20.0, (tableWidth - 680.0) / 6.0);

              return AcademySurface(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: tableWidth),
                      child: DataTable(
                        columnSpacing: dynamicSpacing,
                        headingRowHeight: 40,
                        dataRowMinHeight: 48,
                        dataRowMaxHeight: 56,
                        headingTextStyle: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Academy.muted,
                          letterSpacing: 0.8,
                        ),
                        columns: const [
                          DataColumn(label: Text(AppStrings.week)),
                          DataColumn(label: Text(AppStrings.status)),
                          DataColumn(label: Text(AppStrings.score)),
                          DataColumn(label: Text(AppStrings.attempts)),
                          DataColumn(label: Text(AppStrings.studyDate)),
                          DataColumn(label: Text(AppStrings.videoLesson)),
                          DataColumn(label: Text(AppStrings.action)),
                        ],
                        rows: [
                          for (final week in displayedWeeks)
                            DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: week.completed
                                              ? const Color(0xFFE8F5E9)
                                              : StudentColors.surfaceMuted,
                                          borderRadius: BorderRadius.circular(
                                            7,
                                          ),
                                          border: Border.all(
                                            color: week.completed
                                                ? const Color(0xFFA5D6A7)
                                                : StudentColors.border,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${week.weekNumber}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: week.completed
                                                ? const Color(0xFF2E7D32)
                                                : Brand.navy,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Week ${week.weekNumber}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  _StatusBadge(status: week.assignmentStatus),
                                ),
                                DataCell(
                                  week.score != null
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: week.score!.percentage >= 70
                                                ? StudentColors.successSoft
                                                : StudentColors.amberWash,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color:
                                                  week.score!.percentage >= 70
                                                  ? StudentColors.successBorder
                                                  : StudentColors.amberBorder,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                week.score!.percentage >= 70
                                                    ? Icons.check_circle_rounded
                                                    : Icons
                                                          .info_outline_rounded,
                                                size: 13,
                                                color:
                                                    week.score!.percentage >= 70
                                                    ? StudentColors.live
                                                    : StudentColors.amberDark,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                '${week.score!.correct} / ${week.score!.total} (${week.score!.percentage}%)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      week.score!.percentage >=
                                                          70
                                                      ? StudentColors.liveDeep
                                                      : StudentColors
                                                            .amberBrown,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : const Text(
                                          '—',
                                          style: TextStyle(
                                            color: Academy.muted,
                                          ),
                                        ),
                                ),
                                DataCell(
                                  Text(
                                    '${week.attemptsUsed} / ${week.attemptsMax}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    week.studyDate ?? '—',
                                    style: const TextStyle(
                                      color: Academy.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  week.hasVideo &&
                                          week.videoUrl != null &&
                                          week.videoUrl!.isNotEmpty
                                      ? InkWell(
                                          onTap: () => launchUrl(
                                            Uri.parse(week.videoUrl!),
                                            webOnlyWindowName: AppStrings.blank,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Brand.navy.withValues(
                                                alpha: 0.06,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Brand.navy.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .play_circle_fill_rounded,
                                                  size: 16,
                                                  color: Brand.gold,
                                                ),
                                                SizedBox(width: 5),
                                                Text(
                                                  AppStrings.watch,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 12,
                                                    color: Brand.navy,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          '—',
                                          style: TextStyle(
                                            color: Academy.muted,
                                          ),
                                        ),
                                ),
                                DataCell(
                                  FilledButton.tonalIcon(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: Brand.navy,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => onOpenWeek(group, week),
                                    icon: const Icon(
                                      Icons.visibility_outlined,
                                      size: 14,
                                      color: Brand.gold,
                                    ),
                                    label: const Text(
                                      AppStrings.open,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 22),
        ],
      ],
    );
  }
}

class _StudentJourneyGrid extends StatelessWidget {
  const _StudentJourneyGrid({required this.group, required this.onOpenWeek});

  final LearningLevelGroupDto group;
  final void Function(LearningLevelGroupDto group, LearningWeekDto week)
  onOpenWeek;

  @override
  Widget build(BuildContext context) {
    final completedCount = group.weeks.where((w) => w.completed).length;
    final totalCount = group.weekCount > 0
        ? group.weekCount
        : (group.weeks.isNotEmpty ? group.weeks.length : 52);
    final progressFraction = totalCount > 0
        ? (completedCount / totalCount).clamp(0.0, 1.0)
        : 0.0;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level summary header
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
            border: Border.all(color: Academy.line),
            boxShadow: [
              BoxShadow(
                color: Brand.navy.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    group.level.name,
                    style: TextStyle(
                      fontSize: isMobile ? 17 : 22,
                      fontWeight: FontWeight.w800,
                      color: Academy.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (group.isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Brand.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Brand.gold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: Color(0xFF6B4D00),
                          ),
                          SizedBox(width: 3),
                          Text(
                            AppStrings.current2,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6B4D00),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '$completedCount / $totalCount (${(progressFraction * 100).toInt()}%)',
                    style: TextStyle(
                      color: Academy.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 11.5 : 13,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 8 : 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: isMobile ? 6 : 8,
                  backgroundColor: const Color(0xFFEFE9DC),
                  valueColor: const AlwaysStoppedAnimation(Brand.gold),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 10 : 16),

        // Space-friendly responsive grid of week cards
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cols = width >= 1100
                ? 4
                : width >= 780
                ? 3
                : width >= 480
                ? 2
                : 1;
            const gap = 12.0;
            final itemWidth = (width - gap * (cols - 1)) / cols;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final week in group.weeks)
                  SizedBox(
                    width: itemWidth,
                    child: _StudentWeekCard(
                      week: week,
                      onTap: () => onOpenWeek(group, week),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StudentWeekCard extends StatelessWidget {
  const _StudentWeekCard({required this.week, required this.onTap});

  final LearningWeekDto week;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = week.completed;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return AcademySurface(
      padding: EdgeInsets.all(isMobile ? 11 : 16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: completed
                      ? const Color(0xFFE8F5E9)
                      : Brand.navy.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Week ${week.weekNumber}',
                  style: TextStyle(
                    color: completed ? const Color(0xFF1B5E20) : Academy.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              _StatusBadge(status: week.assignmentStatus),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 14,
                color: Academy.muted,
              ),
              const SizedBox(width: 6),
              Text(
                '${week.attemptsUsed} / ${week.attemptsMax} attempts',
                style: const TextStyle(
                  fontSize: 12,
                  color: Academy.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (week.score != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  week.score!.percentage >= 70
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  size: 14,
                  color: week.score!.percentage >= 70
                      ? StudentColors.live
                      : StudentColors.amberDark,
                ),
                const SizedBox(width: 6),
                Text(
                  'Score: ${week.score!.correct} / ${week.score!.total} (${week.score!.percentage}%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: week.score!.percentage >= 70
                        ? StudentColors.liveDeep
                        : StudentColors.amberBrown,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          if (week.hasVideo) ...[
            const SizedBox(height: 6),
            Row(
              children: const [
                Icon(Icons.play_circle_outline, size: 14, color: Brand.navy),
                SizedBox(width: 6),
                Text(
                  AppStrings.includesVideoLesson,
                  style: TextStyle(
                    fontSize: 11,
                    color: Brand.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                completed ? AppStrings.review : AppStrings.openWeek,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: completed ? Brand.navy : const Color(0xFF8A5A00),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                size: 13,
                color: completed ? Brand.navy : const Color(0xFF8A5A00),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  const _LevelHeader({required this.group});

  final LearningLevelGroupDto group;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          group.level.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Academy.ink,
          ),
        ),
        const SizedBox(width: 10),
        if (group.isCurrent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Brand.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              AppStrings.current2,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        const Spacer(),
        Text(
          '${group.weekCount} Weeks',
          style: const TextStyle(
            color: Academy.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final completed = status == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFDDF3E4) : const Color(0xFFFFF1D6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: completed ? const Color(0xFFBBE5C8) : const Color(0xFFFFDE9E),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 12,
            color: completed
                ? const Color(0xFF1F7A46)
                : const Color(0xFF8A5A00),
          ),
          const SizedBox(width: 4),
          Text(
            completed ? AppStrings.completed : AppStrings.pending,
            style: TextStyle(
              color: completed
                  ? const Color(0xFF1F7A46)
                  : const Color(0xFF8A5A00),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileStaffWeekList extends StatelessWidget {
  const _MobileStaffWeekList({
    required this.group,
    this.weeks,
    required this.onOpenWeek,
  });

  final LearningLevelGroupDto group;
  final List<LearningWeekDto>? weeks;
  final void Function(LearningLevelGroupDto group, LearningWeekDto week)
  onOpenWeek;

  @override
  Widget build(BuildContext context) {
    final effectiveWeeks = weeks ??
        (group.weeks.toList()
          ..sort((a, b) => b.weekNumber.compareTo(a.weekNumber)));

    if (effectiveWeeks.isEmpty) {
      return const AcademySurface(
        child: Text(AppStrings.noWeeklyAssignmentsFoundForThisLevel),
      );
    }

    return Column(
      children: [
        for (final week in effectiveWeeks)
          _StaffMobileWeekCard(
            week: week,
            onOpen: () => onOpenWeek(group, week),
          ),
      ],
    );
  }
}

class _StaffMobileWeekCard extends StatelessWidget {
  const _StaffMobileWeekCard({required this.week, required this.onOpen});

  final LearningWeekDto week;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final completed = week.completed;
    final isPassing = (week.score?.percentage ?? 0) >= 70;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StudentColors.border),
        boxShadow: [
          BoxShadow(
            color: Brand.navy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Week Badge, Label, Study Date & Status Chip
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: completed
                      ? const Color(0xFFE8F5E9)
                      : StudentColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: completed
                        ? const Color(0xFFA5D6A7)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${week.weekNumber}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: completed ? const Color(0xFF2E7D32) : Brand.navy,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Week ${week.weekNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: Brand.navy,
                      ),
                    ),
                    if (week.studyDate != null)
                      Text(
                        'Study: ${week.studyDate}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Academy.muted,
                        ),
                      ),
                  ],
                ),
              ),
              _StatusBadge(status: week.assignmentStatus),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: StudentColors.surfaceMuted),
          const SizedBox(height: 10),

          // Row 2: Score & Attempts
          Row(
            children: [
              Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: week.score != null
                          ? (isPassing
                                ? StudentColors.successSoft
                                : StudentColors.amberWash)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: week.score != null
                            ? (isPassing
                                  ? StudentColors.successBorder
                                  : StudentColors.amberBorder)
                            : StudentColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          week.score != null
                              ? (isPassing
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline_rounded)
                              : Icons.quiz_outlined,
                          size: 14,
                          color: week.score != null
                              ? (isPassing
                                    ? StudentColors.live
                                    : StudentColors.amberDark)
                              : StudentColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            week.score != null
                                ? '${week.score!.correct} / ${week.score!.total} (${week.score!.percentage}%)'
                                : AppStrings.noScoreYet,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: week.score != null
                                  ? (isPassing
                                        ? StudentColors.liveDeep
                                        : StudentColors.amberBrown)
                                  : StudentColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // Attempts badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: StudentColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      size: 14,
                      color: Academy.muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${week.attemptsUsed}/${week.attemptsMax} attempts',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: StudentColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 3: Action Buttons (Watch Video & Open Result)
          Row(
            children: [
              if (week.hasVideo &&
                  week.videoUrl != null &&
                  week.videoUrl!.isNotEmpty) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(
                        color: Brand.navy.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse(week.videoUrl!),
                      webOnlyWindowName: AppStrings.blank,
                    ),
                    icon: const Icon(
                      Icons.play_circle_fill_rounded,
                      size: 15,
                      color: Brand.gold,
                    ),
                    label: const Text(
                      AppStrings.watchVideo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Brand.navy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: Brand.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onOpen,
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 15,
                    color: Brand.gold,
                  ),
                  label: const Text(
                    AppStrings.openResult,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
