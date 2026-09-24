import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/core/widgets/app_confirm_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_dialog.dart';
import 'package:excellent_educators_web/features/auth/domain/admin_permission.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/admin_student_feedback_section.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/master_teacher_progress_panel.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_cards.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/compact_assessment_card.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/schedule/presentation/widgets/teacher_availability_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/widgets/schedule_ui.dart';

class AdminStudentDetailPage extends ConsumerWidget {
  const AdminStudentDetailPage({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentValue = ref.watch(adminStudentProvider(studentId));
    final resultsValue = ref.watch(adminStudentResultsProvider(studentId));
    final user = ref.watch(authControllerProvider).user;
    return AppScaffold(
      title: AppStrings.studentProfile,
      backTo: RoutePaths.adminStudents,
      body: AsyncBody(
        value: studentValue,
        onRetry: () => ref.invalidate(adminStudentProvider(studentId)),
        builder: (student) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              StudentCard(
                student: student,
                highlightOverallRating: true,
                showMonthRatingStatus: false,
                action: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => context.go(RoutePaths.adminStudentJournalFor(student.id)),
                      icon: const Icon(Icons.menu_book_outlined, size: 18),
                      label: const Text(AppStrings.learningJournal2),
                    ),
                    if (user?.canAdmin(AdminPermission.studentsEdit) ?? false)
                      FilledButton.tonalIcon(
                        onPressed: () => updateStudentMasterClassQuota(context, ref, student),
                        icon: const Icon(Icons.event_available_outlined, size: 18),
                        label: const Text(AppStrings.masterClasses),
                      ),
                    if (student.hasSubmittedAptitudeAssessment)
                      FilledButton.tonalIcon(
                        onPressed: () => context.go(RoutePaths.adminStudentResultsFor(student.id)),
                        icon: const Icon(Icons.insights, size: 18),
                        label: const Text(AppStrings.aptitudeResults),
                      ),
                    if (user?.canAdmin(AdminPermission.studentsDelete) ?? false)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showAppConfirmDialog(
                            context,
                            title: AppStrings.deleteStudent,
                            message: AppStrings.delete,
                            confirmLabel: AppStrings.delete,
                            cancelLabel: AppStrings.cancel,
                            destructive: true,
                          );
                          if (confirmed != true) {
                            return;
                          }
                          try {
                            await ref.read(academicRepositoryProvider).deleteStudent(student.id);
                            if (context.mounted) {
                              context.go(RoutePaths.adminStudents);
                            }
                          } catch (error) {
                            if (context.mounted) {
                              showFailure(context, error);
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text(AppStrings.deleteStudent),
                      ),
                  ],
                ),
                trailing: (user?.canAdmin(AdminPermission.studentsEdit) ?? false)
                    ? IconButton(
                        tooltip: AppStrings.editStudent,
                        icon: const Icon(Icons.edit_outlined),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context.go(RoutePaths.adminStudentEditFor(student.id)),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              StatGrid(
                children: [
                  StatTile(
                    label: AppStrings.status2,
                    value: student.status == 'active' ? AppStrings.active : AppStrings.inactive,
                  ),
                  StatTile(
                    label: AppStrings.classLevel,
                    value: student.classGrade > 0
                        ? 'Class ${student.classGrade}${student.level != null && !student.level!.isEmpty ? ' · ${student.level!.label}' : ''}'
                        : (student.level != null && !student.level!.isEmpty ? student.level!.label : AppStrings.notAssigned),
                  ),
                  StatTile(
                    label: AppStrings.aptitudeTest,
                    value: student.hasSubmittedAptitudeAssessment ? AppStrings.submitted : AppStrings.pending,
                  ),
                  StatTile(
                    label: AppStrings.overallRating,
                    value: student.hasOverallRating
                        ? '${student.feedbackOverallAverage!.toStringAsFixed(1)} ★'
                        : AppStrings.notRated,
                  ),
                  StatTile(
                    label: AppStrings.masterClassesThisMonth,
                    value: '${student.masterClassRemaining} left',
                    subtitle: '${student.masterClassUsed} used of ${student.masterClassAllotment}',
                    onTap: (user?.canAdmin(AdminPermission.studentsEdit) ?? false)
                        ? () => updateStudentMasterClassQuota(context, ref, student)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DetailSection(
                title: AppStrings.studentInformation,
                children: [
                  DetailRow(label: AppStrings.studentId, value: student.studentCode),
                  DetailRow(label: AppStrings.gender, value: genderLabel(student.gender)),
                  DetailRow(label: AppStrings.email, value: student.email),
                  DetailRow(label: AppStrings.phone, value: student.phone.isNotEmpty ? student.phone : '—'),
                  if (student.whatsappNumber != null && student.whatsappNumber!.isNotEmpty)
                    DetailRow(label: AppStrings.whatsapp, value: student.whatsappNumber!),
                  if (student.address != null && student.address!.isNotEmpty)
                    DetailRow(label: AppStrings.address, value: student.address!),
                  if (student.guardianName != null && student.guardianName!.isNotEmpty)
                    DetailRow(
                      label: AppStrings.guardian,
                      value: student.guardianPhone != null && student.guardianPhone!.isNotEmpty
                          ? '${student.guardianName!} · ${student.guardianPhone!}'
                          : student.guardianName!,
                    ),
                  if (student.createdAt != null)
                    DetailRow(label: AppStrings.registered, value: formatDisplayDateTime(student.createdAt)),
                  if (student.level != null && !student.level!.isEmpty)
                    DetailRow(label: AppStrings.level, value: student.level!.label),
                  if (student.batch != null && !student.batch!.isEmpty)
                    DetailRow(label: AppStrings.batch, value: student.batch!.label),
                ],
              ),
              const SizedBox(height: 12),
              _StudentHistorySection(studentId: student.id),
              const SizedBox(height: 12),
              DetailSection(
                title: AppStrings.aptitudeAssessment,
                children: [
                  if (student.hasSubmittedAptitudeAssessment) ...[
                    DetailRow(label: AppStrings.status2, value: AppStrings.submitted),
                    if (student.aptitudeAssessmentTitle != null && student.aptitudeAssessmentTitle!.isNotEmpty)
                      DetailRow(label: AppStrings.assessment, value: student.aptitudeAssessmentTitle!),
                    if (student.aptitudeAssessmentSubmittedAt != null)
                      DetailRow(
                        label: AppStrings.submittedOn,
                        value: formatDisplayDateTime(student.aptitudeAssessmentSubmittedAt),
                      ),
                    const SizedBox(height: 10),
                    AsyncBody(
                      value: resultsValue,
                      onRetry: () => ref.invalidate(adminStudentResultsProvider(student.id)),
                      builder: (results) {
                        if (results.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final result in results) ...[
                              CompactAssessmentCard(result: result),
                              const SizedBox(height: 8),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.go(RoutePaths.adminStudentResultsFor(student.id)),
                          icon: const Icon(Icons.insights, size: 18),
                          label: const Text(AppStrings.viewDetailedScoresDimensions),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go(RoutePaths.adminStudentJournalFor(student.id)),
                          icon: const Icon(Icons.menu_book_outlined, size: 18),
                          label: const Text(AppStrings.openLearningJournal),
                        ),
                      ],
                    ),
                  ] else ...[
                    const DetailRow(label: AppStrings.status2, value: AppStrings.notSubmittedYet),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.theStudentWillSeeTheAssessmentOnTheirDashboardOnce,
                      style: TextStyle(color: Brand.muted.withValues(alpha: 0.9), fontSize: 13),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              AdminStudentFeedbackSection(student: student),
              if (user?.canAdmin(AdminPermission.studentsPromote) ?? false) ...[
                const SizedBox(height: 12),
                _PromoteStudentCard(studentId: student.id, currentLevelId: student.level?.id),
              ],
            ],
          );
        },
      ),
    );
  }
}

Future<void> updateStudentMasterClassQuota(
  BuildContext context,
  WidgetRef ref,
  StudentDto student,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _MasterClassQuotaDialog(student: student),
  );
}

class _MasterClassQuotaDialog extends ConsumerStatefulWidget {
  const _MasterClassQuotaDialog({required this.student});

  final StudentDto student;

  @override
  ConsumerState<_MasterClassQuotaDialog> createState() => _MasterClassQuotaDialogState();
}

class _MasterClassQuotaDialogState extends ConsumerState<_MasterClassQuotaDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final student = widget.student;
    _controller = TextEditingController(
      text: '${student.masterClassOverride ?? student.masterClassAllotment}',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final student = widget.student;
    try {
      await ref.read(academicRepositoryProvider).updateStudent(student.id, {
        'master_classes_per_month': int.parse(_controller.text.trim()),
      });
      ref.invalidate(adminStudentProvider(student.id));
      ref.invalidate(adminStudentHistoryProvider(student.id));
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        showFailure(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    return AppModalDialog(
      title: AppStrings.masterClassesThisMonth,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${student.masterClassUsed} used · ${student.masterClassRemaining} remaining of ${student.masterClassAllotment}',
              style: const TextStyle(color: Brand.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: AppStrings.totalMasterClasses,
                helperText: AppStrings.thisStudentCanBookThisManyClassesThisMonth,
              ),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                if (parsed == null || parsed < 1 || parsed > 10) {
                  return AppStrings.enterANumberFrom1To10;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            AppDialogActions(
              confirmLabel: AppStrings.save,
              isConfirming: _saving,
              onConfirm: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentHistorySection extends ConsumerWidget {
  const _StudentHistorySection({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(adminStudentHistoryProvider(studentId));
    return DetailSection(
      title: AppStrings.studentHistory,
      children: [
        AsyncBody(
          value: history,
          onRetry: () => ref.invalidate(adminStudentHistoryProvider(studentId)),
          builder: (items) {
            if (items.isEmpty) {
              return const Text(AppStrings.noActivityRecordedYet, style: TextStyle(color: Brand.muted, fontSize: 13));
            }
            return ActivityTimeline(items: items);
          },
        ),
      ],
    );
  }
}

class AdminTeacherDetailPage extends ConsumerWidget {
  const AdminTeacherDetailPage({super.key, required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherValue = ref.watch(adminTeacherProvider(teacherId));
    final user = ref.watch(authControllerProvider).user;

    return AppScaffold(
      title: AppStrings.teacher,
      backTo: RoutePaths.adminTeachers,
      body: AsyncBody(
        value: teacherValue,
        onRetry: () => ref.invalidate(adminTeacherProvider(teacherId)),
        builder: (teacher) {
          return ListView(
            children: [
              TeacherCard(
                teacher: teacher,
                action: Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => context.go(RoutePaths.adminTeacherHistoryFor(teacherId)),
                      icon: const Icon(Icons.history),
                      label: const Text(AppStrings.history),
                    ),
                    if (user?.canAdmin(AdminPermission.teachersDelete) ?? false)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showAppConfirmDialog(
                            context,
                            title: AppStrings.deleteTeacher,
                            message: AppStrings.delete,
                            confirmLabel: AppStrings.delete,
                            cancelLabel: AppStrings.cancel,
                            destructive: true,
                          );
                          if (confirmed != true) {
                            return;
                          }
                          try {
                            await ref.read(academicRepositoryProvider).deleteTeacher(teacherId);
                            if (context.mounted) {
                              context.go(RoutePaths.adminTeachers);
                            }
                          } catch (error) {
                            if (context.mounted) {
                              showFailure(context, error);
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text(AppStrings.deleteTeacher),
                      ),
                  ],
                ),
                trailing: (user?.canAdmin(AdminPermission.teachersEdit) ?? false)
                    ? IconButton(
                        tooltip: AppStrings.editTeacher,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => context.go(RoutePaths.adminTeacherEditFor(teacherId)),
                      )
                    : null,
              ),
              const SizedBox(height: 10),
              TeacherAvailabilitySummary(teacherId: teacherId),
              const SizedBox(height: 12),
              _AdminTeacherLeavesTile(teacherId: teacherId),
              const SizedBox(height: 12),
              _AdminTeacherPromotedTile(teacherId: teacherId),
              if (teacher.isMasterTeacher) ...[
                const SizedBox(height: 12),
                _AdminTeacherProgressSection(teacherId: teacherId),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AdminTeacherLeavesTile extends ConsumerWidget {
  const _AdminTeacherLeavesTile({required this.teacherId});

  final String teacherId;

  bool _isCurrentMonth(LeaveRequestDto leave) {
    final parts = leave.date.split('-');
    if (parts.length < 2) return false;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return false;
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaves = ref.watch(adminTeacherLeavesProvider(teacherId));
    final approved =
        leaves.valueOrNull?.where((l) => l.status == 'approved').toList() ??
            const <LeaveRequestDto>[];
    final thisMonth = approved.where(_isCurrentMonth).length;
    final total = approved.length;

    return StatTile(
      label: AppStrings.leaves,
      value: leaves.isLoading ? '…' : '$thisMonth',
      icon: Icons.event_busy_outlined,
      accentColor: Brand.navy,
      subtitle: leaves.isLoading
          ? AppStrings.leaveHistory
          : '$thisMonth this month · total $total leaves',
      onTap: () => context.go(RoutePaths.adminTeacherLeavesFor(teacherId)),
    );
  }
}

class AdminTeacherLeavesPage extends ConsumerWidget {
  const AdminTeacherLeavesPage({super.key, required this.teacherId});

  final String teacherId;

  Color _statusColor(String status) {
    return switch (status) {
      'pending' => const Color(0xFF785500),
      'reassignment_pending' => const Color(0xFF9A3412),
      'approved' => const Color(0xFF047857),
      'rejected' => const Color(0xFFB91C1C),
      'cancelled' => const Color(0xFF64748B),
      _ => Brand.muted,
    };
  }

  Color _statusBg(String status) {
    return switch (status) {
      'pending' => const Color(0xFFFFF7E8),
      'reassignment_pending' => const Color(0xFFFFF1E8),
      'approved' => const Color(0xFFECFDF5),
      'rejected' => const Color(0xFFFEF2F2),
      'cancelled' => const Color(0xFFF1F5F9),
      _ => const Color(0xFFF8FAFC),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaves = ref.watch(adminTeacherLeavesProvider(teacherId));

    return AppScaffold(
      title: AppStrings.leaveHistory,
      backTo: RoutePaths.adminTeacher(teacherId),
      body: AsyncBody(
        value: leaves,
        onRetry: () => ref.invalidate(adminTeacherLeavesProvider(teacherId)),
        builder: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                AppStrings.noLeavesRecordedYet,
                style: TextStyle(
                  color: Brand.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final approved = items.where((l) => l.status == 'approved').toList();
          final now = DateTime.now();
          final thisMonth = approved.where((leave) {
            final parts = leave.date.split('-');
            if (parts.length < 2) return false;
            final year = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            return year == now.year && month == now.month;
          }).length;

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Text(
                '$thisMonth this month · total ${approved.length} leaves',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Brand.navyDeep,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 14),
              for (final leave in items) ...[
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: leave.requestGroupId.isEmpty
                        ? null
                        : () => context.go(
                              RoutePaths.adminLeaveRequest(leave.requestGroupId),
                            ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE8E0D4)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  leave.date,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Brand.navyDeep,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  leave.isFullDay
                                      ? AppStrings.fullDay2
                                      : (leave.ranges.isNotEmpty
                                          ? '${formatHm(leave.ranges.first.startTime)} – ${formatHm(leave.ranges.last.endTime)}'
                                          : AppStrings.partial),
                                  style: const TextStyle(
                                    color: Brand.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if ((leave.reason ?? '').trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(leave.reason!.trim()),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _statusBg(leave.status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              leave.statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _statusColor(leave.status),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: Brand.muted),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AdminTeacherPromotedTile extends ConsumerWidget {
  const _AdminTeacherPromotedTile({required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promoted = ref.watch(adminTeacherPromotedProvider(teacherId));
    final count = promoted.valueOrNull?.length ?? 0;

    return StatTile(
      label: AppStrings.promotedStudents,
      value: promoted.isLoading ? '…' : '$count',
      icon: Icons.trending_up,
      accentColor: Brand.goldDark,
      subtitle: AppStrings.levelledUpWithThisTeacher,
      onTap: () => context.go(RoutePaths.adminTeacherPromotedFor(teacherId)),
    );
  }
}

class AdminTeacherPromotedPage extends ConsumerWidget {
  const AdminTeacherPromotedPage({super.key, required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(adminTeacherPromotedProvider(teacherId));

    return AppScaffold(
      title: AppStrings.promotedStudents,
      backTo: RoutePaths.adminTeacher(teacherId),
      body: AsyncBody(
        value: students,
        onRetry: () => ref.invalidate(adminTeacherPromotedProvider(teacherId)),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyHint(
              AppStrings.noPromotedStudentsYet,
              subtitle: AppStrings.studentsThisTeacherMentoredWhoLaterMovedToANew,
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final student = items[index];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE6DCCB)),
                ),
                title: Text(student.fullName),
                subtitle: Text(
                  [
                    student.studentCode,
                    if (student.level != null && !student.level!.isEmpty) student.level!.label,
                  ].join(' · '),
                ),
                onTap: () => context.go(RoutePaths.adminStudent(student.id)),
              );
            },
          );
        },
      ),
    );
  }
}

class _PromoteStudentCard extends ConsumerStatefulWidget {
  const _PromoteStudentCard({required this.studentId, this.currentLevelId});

  final String studentId;
  final String? currentLevelId;

  @override
  ConsumerState<_PromoteStudentCard> createState() => _PromoteStudentCardState();
}

class _PromoteStudentCardState extends ConsumerState<_PromoteStudentCard> {
  String? _levelId;
  var _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final levels = ref.watch(adminLevelsProvider);
    return DetailSection(
      title: AppStrings.promoteStudent,
      children: [
        AsyncBody(
          value: levels,
          onRetry: () => ref.invalidate(adminLevelsProvider),
          builder: (items) {
            final options = items.where((level) => level.id != widget.currentLevelId).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(AppStrings.theNewLevelStartsFromItsOwnWeek1Previous),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _levelId,
                  decoration: const InputDecoration(labelText: AppStrings.newLevel),
                  items: [
                    for (final level in options)
                      DropdownMenuItem(value: level.id, child: Text(level.name)),
                  ],
                  onChanged: (value) => setState(() => _levelId = value),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving || _levelId == null
                      ? null
                      : () async {
                          setState(() {
                            _saving = true;
                            _error = null;
                          });
                          try {
                            await ref.read(learningRepositoryProvider).promoteStudent(
                                  studentId: widget.studentId,
                                  levelId: _levelId!,
                                );
                            ref.invalidate(adminStudentProvider(widget.studentId));
                          } catch (error) {
                            setState(() => _error = error.toString());
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                  child: Text(_saving ? AppStrings.promoting : AppStrings.promote),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AdminTeacherProgressSection extends ConsumerWidget {
  const _AdminTeacherProgressSection({required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(adminTeacherDashboardProvider(teacherId));

    return AsyncBody(
      value: progress,
      onRetry: () => ref.invalidate(adminTeacherDashboardProvider(teacherId)),
      builder: (data) {
        return MasterTeacherProgressPanel(
          data: data,
          showPendingStudents: true,
          onPendingStudentTap: (student) => context.go(RoutePaths.adminStudent(student.id)),
          onRateStudent: (student) => context.go(RoutePaths.adminFeedbackNewFor(student.id)),
          onEditStudentRating: (student) {
            final id = student.monthlyFeedbackId;
            if (id == null || id.isEmpty) {
              return;
            }
            context.go(RoutePaths.adminFeedbackEditFor(student.id, id));
          },
        );
      },
    );
  }
}
