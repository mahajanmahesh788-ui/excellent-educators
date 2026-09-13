import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_dashboard.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_journey.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentTeachersPage extends ConsumerWidget {
  const StudentTeachersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentProfileProvider);
    final eligibility = ref.watch(studentEligibilityProvider);

    return StudentScaffold(
      title: 'Teachers',
      body: profile.when(
        skipLoadingOnReload: true,
        loading: () => const AcademySkeleton(height: 280),
        error: (_, _) => AcademyError(onRetry: () => ref.invalidate(studentProfileProvider)),
        data: (student) {
          final levelLabel = student.level != null && !student.level!.isEmpty ? student.level!.label : 'Your level';
          final type = eligibility.maybeWhen(
            data: (value) => value.canBookIntroduction
                ? 'introduction_call'
                : value.canBookMasterClass
                    ? 'master_class'
                    : null,
            orElse: () => null,
          );
          return ListView(
            padding: const EdgeInsets.only(bottom: 48),
            children: [
              const Text(
                'Your teachers',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Academy.ink),
              ),
              const SizedBox(height: 8),
              const Text(
                'These Master Teachers guide your level. Book a session whenever you are ready.',
                style: TextStyle(color: Academy.muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              TeacherGrid(
                teachers: student.masterTeachers,
                levelLabel: levelLabel,
                bookLabel: bookingActionLabel(type),
                onBook: (_) => context.go(
                  type == null ? RoutePaths.studentBookNew : '${RoutePaths.studentBookNew}?type=$type',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
