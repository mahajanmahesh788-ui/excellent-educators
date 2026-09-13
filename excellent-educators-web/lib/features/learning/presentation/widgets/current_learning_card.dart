import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class CurrentLearningCard extends StatelessWidget {
  const CurrentLearningCard({super.key, required this.dashboard});

  final LearningDashboardDto dashboard;

  @override
  Widget build(BuildContext context) {
    final levelName = dashboard.currentLevel?.name ?? 'Your level';
    final week = dashboard.currentWeek;
    return AcademySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcademyLabel('Your learning journey'),
          const SizedBox(height: 10),
          Text(levelName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Academy.ink)),
          const SizedBox(height: 4),
          Text(
            dashboard.assignmentPending ? 'This week · Week $week' : 'Week $week completed',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Brand.navy),
          ),
          const SizedBox(height: 12),
          Text(dashboard.ctaLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Progress: ${dashboard.completedWeeks} of ${dashboard.totalWeeks} weeks', style: const TextStyle(color: Academy.muted)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (dashboard.week?.videoUrl != null)
                AcademyButton(
                  label: 'Watch Week $week video',
                  icon: Icons.play_circle_outline,
                  outlined: true,
                  onPressed: () => launchUrl(Uri.parse(dashboard.week!.videoUrl!), webOnlyWindowName: '_blank'),
                ),
              AcademyButton(
                label: dashboard.assignmentPending ? 'Complete assignment' : 'View week',
                icon: dashboard.assignmentPending ? Icons.edit_note_outlined : Icons.check_circle_outline,
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
