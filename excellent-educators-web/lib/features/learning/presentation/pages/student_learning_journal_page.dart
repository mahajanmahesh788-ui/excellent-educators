import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:excellent_educators_web/features/learning/presentation/widgets/learning_journal_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class StudentLearningJournalPage extends ConsumerWidget {
  const StudentLearningJournalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(studentLearningJournalProvider);
    return StudentScaffold(
      title: AppStrings.learningJourney2,
      body: journal.when(
        loading: () => const AcademySkeleton(height: 280),
        error: (_, _) => AcademyError(
          onRetry: () => ref.invalidate(studentLearningJournalProvider),
        ),
        data: (data) {
          final current = data.levels
              .where((level) => level.isCurrent)
              .firstOrNull;
          final isMobile = MediaQuery.sizeOf(context).width < 600;
          return ListView(
            padding: EdgeInsets.only(bottom: isMobile ? 20 : 40),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AcademyLabel(AppStrings.learningJourney),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.myLearningJourney,
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 28,
                      fontWeight: FontWeight.w800,
                      color: Academy.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.yourJourneyIsTrackedByLevelAndWeekCompleteWeekly,
                    style: TextStyle(
                      fontSize: isMobile ? 12.5 : 14,
                      color: Academy.muted,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 10 : 18),
              if (current != null)
                JourneyRibbon(
                  levelName: current.level.name,
                  currentWeek: current.weeks.isEmpty
                      ? 1
                      : current.weeks.last.weekNumber,
                  weekCount: current.weekCount,
                ),
              SizedBox(height: isMobile ? 12 : 22),
              LearningJournalTable(
                journal: data,
                staffView: false,
                onOpenWeek: (group, week) {
                  context.go(
                    RoutePaths.studentJournalWeekFor(
                      group.journeyId,
                      week.weekNumber,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
