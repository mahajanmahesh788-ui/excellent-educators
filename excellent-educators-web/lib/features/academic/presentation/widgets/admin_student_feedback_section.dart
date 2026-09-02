import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_confirm_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/feedback/data/dto/feedback_dtos.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/feedback_charts.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/monthly_rating_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminStudentFeedbackSection extends ConsumerWidget {
  const AdminStudentFeedbackSection({super.key, required this.student});

  final StudentDto student;

  void _invalidate(WidgetRef ref) {
    ref.invalidate(adminStudentFeedbackSummaryProvider(student.id));
    ref.invalidate(adminStudentFeedbackProvider(student.id));
  }

  MonthlyFeedbackDto? _currentMonthRating(List<MonthlyFeedbackDto> items) {
    final now = DateTime.now();
    for (final item in items) {
      if (item.year == now.year && item.month == now.month) {
        return item;
      }
    }
    return null;
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String feedbackId) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Delete rating?',
      message: 'This removes the monthly rating permanently. This action cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(feedbackRepositoryProvider).adminDeleteFeedback(student.id, feedbackId);
      _invalidate(ref);
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!student.hasMasterTeacher) {
      return DetailSection(
        title: 'Master Teacher ratings',
        children: [
          Text(
            'Assign a Master Teacher to enable monthly ratings.',
            style: TextStyle(color: Brand.muted.withValues(alpha: 0.9), fontSize: 13),
          ),
        ],
      );
    }

    final summary = ref.watch(adminStudentFeedbackSummaryProvider(student.id));
    final feedback = ref.watch(adminStudentFeedbackProvider(student.id));

    return DetailSection(
      title: 'Master Teacher ratings',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (student.feedbackCurrentMonthCompleted)
              const _StatusTag(
                label: 'Monthly rating done',
                background: Color(0xFFE8F5E9),
                color: Color(0xFF2E7D32),
              )
            else
              const _StatusTag(
                label: 'No monthly rating',
                background: Color(0xFFFFF8E1),
                color: Color(0xFFF57F17),
              ),
            if (student.feedbackTotalSessions > 0)
              _StatusTag(
                label: '${student.feedbackTotalSessions} monthly rating(s) on record',
                background: const Color(0xFFE8EAF6),
                color: const Color(0xFF3949AB),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AsyncBody(
          value: feedback,
          onRetry: () => _invalidate(ref),
          builder: (items) {
            final currentMonth = _currentMonthRating(items);
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (currentMonth == null)
                  FilledButton.icon(
                    onPressed: () => context.go(RoutePaths.adminFeedbackNewFor(student.id)),
                    icon: const Icon(Icons.add),
                    label: const Text('Add monthly rating'),
                  )
                else ...[
                  FilledButton.tonalIcon(
                    onPressed: () => context.go(RoutePaths.adminFeedbackEditFor(student.id, currentMonth.id)),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit this month'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, ref, currentMonth.id),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete this month'),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        AsyncBody(
          value: summary,
          onRetry: () => _invalidate(ref),
          builder: (summaryData) {
            if (summaryData.totalSessions == 0) {
              return Text(
                'No monthly ratings submitted yet for ${student.fullName}.',
                style: TextStyle(color: Brand.muted.withValues(alpha: 0.9), fontSize: 13),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FeedbackOverallCard(summary: summaryData),
                const SizedBox(height: 16),
                Text('Month-wise trend', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                FeedbackMonthlyTrendChart(months: summaryData.byMonth),
                const SizedBox(height: 16),
                Text('Overall by skill / dimension', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                FeedbackDimensionOverview(dimensions: summaryData.byDimension),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        AsyncBody(
          value: feedback,
          onRetry: () => _invalidate(ref),
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
                        'Monthly rating history',
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
                const Text(
                  'Admin can edit or delete any rating at any time',
                  style: TextStyle(color: Brand.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                MonthlyRatingHistoryList(
                  items: items,
                  onEdit: (feedbackId) => context.go(RoutePaths.adminFeedbackEditFor(student.id, feedbackId)),
                  onDelete: (feedbackId) => _confirmDelete(context, ref, feedbackId),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({
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
