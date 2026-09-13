import 'package:excellent_educators_web/core/time/app_clock.dart';
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_confirm_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_cards.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/compact_assessment_card.dart';
import 'package:excellent_educators_web/features/feedback/data/dto/feedback_dtos.dart';
import 'package:excellent_educators_web/features/feedback/domain/feedback_form_value.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/feedback_rating_bar.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/student_feedback_month_view.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/student_read_only_ratings_section.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/requests/presentation/widgets/request_student_removal_dialog.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum MonthlyFeedbackFormAudience {
  masterTeacher,
  admin,
}

class MasterTeacherStudentDetailPage extends ConsumerWidget {
  const MasterTeacherStudentDetailPage({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(masterTeacherStudentProvider(studentId));
    final results = ref.watch(masterTeacherStudentResultsProvider(studentId));

    return AppScaffold(
      title: 'Student profile',
      backTo: RoutePaths.masterTeacherStudents,
      body: AsyncBody(
        value: student,
        onRetry: () => ref.invalidate(masterTeacherStudentProvider(studentId)),
        builder: (studentData) {
          return ListView(
            children: [
              StudentCard(
                student: studentData,
                highlightOverallRating: true,
                action: RequestStudentRemovalIconButton(
                  studentId: studentData.id,
                  studentName: studentData.fullName,
                  studentCode: studentData.studentCode,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.go(RoutePaths.masterTeacherStudentJournalFor(studentId)),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Learning journal'),
              ),
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
                onRetry: () => ref.invalidate(masterTeacherStudentResultsProvider(studentId)),
                builder: (resultItems) {
                  if (resultItems.isEmpty) {
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
                      for (final result in resultItems) ...[
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
                audience: StudentRatingsAudience.masterTeacher,
                student: studentData,
                onAddRating: studentData.canRateThisMonth
                    ? () => context.go(RoutePaths.masterTeacherFeedbackNewFor(studentId))
                    : null,
                onEditRating: (feedbackId) =>
                    context.go(RoutePaths.masterTeacherFeedbackEditFor(studentId, feedbackId)),
                onDeleteRating: (feedbackId) => _confirmDeleteRating(context, ref, studentId, feedbackId),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _confirmDeleteRating(
  BuildContext context,
  WidgetRef ref,
  String studentId,
  String feedbackId,
) async {
  final confirmed = await showAppConfirmDialog(
    context,
    title: 'Delete rating?',
    message:
        'This removes the monthly rating permanently. You can only delete during the same calendar month it was submitted.',
    confirmLabel: 'Delete',
    cancelLabel: 'Cancel',
    destructive: true,
  );
  if (confirmed != true) {
    return;
  }

  try {
    await ref.read(feedbackRepositoryProvider).deleteFeedback(studentId, feedbackId);
    ref.invalidate(masterTeacherStudentFeedbackProvider(studentId));
    ref.invalidate(masterTeacherStudentFeedbackSummaryProvider(studentId));
    ref.invalidate(masterTeacherStudentProvider(studentId));
    ref.invalidate(masterTeacherStudentsProvider);
  } catch (error) {
    if (context.mounted) {
      showFailure(context, error);
    }
  }
}

class MonthlyFeedbackFormPage extends ConsumerStatefulWidget {
  const MonthlyFeedbackFormPage({
    super.key,
    required this.studentId,
    required this.audience,
    this.feedbackId,
  });

  final String studentId;
  final MonthlyFeedbackFormAudience audience;
  final String? feedbackId;

  @override
  ConsumerState<MonthlyFeedbackFormPage> createState() => _MonthlyFeedbackFormPageState();
}

class _MonthlyFeedbackFormPageState extends ConsumerState<MonthlyFeedbackFormPage> {
  late String _sessionDate;
  String _targetType = 'dimension';
  String? _targetId;
  int _rating = 5;
  final _positive = TextEditingController();
  final _improve = TextEditingController();
  var _saving = false;
  var _bound = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sessionDate = AppClock.todayString();
  }

  String get _monthLabel {
    final parsed = DateTime.tryParse(_sessionDate);
    if (parsed == null) {
      return _sessionDate;
    }
    return AppClock.monthLabel(parsed.year, parsed.month);
  }

  @override
  void dispose() {
    _positive.dispose();
    _improve.dispose();
    super.dispose();
  }

  void _bind(MonthlyFeedbackDto feedback) {
    if (_bound) {
      return;
    }
    _bound = true;
    if (feedback.sessionDate != null) {
      _sessionDate = feedback.sessionDate!;
    }
    if (feedback.items.isNotEmpty) {
      final item = feedback.items.first;
      _targetType = item.targetType;
      _targetId = item.targetId;
      _rating = item.rating;
      _positive.text = item.positivePoints ?? '';
      _improve.text = item.areasForImprovement ?? '';
    }
  }

  Future<void> _save() async {
    final value = FeedbackFormValue(
      sessionDate: _sessionDate,
      targetType: _targetType,
      targetId: _targetId ?? '',
      rating: _rating,
      positivePoints: _positive.text,
      areasForImprovement: _improve.text,
    );
    final error = FeedbackFormValue.validate(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(feedbackRepositoryProvider);
      if (widget.audience == MonthlyFeedbackFormAudience.admin) {
        if (widget.feedbackId == null) {
          await repo.adminCreateFeedback(widget.studentId, value.toCreatePayload());
        } else {
          await repo.adminUpdateFeedback(widget.studentId, widget.feedbackId!, value.toUpdatePayload());
        }
        ref.invalidate(adminStudentFeedbackProvider(widget.studentId));
        ref.invalidate(adminStudentFeedbackSummaryProvider(widget.studentId));
        ref.invalidate(adminDashboardProvider);
        ref.invalidate(adminTeacherDashboardProvider);
        if (mounted) {
          context.go(RoutePaths.adminStudent(widget.studentId));
        }
      } else {
        if (widget.feedbackId == null) {
          await repo.createFeedback(widget.studentId, value.toCreatePayload());
        } else {
          await repo.updateFeedback(widget.studentId, widget.feedbackId!, value.toUpdatePayload());
        }
        ref.invalidate(masterTeacherStudentFeedbackProvider(widget.studentId));
        ref.invalidate(masterTeacherStudentFeedbackSummaryProvider(widget.studentId));
        ref.invalidate(masterTeacherStudentProvider(widget.studentId));
        ref.invalidate(masterTeacherStudentsProvider);
        ref.invalidate(teacherDayScheduleProvider);
        ref.invalidate(masterTeacherDashboardProvider);
        if (mounted) {
          context.go(RoutePaths.masterTeacherStudentFor(widget.studentId));
        }
      }
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.audience == MonthlyFeedbackFormAudience.admin;
    final catalog = isAdmin
        ? ref.watch(adminFeedbackCatalogProvider)
        : ref.watch(masterTeacherFeedbackCatalogProvider);
    final existing = widget.feedbackId == null
        ? null
        : isAdmin
            ? ref.watch(adminStudentFeedbackProvider(widget.studentId))
            : ref.watch(masterTeacherStudentFeedbackProvider(widget.studentId));

    existing?.whenData((items) {
      for (final item in items) {
        if (item.id == widget.feedbackId) {
          _bind(item);
        }
      }
    });

    return AppScaffold(
      title: widget.feedbackId == null ? 'Monthly rating' : 'Edit monthly rating',
      backTo: isAdmin
          ? RoutePaths.adminStudent(widget.studentId)
          : RoutePaths.masterTeacherStudentFor(widget.studentId),
      body: AsyncBody(
        value: catalog,
        builder: (dimensions) {
          return ListView(
            children: [
              if (isAdmin)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Admin override — you can add or change ratings at any time.',
                    style: TextStyle(color: Brand.muted, fontSize: 13),
                  ),
                ),
              Text(
                _monthLabel,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                isAdmin
                    ? 'One rating per student per month. Admins can edit any time.'
                    : 'One rating per student per month. You can edit or delete during the rating month only.',
                style: const TextStyle(color: Brand.muted),
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFB42318))),
                ),
              DropdownButtonFormField<String>(
                initialValue: _targetType,
                decoration: const InputDecoration(labelText: 'Area'),
                items: const [
                  DropdownMenuItem(value: 'dimension', child: Text('Dimension')),
                  DropdownMenuItem(value: 'module', child: Text('Module')),
                  DropdownMenuItem(value: 'skill', child: Text('Skill')),
                ],
                onChanged: (value) => setState(() {
                  _targetType = value ?? _targetType;
                  _targetId = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _targetId,
                decoration: const InputDecoration(labelText: 'Select skill / module / dimension'),
                items: [
                  for (final item in _targets(dimensions))
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
                ],
                onChanged: (value) => setState(() => _targetId = value),
              ),
              const SizedBox(height: 20),
              FeedbackRatingBar(
                rating: _rating,
                onChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _positive,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Positive points', alignLabelWithHint: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _improve,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Areas for improvement', alignLabelWithHint: true),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save monthly rating'),
              ),
            ],
          );
        },
      ),
    );
  }

  List<({String id, String name})> _targets(List<FeedbackDimensionDto> dimensions) {
    if (_targetType == 'dimension') {
      return [for (final dimension in dimensions) (id: dimension.id, name: dimension.name)];
    }
    if (_targetType == 'module') {
      return [
        for (final dimension in dimensions)
          for (final module in dimension.modules) (id: module.id, name: '${dimension.name} · ${module.name}'),
      ];
    }
    return [
      for (final dimension in dimensions)
        for (final module in dimension.modules)
          for (final skill in module.skills) (id: skill.id, name: '${module.name} · ${skill.name}'),
    ];
  }
}

class StudentFeedbackPage extends ConsumerWidget {
  const StudentFeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedback = ref.watch(studentFeedbackProvider);
    final summary = ref.watch(studentFeedbackSummaryProvider);

    return StudentScaffold(
      title: 'My ratings',
      body: AsyncBody(
        value: feedback,
        onRetry: () {
          ref.invalidate(studentFeedbackProvider);
          ref.invalidate(studentFeedbackSummaryProvider);
        },
        builder: (items) {
          if (items.isEmpty) {
            return const AcademyEmpty(
              icon: Icons.forum_outlined,
              title: 'No feedback yet',
              body: 'Your teachers will share monthly notes here as your journey unfolds.',
            );
          }

          return AsyncBody(
            value: summary,
            builder: (summaryData) => ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                StudentFeedbackMonthView(summary: summaryData, items: items),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
