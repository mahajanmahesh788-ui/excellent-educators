import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/master_teacher_students_filter.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/master_teacher_progress_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MasterTeacherDashboardPage extends ConsumerWidget {
  const MasterTeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(masterTeacherDashboardProvider);

    return AppScaffold(
      title: 'Dashboard',
      body: AsyncBody(
        value: dashboard,
        onRetry: () => ref.invalidate(masterTeacherDashboardProvider),
        builder: (data) {
          return ListView(
            children: [
              MasterTeacherProgressPanel(
                data: data,
                pendingStudentsTitle: 'Rate these students',
                onNotRatedTap: () => _openNotRatedStudents(context, ref),
                onAssessmentPendingTap: () => context.go(RoutePaths.masterTeacherStudents),
                onPendingStudentTap: (student) => context.go(RoutePaths.masterTeacherStudentFor(student.id)),
                onRateStudent: (student) => context.go(RoutePaths.masterTeacherFeedbackNewFor(student.id)),
                onEditStudentRating: (student) {
                  final id = student.monthlyFeedbackId;
                  if (id == null || id.isEmpty) {
                    return;
                  }
                  context.go(RoutePaths.masterTeacherFeedbackEditFor(student.id, id));
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _openNotRatedStudents(BuildContext context, WidgetRef ref) {
    ref.read(masterTeacherStudentsFilterProvider.notifier).state = MasterTeacherStudentsFilter.currentMonth().copyWith(
          rated: MasterTeacherStudentsRatedFilter.notRated,
        );
    context.go(RoutePaths.masterTeacherStudents);
  }
}
