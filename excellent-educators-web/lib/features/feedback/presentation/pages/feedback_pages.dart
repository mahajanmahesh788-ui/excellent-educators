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
import 'package:excellent_educators_web/features/feedback/presentation/widgets/dimension_factor_profile.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/student_feedback_month_view.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/student_read_only_ratings_section.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/requests/presentation/widgets/request_student_removal_dialog.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

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
      title: AppStrings.studentProfile,
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
                label: const Text(AppStrings.learningJournal2),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.aptitudeInterestsReferenceOnly,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                AppStrings.compactViewOfAptitudeResultsMonthlyDevelopmentRatingsAreShown,
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
                        AppStrings.noAptitudeAssessmentSubmittedYet,
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
    title: AppStrings.deleteRating2,
    message:
        AppStrings.thisRemovesTheMonthlyRatingPermanentlyYouCanOnlyDelete,
    confirmLabel: AppStrings.delete,
    cancelLabel: AppStrings.cancel,
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
    this.bookingId,
  });

  final String studentId;
  final MonthlyFeedbackFormAudience audience;
  final String? feedbackId;
  final String? bookingId;

  @override
  ConsumerState<MonthlyFeedbackFormPage> createState() => _MonthlyFeedbackFormPageState();
}

class _MonthlyFeedbackFormPageState extends ConsumerState<MonthlyFeedbackFormPage> {
  final _positive = TextEditingController();
  final _improve = TextEditingController();
  final _discussed = TextEditingController();
  final _ratings = <String, int>{};
  var _saving = false;
  var _bound = false;
  String? _error;

  @override
  void dispose() {
    _positive.dispose();
    _improve.dispose();
    _discussed.dispose();
    super.dispose();
  }

  void _bind(MonthlyFeedbackDto feedback, List<FeedbackDimensionDto> dimensions) {
    if (_bound) {
      return;
    }
    _bound = true;
    for (final dimension in dimensions) {
      final match = feedback.items.where((item) => item.targetId == dimension.id);
      _ratings[dimension.id] = match.isEmpty ? 5 : match.first.rating;
    }
    _positive.text = feedback.positivePoints ?? '';
    _improve.text = feedback.areasForImprovement ?? '';
    _discussed.text = feedback.discussedInClass ?? '';
  }

  void _seedRatings(List<FeedbackDimensionDto> dimensions) {
    if (_ratings.isNotEmpty) {
      return;
    }
    for (final dimension in dimensions) {
      _ratings[dimension.id] = 5;
    }
  }

  Future<void> _save(List<FeedbackDimensionDto> dimensions) async {
    final value = FeedbackFormValue(
      bookingId: widget.bookingId,
      ratings: Map<String, int>.from(_ratings),
      positivePoints: _positive.text,
      areasForImprovement: _improve.text,
      discussedInClass: _discussed.text,
    );
    final error = FeedbackFormValue.validate(value, expectedCount: dimensions.length);
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

    return AppScaffold(
      title: widget.feedbackId == null ? AppStrings.monthlyRating : AppStrings.editMonthlyRating,
      backTo: isAdmin
          ? RoutePaths.adminStudent(widget.studentId)
          : RoutePaths.masterTeacherStudentFor(widget.studentId),
      body: AsyncBody(
        value: catalog,
        builder: (dimensions) {
          existing?.whenData((items) {
            for (final item in items) {
              if (item.id == widget.feedbackId) {
                _bind(item, dimensions);
              }
            }
          });
          _seedRatings(dimensions);

          final ratingValues = dimensions.map((d) => _ratings[d.id] ?? 5).toList();
          final avgRating = ratingValues.isEmpty
              ? 5.0
              : (ratingValues.reduce((a, b) => a + b) / ratingValues.length);
          final avgBand = dimensionBand(avgRating.round());
          final isMobile = MediaQuery.sizeOf(context).width < 600;

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24,
              vertical: isMobile ? 12 : 20,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE6DCCB)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(isMobile ? 14 : 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: isMobile ? 38 : 44,
                              height: isMobile ? 38 : 44,
                              decoration: BoxDecoration(
                                color: Brand.creamDark.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.stars_rounded, size: isMobile ? 22 : 26, color: Brand.navy),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.onePageTenDimensionsClearNextSteps,
                                    style: TextStyle(
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.w800,
                                      color: Brand.navy,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isAdmin
                                        ? AppStrings.oneRatingPerStudentPerMonthAdminsCanEditAny
                                        : AppStrings.oneRatingPerStudentPerMonthYouCanEditOr,
                                    style: const TextStyle(color: Brand.muted, fontSize: 13, height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                            if (!isMobile) ...[
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: avgBand.bgColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: avgBand.color.withValues(alpha: 0.35)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Average: ',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: avgBand.color),
                                        ),
                                        Text(
                                          avgRating.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: avgBand.color,
                                          ),
                                        ),
                                        Text(
                                          ' / 10',
                                          style: TextStyle(fontSize: 11, color: avgBand.color),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      avgBand.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: avgBand.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isMobile) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: avgBand.bgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: avgBand.color.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Overall Average: ${avgRating.toStringAsFixed(1)} / 10',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: avgBand.color,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: avgBand.color.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  avgBand.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: avgBand.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE4E2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDA29B)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFB42318), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8EEF5)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 12,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Brand.gold,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ILLUSTRATIVE STUDENT PROFILE',
                                        style: TextStyle(
                                          color: Color(0xFF1D4ED8),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'One page. Ten dimensions. Clear next steps.',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Brand.navy,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isMobile) ...[
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _legendBadge('Strength', const Color(0xFF0F9D58), const Color(0xFFE8F5E9)),
                                      _legendBadge('Explore', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                                      _legendBadge('Develop', const Color(0xFFC4A35A), const Color(0xFFFFFBEB)),
                                      _legendBadge('Focus', const Color(0xFFD93025), const Color(0xFFFFEBEE)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 20),
                            DimensionFactorProfile(
                              items: [
                                for (final dimension in dimensions)
                                  DimensionRatingValue(
                                    id: dimension.id,
                                    name: dimension.name,
                                    rating: _ratings[dimension.id] ?? 5,
                                  ),
                              ],
                              onChanged: (id, rating) => setState(() => _ratings[id] = rating),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE6DCCB)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(isMobile ? 14 : 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Brand.creamDark.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.rate_review_outlined, size: 20, color: Brand.navy),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Master Class Observations & Guidance',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Brand.navy,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _positive,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: AppStrings.positivePoints,
                                hintText: 'Highlight student strengths, active participation, and standout moments...',
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _improve,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: AppStrings.areasForImprovementOptional,
                                hintText: 'Specific skills or behaviors for the student to practice or focus on...',
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _discussed,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: AppStrings.discussedInThisMasterClass,
                                hintText: 'Key discussion topics, recommendations, or goals agreed during the session...',
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              if (isAdmin) {
                                context.go(RoutePaths.adminStudent(widget.studentId));
                              } else {
                                context.go(RoutePaths.masterTeacherStudentFor(widget.studentId));
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(120, 44),
                              side: const BorderSide(color: Color(0xFFD7CDBB)),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _saving ? null : () => _save(dimensions),
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text(AppStrings.saveMonthlyRating),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(190, 44),
                              backgroundColor: Brand.navy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _legendBadge(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class StudentFeedbackPage extends ConsumerWidget {
  const StudentFeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedback = ref.watch(studentFeedbackProvider);
    final summary = ref.watch(studentFeedbackSummaryProvider);

    return StudentScaffold(
      title: AppStrings.myRatings,
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
              title: AppStrings.noFeedbackYet,
              body: AppStrings.yourTeachersWillShareMonthlyNotesHereAsYourJourney,
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
