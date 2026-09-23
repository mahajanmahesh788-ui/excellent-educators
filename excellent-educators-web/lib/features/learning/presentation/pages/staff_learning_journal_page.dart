import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:excellent_educators_web/features/learning/presentation/widgets/learning_journal_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class StaffLearningJournalPage extends ConsumerWidget {
  const StaffLearningJournalPage({
    super.key,
    required this.studentId,
    required this.masterTeacher,
  });

  final String studentId;
  final bool masterTeacher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = masterTeacher
        ? ref.watch(masterTeacherLearningJournalProvider(studentId))
        : ref.watch(adminLearningJournalProvider(studentId));

    return AppScaffold(
      title: AppStrings.learningJournal,
      backTo: masterTeacher
          ? RoutePaths.masterTeacherStudentFor(studentId)
          : RoutePaths.adminStudent(studentId),
      body: AsyncBody(
        value: journal,
        onRetry: () {
          if (masterTeacher) {
            ref.invalidate(masterTeacherLearningJournalProvider(studentId));
          } else {
            ref.invalidate(adminLearningJournalProvider(studentId));
          }
        },
        builder: (data) => ListView(
          children: [
            if (data.studentName != null)
              Text(
                data.studentName!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (data.currentLevelName != null)
              Text('Current level: ${data.currentLevelName}'),
            const SizedBox(height: 16),
            LearningJournalTable(
              journal: data,
              staffView: true,
              onOpenWeek: (group, week) {
                final path = masterTeacher
                    ? RoutePaths.masterTeacherStudentWeekFor(
                        studentId,
                        group.journeyId,
                        week.weekNumber,
                      )
                    : RoutePaths.adminStudentWeekFor(
                        studentId,
                        group.journeyId,
                        week.weekNumber,
                      );
                context.go(path);
              },
            ),
          ],
        ),
      ),
    );
  }
}
