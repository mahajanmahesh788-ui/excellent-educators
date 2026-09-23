import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/master_teacher_students_filter.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_cards.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/mentor_profile_editor.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/mentor_profile_view.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/assessment_result_view.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/compact_assessment_card.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/student_read_only_ratings_section.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_ui.dart';
import 'package:excellent_educators_web/features/requests/presentation/widgets/request_student_removal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class TeacherBatchesPage extends ConsumerWidget {
  const TeacherBatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(teacherBatchesProvider);

    return AppScaffold(
      title: AppStrings.myBatches,
      body: AsyncBody(
        value: batches,
        onRetry: () => ref.invalidate(teacherBatchesProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyHint(
              AppStrings.noBatchesAssigned,
              icon: EmptyIcons.batches,
              subtitle: AppStrings.yourAdminWillAssignYouToABatchWhenReady,
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
      title: AppStrings.batchStudents,
      backTo: RoutePaths.teacherBatches,
      actions: [
        TextButton.icon(
          onPressed: () =>
              context.go(RoutePaths.teacherAssessmentsFor(batchId)),
          icon: const Icon(
            Icons.assignment_outlined,
            color: Colors.white,
            size: 18,
          ),
          label: const Text(
            AppStrings.batchAssessments,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
      body: AsyncBody(
        value: students,
        onRetry: () => ref.invalidate(teacherBatchStudentsProvider(batchId)),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyHint(
              AppStrings.noStudentsInThisBatch,
              icon: EmptyIcons.students,
              subtitle: AppStrings.studentsWillAppearHereOnceEnrolledByAdmin,
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
                onTap: () =>
                    context.go(RoutePaths.teacherStudentResultsFor(student.id)),
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
      title: AppStrings.myStudents,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MasterTeacherStudentsFilterBar(
            filter: filter,
            levels: students.asData?.value.levels ?? const [],
            onFilterChanged: (next) =>
                ref.read(masterTeacherStudentsFilterProvider.notifier).state =
                    next,
          ),
          Expanded(
            child: AsyncBody(
              value: students,
              onRetry: () => ref.invalidate(masterTeacherStudentsProvider),
              builder: (roster) {
                final items = roster.students;
                if (items.isEmpty) {
                  final filtered =
                      filter.rated != MasterTeacherStudentsRatedFilter.all ||
                      filter.levelId.isNotEmpty ||
                      filter.batchId.isNotEmpty;
                  return EmptyHint(
                    filtered
                        ? AppStrings.noStudentsMatchTheseFilters
                        : AppStrings.noStudentsAssigned,
                    icon: EmptyIcons.students,
                    subtitle: filtered
                        ? AppStrings.tryAnotherLevelBatchMonthOrRatedFilter
                        : AppStrings
                              .studentsWillAppearHereWhenAdminAssignsYouToTheir,
                  );
                }
                return ListView(
                  children: [..._groupedStudentTiles(context, items)],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _groupedStudentTiles(
  BuildContext context,
  List<StudentDto> items,
) {
  final groups = <String, List<StudentDto>>{};
  for (final student in items) {
    final level = student.level != null && !student.level!.isEmpty
        ? student.level!.label
        : AppStrings.unassignedLevel;
    final batch = student.batch != null && !student.batch!.isEmpty
        ? student.batch!.label
        : AppStrings.noBatch;
    groups.putIfAbsent('$level|$batch', () => []).add(student);
  }
  final keys = groups.keys.toList()..sort();
  final widgets = <Widget>[];
  String? lastLevel;
  for (final key in keys) {
    final separator = key.indexOf('|');
    final level = key.substring(0, separator);
    final batch = key.substring(separator + 1);
    if (level != lastLevel) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: lastLevel == null ? 0 : 16, bottom: 8),
          child: Text(
            level,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Brand.navy,
            ),
          ),
        ),
      );
      lastLevel = level;
    }
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          batch,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Brand.muted,
          ),
        ),
      ),
    );
    for (final student in groups[key]!) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: StudentCard(
            student: student,
            highlightOverallRating: true,
            onTap: () =>
                context.go(RoutePaths.masterTeacherStudentFor(student.id)),
            action:
                student.canEditRatingThisMonth &&
                    student.monthlyFeedbackId != null
                ? TextButton(
                    onPressed: () => context.go(
                      RoutePaths.masterTeacherFeedbackEditFor(
                        student.id,
                        student.monthlyFeedbackId!,
                      ),
                    ),
                    child: const Text(AppStrings.editRating),
                  )
                : student.canRateThisMonth
                ? TextButton(
                    onPressed: () => context.go(
                      RoutePaths.masterTeacherFeedbackNewFor(student.id),
                    ),
                    child: const Text(AppStrings.rate),
                  )
                : null,
          ),
        ),
      );
    }
  }
  return widgets;
}

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentProfileProvider);

    return StudentScaffold(
      title: AppStrings.myProfile,
      body: AsyncBody(
        value: profile,
        onRetry: () => ref.invalidate(studentProfileProvider),
        builder: (student) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              AcademySurface(
                child: Row(
                  children: [
                    AcademyAvatar(name: student.fullName, size: 64),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Academy.ink,
                            ),
                          ),
                          Text(
                            student.email,
                            style: const TextStyle(color: Academy.muted),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Student ID · ${student.studentCode}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Brand.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StudentSectionCard(
                icon: Icons.contact_mail_rounded,
                title: AppStrings.contactDetails,
                child: Column(
                  children: [
                    _ProfileRow(
                      icon: Icons.email_outlined,
                      label: AppStrings.email,
                      value: student.email,
                    ),
                    _ProfileRow(
                      icon: Icons.wc_outlined,
                      label: AppStrings.gender,
                      value: genderLabel(student.gender),
                    ),
                    _ProfileRow(
                      icon: Icons.phone_outlined,
                      label: AppStrings.phone,
                      value: student.phone.isEmpty ? '—' : student.phone,
                    ),
                    if (student.whatsappNumber != null &&
                        student.whatsappNumber!.isNotEmpty)
                      _ProfileRow(
                        icon: Icons.chat_outlined,
                        label: AppStrings.whatsapp,
                        value: student.whatsappNumber!,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              StudentSectionCard(
                icon: Icons.hub_rounded,
                title: AppStrings.academicNetwork,
                child: Column(
                  children: [
                    _ProfileRow(
                      icon: Icons.school_rounded,
                      label: AppStrings.classLabel,
                      value: student.classGrade > 0
                          ? 'Class ${student.classGrade}'
                          : '—',
                    ),
                    _ProfileRow(
                      icon: Icons.layers_rounded,
                      label: AppStrings.level,
                      value: student.level?.label ?? AppStrings.level1,
                    ),
                    _ProfileRow(
                      icon: Icons.groups_rounded,
                      label: AppStrings.batch,
                      value: student.batch?.label ?? AppStrings.notAssigned,
                    ),
                    _ProfileRow(
                      icon: Icons.psychology_alt_rounded,
                      label: AppStrings.masterTeachers,
                      value: student.masterTeachers.isNotEmpty
                          ? student.masterTeachers
                                .map((t) => t.fullName)
                                .join(', ')
                          : AppStrings.noneAssigned,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              StudentSectionCard(
                icon: Icons.shield_outlined,
                title: AppStrings.accountSecurity,
                child: StudentQuickLink(
                  label: AppStrings.changePassword,
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

class TeacherProfilePage extends ConsumerStatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  ConsumerState<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends ConsumerState<TeacherProfilePage> {
  MentorProfileDraft? _draft;
  String? _boundId;
  var _editing = false;
  var _saving = false;

  @override
  void dispose() {
    _draft?.dispose();
    super.dispose();
  }

  void _bind(TeacherDto teacher) {
    if (_boundId == teacher.id && _draft != null) {
      return;
    }
    _boundId = teacher.id;
    _draft?.dispose();
    _draft = MentorProfileDraft.fromTeacher(teacher);
  }

  Future<void> _save() async {
    if (_draft == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(academicRepositoryProvider)
          .updateTeacherProfile(_draft!.toPayload());
      ref.invalidate(teacherProfileProvider);
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Professional profile updated.')),
        );
      }
    } catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(teacherProfileProvider);

    return AppScaffold(
      title: AppStrings.myProfile,
      body: AsyncBody(
        value: profile,
        onRetry: () => ref.invalidate(teacherProfileProvider),
        builder: (teacher) {
          if (_boundId != teacher.id || _draft == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _bind(teacher));
            });
            return const Center(child: CircularProgressIndicator());
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 600 ? 0.0 : 4.0;
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  6,
                  horizontalPadding,
                  42,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TeacherProfileToolbar(
                            teacher: teacher,
                            editing: _editing,
                            saving: _saving,
                            onToggleEdit: () => setState(() {
                              if (_editing) {
                                _draft?.dispose();
                                _draft = MentorProfileDraft.fromTeacher(
                                  teacher,
                                );
                              }
                              _editing = !_editing;
                            }),
                          ),
                          const SizedBox(height: 18),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SizeTransition(
                                  sizeFactor: animation,
                                  alignment: Alignment.topCenter,
                                  child: child,
                                ),
                              );
                            },
                            child: _editing
                                ? Column(
                                    key: const ValueKey('mentor-editor'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      MentorProfileEditor(
                                        draft: _draft!,
                                        onChanged: () => setState(() {}),
                                      ),
                                      const SizedBox(height: 18),
                                      FilledButton.icon(
                                        onPressed: _saving ? null : _save,
                                        icon: _saving
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Icon(Icons.save_rounded),
                                        label: Text(
                                          _saving
                                              ? 'Saving profile…'
                                              : 'Save Professional Profile',
                                        ),
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size.fromHeight(
                                            54,
                                          ),
                                          backgroundColor: Brand.navy,
                                        ),
                                      ),
                                    ],
                                  )
                                : MentorProfileContent(
                                    key: const ValueKey('mentor-preview'),
                                    teacher: teacher,
                                  ),
                          ),
                          const SizedBox(height: 22),
                          _TeacherPrivateDetails(teacher: teacher),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TeacherProfileToolbar extends StatelessWidget {
  const _TeacherProfileToolbar({
    required this.teacher,
    required this.editing,
    required this.saving,
    required this.onToggleEdit,
  });

  final TeacherDto teacher;
  final bool editing;
  final bool saving;
  final VoidCallback onToggleEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7DDCD)),
        boxShadow: [
          BoxShadow(
            color: Brand.navy.withValues(alpha: .05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final identity = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MentorAvatar(
                name: teacher.fullName,
                photoUrl: teacher.photoUrl,
                size: 48,
                borderRadius: 14,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR PUBLIC MENTOR PROFILE',
                      style: TextStyle(
                        color: Brand.goldDark,
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      editing
                          ? 'Shape how students meet you'
                          : 'Preview what students see',
                      style: const TextStyle(
                        color: Brand.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final button = OutlinedButton.icon(
            onPressed: saving ? null : onToggleEdit,
            icon: Icon(editing ? Icons.close_rounded : Icons.edit_rounded),
            label: Text(editing ? 'Cancel editing' : 'Edit profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: editing ? const Color(0xFF9A3F3F) : Brand.navy,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            ),
          );

          if (constraints.maxWidth < 580) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 13), button],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 16),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _TeacherPrivateDetails extends StatelessWidget {
  const _TeacherPrivateDetails({required this.teacher});

  final TeacherDto teacher;

  @override
  Widget build(BuildContext context) {
    final contact = StudentSectionCard(
      icon: Icons.contact_mail_rounded,
      title: AppStrings.contactDetails,
      child: Column(
        children: [
          _ProfileRow(
            icon: Icons.email_outlined,
            label: AppStrings.email,
            value: teacher.email,
          ),
          _ProfileRow(
            icon: Icons.wc_outlined,
            label: AppStrings.gender,
            value: genderLabel(teacher.gender),
          ),
          if (teacher.createdAt != null)
            _ProfileRow(
              icon: Icons.calendar_today_outlined,
              label: AppStrings.registered,
              value: formatDisplayDateTime(teacher.createdAt),
            ),
        ],
      ),
    );
    final account = Column(
      children: [
        StudentSectionCard(
          icon: Icons.work_outline_rounded,
          title: AppStrings.assignments,
          child: Column(
            children: [
              if ((teacher.employeeCode ?? '').isNotEmpty)
                _ProfileRow(
                  icon: Icons.badge_outlined,
                  label: AppStrings.employeeCode,
                  value: teacher.employeeCode!,
                ),
              _ProfileRow(
                icon: Icons.layers_rounded,
                label: AppStrings.assignedLevel,
                value: teacher.assignedLevelsLabel,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StudentSectionCard(
          icon: Icons.shield_outlined,
          title: AppStrings.accountSecurity,
          child: StudentQuickLink(
            label: AppStrings.changePassword,
            icon: Icons.lock_outline_rounded,
            onTap: () => context.go(RoutePaths.changePassword),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRIVATE ACCOUNT DETAILS',
          style: TextStyle(
            color: Brand.muted,
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                children: [contact, const SizedBox(height: 16), account],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: contact),
                const SizedBox(width: 16),
                Expanded(child: account),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

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
                Text(
                  label,
                  style: const TextStyle(color: Brand.muted, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Brand.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
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
      title: AppStrings.studentProfile,
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
                AppStrings.aptitudeInterestsReferenceOnly,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                AppStrings
                    .compactViewOfAptitudeResultsMonthlyDevelopmentRatingsAreShown,
                style: TextStyle(color: Brand.muted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              AsyncBody(
                value: results,
                onRetry: () =>
                    ref.invalidate(teacherStudentResultsProvider(studentId)),
                builder: (items) {
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        AppStrings.noAptitudeAssessmentSubmittedYet,
                        style: TextStyle(
                          color: Brand.muted.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
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
      title: AppStrings.aptitudeResults,
      backTo: RoutePaths.adminStudent(studentId),
      body: AsyncBody(
        value: results,
        onRetry: () => ref.invalidate(adminStudentResultsProvider(studentId)),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyHint(
              AppStrings.aptitudeNotSubmitted,
              icon: EmptyIcons.assessments,
              subtitle:
                  AppStrings.thisStudentHasNotCompletedTheAptitudeAssessmentYet,
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) =>
                AssessmentResultView(result: items[index]),
          );
        },
      ),
    );
  }
}
