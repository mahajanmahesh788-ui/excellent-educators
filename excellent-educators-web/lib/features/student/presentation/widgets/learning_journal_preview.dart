import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';

class LearningJournalPreviewWidget extends StatelessWidget {
  const LearningJournalPreviewWidget({super.key, this.learning, this.journal});

  final LearningDashboardDto? learning;
  final LearningJournalDto? journal;

  @override
  Widget build(BuildContext context) {
    final currentWeek = learning?.currentWeek ?? 0;
    final completedWeeks = learning?.completedWeeks ?? _completedFromJournal(journal);
    final totalWeeks = learning?.totalWeeks ?? 52;
    final week = learning?.week;
    final isCurrentDone = week?.completed ?? false;
    final recentCompleted = _recentCompletedWeeks(journal, limit: 4);
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final journeyId = week?.journeyId.isNotEmpty == true
        ? week!.journeyId
        : _currentJourneyId(journal);

    final summary = completedWeeks > 0
        ? 'You have completed $completedWeeks of $totalWeeks weeks'
            '${currentWeek > 0 ? '. Currently on Week $currentWeek${isCurrentDone ? ' (done)' : ''}.' : '.'}'
        : currentWeek > 0
            ? 'Week $currentWeek is ready. Open your journal to watch the video and submit answers.'
            : 'Your weekly learning journal will appear here once your level journey starts.';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: StudentColors.surfaceWarm,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StudentColors.borderWarm, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: StudentColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 28,
            child: Container(
              width: 22,
              height: 38,
              decoration: const BoxDecoration(
                color: StudentColors.bookmark,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 18 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: StudentColors.forestLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history_edu_rounded,
                        size: 18,
                        color: StudentColors.forest,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MY LEARNING JOURNAL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: StudentColors.forest,
                            ),
                          ),
                          Text(
                            'Weekly Insights & Study Reflection',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: StudentColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: StudentColors.borderWarm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              completedWeeks > 0
                                  ? '$completedWeeks week${completedWeeks == 1 ? '' : 's'} completed'
                                  : currentWeek > 0
                                      ? 'Week $currentWeek'
                                      : 'No weeks unlocked yet',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: StudentColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: completedWeeks > 0
                                  ? StudentColors.successSoft
                                  : StudentColors.amberLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              completedWeeks > 0
                                  ? 'In progress'
                                  : 'Not started',
                              style: TextStyle(
                                color: completedWeeks > 0
                                    ? StudentColors.success
                                    : StudentColors.amberDeep,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        summary,
                        style: const TextStyle(
                          color: StudentColors.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      if (recentCompleted.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final item in recentCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: StudentColors.forestLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: StudentColors.forestBorder,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: StudentColors.forest,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Week ${item.weekNumber}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: StudentColors.forest,
                                      ),
                                    ),
                                    if (item.scoreDisplay != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        item.scoreDisplay!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                          color: StudentColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        completedWeeks > 0
                            ? 'View all completed weekly logs'
                            : 'Start this week’s learning journal',
                        style: const TextStyle(
                          color: StudentColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        if (journeyId != null &&
                            journeyId.isNotEmpty &&
                            currentWeek > 0) {
                          context.go(
                            RoutePaths.studentJournalWeekFor(
                              journeyId,
                              currentWeek,
                            ),
                          );
                        } else {
                          context.go(RoutePaths.studentJournal);
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: StudentColors.forest,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      icon: Icon(
                        completedWeeks > 0
                            ? Icons.menu_book_rounded
                            : Icons.edit_note_rounded,
                        size: 18,
                      ),
                      label: Text(
                        completedWeeks > 0 ? 'Open Journal' : 'Write Reflection',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static int _completedFromJournal(LearningJournalDto? journal) {
    if (journal == null) return 0;
    var count = 0;
    for (final level in journal.levels) {
      for (final week in level.weeks) {
        if (week.completed) count++;
      }
    }
    return count;
  }

  static String? _currentJourneyId(LearningJournalDto? journal) {
    if (journal == null) return null;
    for (final level in journal.levels) {
      if (level.isCurrent && level.journeyId.isNotEmpty) {
        return level.journeyId;
      }
    }
    return journal.levels.isNotEmpty ? journal.levels.first.journeyId : null;
  }

  static List<({int weekNumber, String? scoreDisplay})> _recentCompletedWeeks(
    LearningJournalDto? journal, {
    required int limit,
  }) {
    if (journal == null) return const [];
    final completed = <({int weekNumber, String? scoreDisplay})>[];
    for (final level in journal.levels) {
      if (!level.isCurrent && journal.levels.any((l) => l.isCurrent)) {
        continue;
      }
      for (final week in level.weeks) {
        if (!week.completed) continue;
        completed.add((
          weekNumber: week.weekNumber,
          scoreDisplay: week.score?.display,
        ));
      }
    }
    if (completed.isEmpty) {
      for (final level in journal.levels) {
        for (final week in level.weeks) {
          if (!week.completed) continue;
          completed.add((
            weekNumber: week.weekNumber,
            scoreDisplay: week.score?.display,
          ));
        }
      }
    }
    completed.sort((a, b) => b.weekNumber.compareTo(a.weekNumber));
    return completed.take(limit).toList();
  }
}
