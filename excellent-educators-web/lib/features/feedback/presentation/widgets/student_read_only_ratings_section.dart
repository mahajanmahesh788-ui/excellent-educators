import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/feedback/data/dto/feedback_dtos.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/feedback_charts.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/monthly_rating_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

enum StudentRatingsAudience {
  commonTeacher,
  masterTeacher,
}

class StudentRatingsSection extends ConsumerWidget {
  const StudentRatingsSection({
    super.key,
    required this.studentId,
    required this.audience,
    this.student,
    this.onAddRating,
    this.onEditRating,
    this.onDeleteRating,
  });

  final String studentId;
  final StudentRatingsAudience audience;
  final StudentDto? student;
  final VoidCallback? onAddRating;
  final void Function(String feedbackId)? onEditRating;
  final void Function(String feedbackId)? onDeleteRating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (student != null && !student!.hasMasterTeacher) {
      return DetailSection(
        title: AppStrings.masterTeacherRatings,
        children: [
          Text(
            AppStrings.noMasterTeacherAssignedYetMonthlyRatingsWillAppearHere,
            style: TextStyle(color: Brand.muted.withValues(alpha: 0.9), fontSize: 13),
          ),
        ],
      );
    }

    final summary = audience == StudentRatingsAudience.masterTeacher
        ? ref.watch(masterTeacherStudentFeedbackSummaryProvider(studentId))
        : ref.watch(teacherStudentFeedbackSummaryProvider(studentId));
    final feedback = audience == StudentRatingsAudience.masterTeacher
        ? ref.watch(masterTeacherStudentFeedbackProvider(studentId))
        : ref.watch(teacherStudentFeedbackProvider(studentId));

    void invalidate() {
      if (audience == StudentRatingsAudience.masterTeacher) {
        ref.invalidate(masterTeacherStudentFeedbackSummaryProvider(studentId));
        ref.invalidate(masterTeacherStudentFeedbackProvider(studentId));
      } else {
        ref.invalidate(teacherStudentFeedbackSummaryProvider(studentId));
        ref.invalidate(teacherStudentFeedbackProvider(studentId));
      }
    }

    return DetailSection(
      title: AppStrings.masterTeacherRatings,
      children: [
        if (audience == StudentRatingsAudience.masterTeacher) ...[
          AsyncBody(
            value: feedback,
            onRetry: invalidate,
            builder: (items) => _masterTeacherRatingActions(items),
          ),
          const SizedBox(height: 16),
        ],
        AsyncBody(
          value: summary,
          onRetry: invalidate,
          builder: (summaryData) {
            if (summaryData.totalSessions == 0) {
              return Text(
                AppStrings.noMonthlyRatingsSubmittedYet,
                style: TextStyle(color: Brand.muted.withValues(alpha: 0.9), fontSize: 13),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FeedbackOverallCard(summary: summaryData),
                if (summaryData.byMonth.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(AppStrings.monthWiseTrend, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  FeedbackMonthlyTrendChart(months: summaryData.byMonth),
                ],
                if (summaryData.byDimension.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(AppStrings.overallBySkillDimension, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  FeedbackDimensionOverview(dimensions: summaryData.byDimension),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        AsyncBody(
          value: feedback,
          onRetry: invalidate,
          builder: (items) {
            if (items.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.monthlyRatingHistory,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '${items.length} month${items.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: Brand.muted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.newestFirstTapAMonthToSeeFullDetails,
                  style: TextStyle(color: Brand.muted.withValues(alpha: 0.9), fontSize: 12),
                ),
                const SizedBox(height: 12),
                MonthlyRatingHistoryList(
                  items: items,
                  onEdit: audience == StudentRatingsAudience.masterTeacher ? onEditRating : null,
                  onDelete: audience == StudentRatingsAudience.masterTeacher ? onDeleteRating : null,
                  showStaffNotes: true,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _masterTeacherRatingActions(List<MonthlyFeedbackDto> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (onAddRating != null)
          FilledButton.icon(
            onPressed: onAddRating,
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.addMonthlyRating),
          ),
        if (items.any((item) => item.editable) && onEditRating != null)
          FilledButton.tonalIcon(
            onPressed: () {
              final editable = items.firstWhere((item) => item.editable);
              onEditRating!(editable.id);
            },
            icon: const Icon(Icons.edit),
            label: const Text(AppStrings.editThisMonthSRating),
          ),
      ],
    );
  }
}
