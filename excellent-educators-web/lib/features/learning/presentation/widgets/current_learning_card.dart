import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class CurrentLearningCard extends StatelessWidget {
  const CurrentLearningCard({super.key, required this.dashboard});

  final LearningDashboardDto dashboard;

  @override
  Widget build(BuildContext context) {
    final levelName = dashboard.currentLevel?.name ?? AppStrings.yourLevel;
    final week = dashboard.currentWeek;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return AcademySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcademyLabel(AppStrings.yourLearningJourney),
          SizedBox(height: isMobile ? 6 : 10),
          Text(
            levelName,
            style: TextStyle(
              fontSize: isMobile ? 18 : 26,
              fontWeight: FontWeight.w800,
              color: Academy.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dashboard.assignmentPending
                ? 'This week · Week $week'
                : 'Week $week completed',
            style: TextStyle(
              fontSize: isMobile ? 14 : 18,
              fontWeight: FontWeight.w700,
              color: Brand.navy,
            ),
          ),
          SizedBox(height: isMobile ? 6 : 12),
          Text(
            dashboard.ctaLabel,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 13 : 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Progress: ${dashboard.completedWeeks} of ${dashboard.totalWeeks} weeks',
            style: TextStyle(
              color: Academy.muted,
              fontSize: isMobile ? 12 : 13.5,
            ),
          ),
          SizedBox(height: isMobile ? 10 : 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (dashboard.week?.videoUrl != null)
                AcademyButton(
                  label: 'Watch Week $week video',
                  icon: Icons.play_circle_outline,
                  outlined: true,
                  onPressed: () => launchUrl(
                    Uri.parse(dashboard.week!.videoUrl!),
                    webOnlyWindowName: AppStrings.blank,
                  ),
                ),
              AcademyButton(
                label: dashboard.assignmentPending
                    ? AppStrings.completeAssignment
                    : AppStrings.viewWeek,
                icon: dashboard.assignmentPending
                    ? Icons.edit_note_outlined
                    : Icons.check_circle_outline,
                onPressed: () {
                  final journeyId = dashboard.week?.journeyId;
                  if (journeyId == null || journeyId.isEmpty) {
                    context.go(RoutePaths.studentJournal);
                    return;
                  }
                  context.go(RoutePaths.studentJournalWeekFor(journeyId, week));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
