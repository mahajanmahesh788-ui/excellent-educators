import 'package:excellent_educators_web/core/time/app_clock.dart';
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
import 'package:excellent_educators_web/features/auth/domain/admin_permission.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AdminStudentFeedbackSection extends ConsumerStatefulWidget {
  const AdminStudentFeedbackSection({super.key, required this.student});

  final StudentDto student;

  @override
  ConsumerState<AdminStudentFeedbackSection> createState() => _AdminStudentFeedbackSectionState();
}

class _AdminStudentFeedbackSectionState extends ConsumerState<AdminStudentFeedbackSection> {
  String? _selectedMonthKey;

  void _invalidate() {
    ref.invalidate(adminStudentFeedbackSummaryProvider(widget.student.id));
    ref.invalidate(adminStudentFeedbackProvider(widget.student.id));
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

  Future<void> _confirmDelete(String feedbackId) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: AppStrings.deleteRating2,
      message: AppStrings.thisRemovesTheMonthlyRatingPermanentlyThisActionCannotBe,
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
      destructive: true,
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(feedbackRepositoryProvider).adminDeleteFeedback(widget.student.id, feedbackId);
      _invalidate();
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.student.hasMasterTeacher) {
      return DetailSection(
        title: AppStrings.masterTeacherRatings,
        children: [
          Text(
            AppStrings.assignAMasterTeacherToEnableMonthlyRatings,
            style: TextStyle(color: Brand.muted.withValues(alpha: 0.9), fontSize: 13),
          ),
        ],
      );
    }

    final summary = ref.watch(adminStudentFeedbackSummaryProvider(widget.student.id));
    final feedback = ref.watch(adminStudentFeedbackProvider(widget.student.id));
    final canRate = ref.watch(authControllerProvider).user?.canAdmin(AdminPermission.studentsRating) ?? false;

    return DetailSection(
      title: AppStrings.masterTeacherRatings,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (widget.student.feedbackCurrentMonthCompleted)
              const _StatusTag(
                label: AppStrings.monthlyRatingDone,
                background: Color(0xFFE8F5E9),
                color: Color(0xFF2E7D32),
              )
            else
              const _StatusTag(
                label: AppStrings.noMonthlyRatingThisMonth,
                background: Color(0xFFFFF8E1),
                color: Color(0xFFF57F17),
              ),
            if (widget.student.feedbackTotalSessions > 0)
              _StatusTag(
                label: '${widget.student.feedbackTotalSessions} monthly rating(s) on record',
                background: const Color(0xFFE8EAF6),
                color: const Color(0xFF3949AB),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AsyncBody(
          value: feedback,
          onRetry: _invalidate,
          builder: (items) {
            final currentMonth = _currentMonthRating(items);
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                  if (canRate)
                  FilledButton.icon(
                    onPressed: () => context.go(RoutePaths.adminFeedbackNewFor(widget.student.id)),
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.addMonthlyRating),
                  ),
                if (canRate && currentMonth != null) ...[
                  FilledButton.tonalIcon(
                    onPressed: () => context.go(RoutePaths.adminFeedbackEditFor(widget.student.id, currentMonth.id)),
                    icon: const Icon(Icons.edit),
                    label: const Text(AppStrings.editThisMonth),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(currentMonth.id),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(AppStrings.deleteThisMonth),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        AsyncBody(
          value: summary,
          onRetry: _invalidate,
          builder: (summaryData) {
            if (summaryData.totalSessions == 0) {
              return Text(
                'No monthly ratings submitted yet for ${widget.student.fullName}.',
                style: TextStyle(color: Brand.muted.withValues(alpha: 0.9), fontSize: 13),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FeedbackOverallCard(summary: summaryData),
                const SizedBox(height: 16),
                Text(AppStrings.monthWiseTrend, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                FeedbackMonthlyTrendChart(months: summaryData.byMonth),
                const SizedBox(height: 16),
                Text(AppStrings.overallBySkillDimension, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                FeedbackDimensionOverview(dimensions: summaryData.byDimension),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        AsyncBody(
          value: feedback,
          onRetry: _invalidate,
          builder: (items) {
            if (items.isEmpty) {
              return const SizedBox.shrink();
            }

            final monthEntries = <String, String>{};
            for (final item in items) {
              final key = '${item.year}-${item.month.toString().padLeft(2, '0')}';
              monthEntries.putIfAbsent(key, () => AppClock.monthLabel(item.year, item.month));
            }

            final filteredItems = (_selectedMonthKey == null || _selectedMonthKey == 'all')
                ? items
                : items.where((item) {
                    final key = '${item.year}-${item.month.toString().padLeft(2, '0')}';
                    return key == _selectedMonthKey;
                  }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.monthlyRatingHistory,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Showing ${filteredItems.length} of ${items.length} rating${items.length == 1 ? '' : 's'} · Admin can edit or delete',
                            style: const TextStyle(color: Brand.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (monthEntries.length > 1) ...[
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE6DCCB)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: monthEntries.containsKey(_selectedMonthKey) ? _selectedMonthKey : 'all',
                            icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Brand.navy),
                            style: const TextStyle(color: Brand.navy, fontSize: 13, fontWeight: FontWeight.w600),
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text(AppStrings.allMonths2)),
                              for (final entry in monthEntries.entries)
                                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                            ],
                            onChanged: (value) => setState(() => _selectedMonthKey = value),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                if (filteredItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      AppStrings.noMonthlyRatingsForThisMonth,
                      style: TextStyle(color: Brand.muted.withValues(alpha: 0.9), fontSize: 13),
                    ),
                  )
                else
                  MonthlyRatingHistoryList(
                    items: filteredItems,
                    onEdit: (feedbackId) => context.go(RoutePaths.adminFeedbackEditFor(widget.student.id, feedbackId)),
                    onDelete: (feedbackId) => _confirmDelete(feedbackId),
                    showStaffNotes: true,
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
