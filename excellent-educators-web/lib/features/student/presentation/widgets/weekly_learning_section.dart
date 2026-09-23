import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';

class WeeklyLearningSection extends StatelessWidget {
  const WeeklyLearningSection({super.key, required this.dashboard});

  final LearningDashboardDto dashboard;

  @override
  Widget build(BuildContext context) {
    final week = dashboard.week;
    final weekNumber = dashboard.currentWeek;
    final levelName = dashboard.currentLevel?.name ?? 'Your Level';
    final hasVideo = (week?.videoUrl ?? '').isNotEmpty;
    final isAssignmentCompleted = !(dashboard.assignmentPending);
    final questionCount = week?.questions.length ?? 0;
    final score = week?.score;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return StudentCard(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: StudentColors.skyLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: StudentColors.skyDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THIS WEEK’S LEARNING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: StudentColors.skyDark,
                        ),
                      ),
                      Text(
                        '$levelName · Week $weekNumber Activities',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: StudentColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isAssignmentCompleted
                      ? StudentColors.emeraldLight
                      : StudentColors.amberLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAssignmentCompleted ? 'Completed' : 'Action Required',
                  style: TextStyle(
                    color: isAssignmentCompleted
                        ? StudentColors.emeraldDark
                        : StudentColors.amberDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Activity 1: Weekly Video Lesson
          _LearningActivityTile(
            icon: Icons.smart_display_rounded,
            iconBg: StudentColors.skyLight,
            iconColor: StudentColors.skyDark,
            title: 'Weekly Concept Video',
            subtitle: hasVideo
                ? 'Watch Week $weekNumber interactive video lecture'
                : 'Video material is being prepared for this week',
            badge: hasVideo ? 'Ready to Watch' : 'Upcoming',
            badgeColor: hasVideo
                ? StudentColors.skyDark
                : StudentColors.textMuted,
            badgeBg: hasVideo
                ? StudentColors.skyLight
                : StudentColors.surfaceMuted,
            actionLabel: 'Watch Video',
            actionIcon: Icons.play_arrow_rounded,
            buttonFilled: hasVideo,
            onAction: hasVideo
                ? () => launchUrl(
                    Uri.parse(week!.videoUrl!),
                    webOnlyWindowName: AppStrings.blank,
                  )
                : null,
          ),

          const SizedBox(height: 12),

          // Activity 2: Aptitude Challenge
          _LearningActivityTile(
            icon: Icons.psychology_rounded,
            iconBg: isAssignmentCompleted
                ? StudentColors.emeraldLight
                : StudentColors.amberLight,
            iconColor: isAssignmentCompleted
                ? StudentColors.emeraldDark
                : StudentColors.amberDark,
            title: 'Weekly Aptitude & Practice Challenge',
            subtitle: isAssignmentCompleted
                ? (score != null
                      ? 'Completed with score: ${score.display} (${score.percentage}%)'
                      : 'Challenge successfully submitted')
                : (questionCount > 0
                      ? '$questionCount questions • ${week?.attemptsUsed ?? 0}/${week?.attemptsMax ?? 2} attempts used'
                      : 'Complete this week\'s assessment to unlock feedback'),
            badge: isAssignmentCompleted
                ? 'Score: ${score?.display ?? "Submitted"}'
                : 'Pending Challenge',
            badgeColor: isAssignmentCompleted
                ? StudentColors.emeraldDark
                : StudentColors.amberDark,
            badgeBg: isAssignmentCompleted
                ? StudentColors.emeraldLight
                : StudentColors.amberLight,
            actionLabel: isAssignmentCompleted
                ? 'Review Score'
                : 'Start Challenge',
            actionIcon: isAssignmentCompleted
                ? Icons.check_circle_outline_rounded
                : Icons.edit_note_rounded,
            buttonFilled: !isAssignmentCompleted,
            onAction: () {
              final journeyId = week?.journeyId;
              if (journeyId != null && journeyId.isNotEmpty) {
                context.go(
                  RoutePaths.studentJournalWeekFor(journeyId, weekNumber),
                );
              } else {
                context.go(RoutePaths.studentJournal);
              }
            },
          ),

          const SizedBox(height: 12),

          // Activity 3: Weekly Reflection Journal
          _LearningActivityTile(
            icon: Icons.auto_stories_rounded,
            iconBg: StudentColors.violetLight,
            iconColor: StudentColors.violetDark,
            title: 'Learning Journal & Study Notes',
            subtitle:
                'Log your insights, homework questions, and study takeaways',
            badge: 'Journal Entry',
            badgeColor: StudentColors.violetDark,
            badgeBg: StudentColors.violetLight,
            actionLabel: 'Open Journal',
            actionIcon: Icons.arrow_forward_rounded,
            buttonFilled: false,
            onAction: () {
              final journeyId = week?.journeyId;
              if (journeyId != null && journeyId.isNotEmpty) {
                context.go(
                  RoutePaths.studentJournalWeekFor(journeyId, weekNumber),
                );
              } else {
                context.go(RoutePaths.studentJournal);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _LearningActivityTile extends StatelessWidget {
  const _LearningActivityTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
    required this.actionLabel,
    required this.actionIcon,
    required this.buttonFilled,
    required this.onAction,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;
  final String actionLabel;
  final IconData actionIcon;
  final bool buttonFilled;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StudentColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
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
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: StudentColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onAction != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: buttonFilled
                  ? FilledButton.icon(
                      onPressed: onAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: iconColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(actionIcon, size: 16),
                      label: Text(
                        actionLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: onAction,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: iconColor,
                        side: BorderSide(
                          color: iconColor.withValues(alpha: 0.4),
                        ),
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(actionIcon, size: 16),
                      label: Text(
                        actionLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
