import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:excellent_educators_web/features/learning/presentation/widgets/learning_journal_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentLearningJournalPage extends ConsumerWidget {
  const StudentLearningJournalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(studentLearningJournalProvider);
    return StudentScaffold(
      title: 'Learning Journey',
      body: journal.when(
        loading: () => const AcademySkeleton(height: 280),
        error: (_, _) => AcademyError(onRetry: () => ref.invalidate(studentLearningJournalProvider)),
        data: (data) {
          final current = data.levels.where((level) => level.isCurrent).firstOrNull;
          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AcademyLabel('LEARNING JOURNEY'),
                  SizedBox(height: 4),
                  Text(
                    'My Learning Journey',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Academy.ink, letterSpacing: -0.5),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your journey is tracked by level and week — complete weekly assignments to level up.',
                    style: TextStyle(fontSize: 14, color: Academy.muted),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (current != null)
                JourneyRibbon(
                  levelName: current.level.name,
                  currentWeek: current.weeks.isEmpty ? 1 : current.weeks.last.weekNumber,
                  weekCount: current.weekCount,
                ),
              const SizedBox(height: 22),
              LearningJournalTable(
                journal: data,
                staffView: false,
                onOpenWeek: (group, week) {
                  context.go(RoutePaths.studentJournalWeekFor(group.journeyId, week.weekNumber));
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
