import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/master_teacher_students_filter.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_cards.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/assessment_result_view.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/compact_assessment_card.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/student_read_only_ratings_section.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_ui.dart';
import 'package:excellent_educators_web/features/requests/presentation/widgets/request_student_removal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeacherBatchesPage extends ConsumerWidget {
  const TeacherBatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(teacherBatchesProvider);

    return AppScaffold(
      title: 'My batches',
      body: AsyncBody(
        value: batches,
        onRetry: () => ref.invalidate(teacherBatchesProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyHint(
              'No batches assigned',
              icon: EmptyIcons.batches,
              subtitle: 'Your admin will assign you to a batch when ready.',
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final batch = items[index];
              return BatchCard(
                batch: batch,
                onTap: () => context.go(RoutePaths.teacherBatch(batch.id)),
              );
            },
          );
        },
      ),
    );
  }
}

class TeacherBatchStudentsPage extends ConsumerWidget {
  const TeacherBatchStudentsPage({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(teacherBatchStudentsProvider(batchId));

    return AppScaffold(
      title: 'Batch students',
      backTo: RoutePaths.teacherBatches,
      actions: [
        TextButton.icon(
          onPressed: () => context.go(RoutePaths.teacherAssessmentsFor(batchId)),
          icon: const Icon(Icons.assignment_outlined, color: Colors.white, size: 18),
          label: const Text('Batch assessments', style: TextStyle(color: Colors.white)),
        ),
      ],
      body: AsyncBody(
        value: students,
        onRetry: () => ref.invalidate(teacherBatchStudentsProvider(batchId)),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyHint(
              'No students in this batch',
              icon: EmptyIcons.students,
              subtitle: 'Students will appear here once enrolled by admin.',
            );
          }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final student = items[index];
                    return StudentCard(
                      student: student,
                      highlightOverallRating: true,
                      onTap: () => context.go(RoutePaths.teacherStudentResultsFor(student.id)),
                      action: RequestStudentRemovalIconButton(
                        studentId: student.id,
                        studentName: student.fullName,
                        studentCode: student.studentCode,
                        batchId: batchId,
                        batchName: student.batch?.label,
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}

class MasterTeacherStudentsPage extends ConsumerWidget {
  const MasterTeacherStudentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(masterTeacherStudentsFilterProvider);
    final students = ref.watch(masterTeacherStudentsProvider);

    return AppScaffold(
      title: 'My students',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MasterTeacherStudentsFilterBar(
            filter: filter,
            onFilterChanged: (next) => ref.read(masterTeacherStudentsFilterProvider.notifier).state = next,
          ),
          Expanded(
            child: AsyncBody(
              value: students,
              onRetry: () => ref.invalidate(masterTeacherStudentsProvider),
              builder: (items) {
                if (items.isEmpty) {
                  final filtered = filter.rated != MasterTeacherStudentsRatedFilter.all;
                  return EmptyHint(
                    filtered ? 'No students match these filters' : 'No students assigned',
                    icon: EmptyIcons.students,
                    subtitle: filtered
                        ? 'Try another month or change the rated filter.'
                        : 'Students will appear here when admin assigns them to you.',
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) => StudentCard(
                    student: items[index],
                    highlightOverallRating: true,
                    showMonthRatingStatus: true,
                    onTap: () => context.go(RoutePaths.masterTeacherStudentFor(items[index].id)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentProfileProvider);

    return StudentScaffold(
      title: 'My profile',
      body: AsyncBody(
        value: profile,
        onRetry: () => ref.invalidate(studentProfileProvider),
        builder: (student) {
          return ListView(
            children: [
              StudentHeroCard(
                title: student.fullName,
                subtitle: student.email,
                trailing: CircleAvatar(
                  radius: 28,
                  backgroundColor: Brand.gold.withValues(alpha: 0.22),
                  child: Text(
                    student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Brand.gold, fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    StudentStatChip(
                      icon: Icons.badge_rounded,
                      label: 'Student ID',
                      value: student.studentCode,
                    ),
                    StudentStatChip(
                      icon: Icons.school_rounded,
                      label: 'Career Compass',
                      value: student.careerCompassLevel?.displayName ?? '—',
                      accent: const Color(0xFF4E8BC9),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StudentSectionCard(
                icon: Icons.contact_mail_rounded,
                title: 'Contact details',
                child: Column(
                  children: [
                    _ProfileRow(icon: Icons.email_outlined, label: 'Email', value: student.email),
                    _ProfileRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: student.phone.isEmpty ? '—' : student.phone,
                    ),
                    if (student.whatsappNumber != null && student.whatsappNumber!.isNotEmpty)
                      _ProfileRow(
                        icon: Icons.chat_outlined,
                        label: 'WhatsApp',
                        value: student.whatsappNumber!,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              StudentSectionCard(
                icon: Icons.hub_rounded,
                title: 'Academic network',
                child: Column(
                  children: [
                    _ProfileRow(icon: Icons.groups_rounded, label: 'Batch', value: student.batch?.label ?? 'Not assigned'),
                    _ProfileRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Common Teacher',
                      value: student.commonTeacher?.label ?? 'Not assigned',
                    ),
                    _ProfileRow(
                      icon: Icons.psychology_alt_rounded,
                      label: 'Master Teacher',
                      value: student.masterTeacher?.label ?? 'Not assigned',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              StudentSectionCard(
                icon: Icons.shield_outlined,
                title: 'Account security',
                child: StudentQuickLink(
                  label: 'Change password',
                  icon: Icons.lock_outline_rounded,
                  onTap: () => context.go(RoutePaths.changePassword),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class TeacherProfilePage extends ConsumerWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(teacherProfileProvider);

    return AppScaffold(
      title: 'My profile',
      body: AsyncBody(
        value: profile,
        onRetry: () => ref.invalidate(teacherProfileProvider),
        builder: (teacher) {
          final roles = <Widget>[
            if (teacher.isCommonTeacher)
              const _TeacherRoleChip(label: 'Common Teacher', background: Color(0xFFFBF6EA), color: Brand.goldDark),
            if (teacher.isMasterTeacher)
              const _TeacherRoleChip(label: 'Master Teacher', background: Color(0xFFE8EAF6), color: Color(0xFF3949AB)),
          ];

          return ListView(
            children: [
              StudentHeroCard(
                title: teacher.fullName,
                subtitle: teacher.email,
                trailing: CircleAvatar(
                  radius: 28,
                  backgroundColor: Brand.gold.withValues(alpha: 0.22),
                  child: Text(
                    teacher.fullName.isNotEmpty ? teacher.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Brand.gold, fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...roles,
                    if (teacher.employeeCode != null && teacher.employeeCode!.isNotEmpty)
                      StudentStatChip(
                        icon: Icons.badge_rounded,
                        label: 'Employee code',
                        value: teacher.employeeCode!,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StudentSectionCard(
                icon: Icons.contact_mail_rounded,
                title: 'Contact details',
                child: Column(
                  children: [
                    _ProfileRow(icon: Icons.email_outlined, label: 'Email', value: teacher.email),
                    if (teacher.createdAt != null)
                      _ProfileRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Registered',
                        value: formatDisplayDateTime(teacher.createdAt),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              StudentSectionCard(
                icon: Icons.work_outline_rounded,
                title: 'Assignments',
                child: Column(
                  children: [
                    if (teacher.isCommonTeacher)
                      _ProfileRow(
                        icon: Icons.groups_rounded,
                        label: 'Active batches',
                        value: '${teacher.activeBatchCount ?? 0}',
                      ),
                    if (teacher.isMasterTeacher)
                      _ProfileRow(
                        icon: Icons.psychology_alt_rounded,
                        label: 'Assigned students',
                        value: '${teacher.activeMenteeCount ?? 0}',
                      ),
                    if (teacher.isCommonTeacher && teacher.careerCompassLevels.isNotEmpty)
                      _ProfileRow(
                        icon: Icons.school_rounded,
                        label: 'Career Compass levels',
                        value: teacher.levelsLabel,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              StudentSectionCard(
                icon: Icons.shield_outlined,
                title: 'Account security',
                child: StudentQuickLink(
                  label: 'Change password',
                  icon: Icons.lock_outline_rounded,
                  onTap: () => context.go(RoutePaths.changePassword),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _TeacherRoleChip extends StatelessWidget {
  const _TeacherRoleChip({
    required this.label,
    required this.background,
    required this.color,
  });

  final String label;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Brand.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Brand.goldDark, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Brand.muted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TeacherStudentResultsPage extends ConsumerWidget {
  const TeacherStudentResultsPage({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(teacherStudentProvider(studentId));
    final results = ref.watch(teacherStudentResultsProvider(studentId));

    return AppScaffold(
      title: 'Student profile',
      backTo: RoutePaths.teacherBatches,
      body: AsyncBody(
        value: student,
        onRetry: () => ref.invalidate(teacherStudentProvider(studentId)),
        builder: (studentData) {
          return ListView(
            children: [
              StudentCard(student: studentData, highlightOverallRating: true),
              const SizedBox(height: 16),
              Text(
                'Aptitude interests (reference only)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Compact view of aptitude results. Monthly development ratings are shown below.',
                style: TextStyle(color: Brand.muted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              AsyncBody(
                value: results,
                onRetry: () => ref.invalidate(teacherStudentResultsProvider(studentId)),
                builder: (items) {
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No aptitude assessment submitted yet.',
                        style: TextStyle(color: Brand.muted.withValues(alpha: 0.9), fontSize: 13),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final result in items) ...[
                        CompactAssessmentCard(result: result),
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              StudentRatingsSection(
                studentId: studentId,
                audience: StudentRatingsAudience.commonTeacher,
                student: studentData,
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class AdminStudentResultsPage extends ConsumerWidget {
  const AdminStudentResultsPage({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(adminStudentResultsProvider(studentId));

    return AppScaffold(
      title: 'Aptitude results',
      backTo: RoutePaths.adminStudent(studentId),
      body: AsyncBody(
        value: results,
        onRetry: () => ref.invalidate(adminStudentResultsProvider(studentId)),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyHint(
              'Aptitude not submitted',
              icon: EmptyIcons.assessments,
              subtitle: 'This student has not completed the aptitude assessment yet.',
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) => AssessmentResultView(result: items[index]),
          );
        },
      ),
    );
  }
}
