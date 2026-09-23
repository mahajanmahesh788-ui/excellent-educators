import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/feedback/data/dto/feedback_dtos.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/feedback_charts.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/monthly_rating_history.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_ui.dart';
import 'package:flutter/material.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class StudentFeedbackMonthView extends StatefulWidget {
  const StudentFeedbackMonthView({
    super.key,
    required this.summary,
    required this.items,
  });

  final FeedbackSummaryDto summary;
  final List<MonthlyFeedbackDto> items;

  @override
  State<StudentFeedbackMonthView> createState() =>
      _StudentFeedbackMonthViewState();
}

class _StudentFeedbackMonthViewState extends State<StudentFeedbackMonthView> {
  late String _selectedKey;

  @override
  void initState() {
    super.initState();
    _selectedKey = _monthKey(widget.items.first);
  }

  @override
  void didUpdateWidget(covariant StudentFeedbackMonthView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.isEmpty) {
      return;
    }
    if (!widget.items.any((item) => _monthKey(item) == _selectedKey)) {
      _selectedKey = _monthKey(widget.items.first);
    }
  }

  String _monthKey(MonthlyFeedbackDto item) => '${item.year}-${item.month}';

  MonthlyFeedbackDto? get _selectedItem {
    for (final item in widget.items) {
      if (_monthKey(item) == _selectedKey) {
        return item;
      }
    }
    return widget.items.isEmpty ? null : widget.items.first;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedItem;
    if (selected == null) {
      return const SizedBox.shrink();
    }

    final monthItems = widget.items
        .where((item) => _monthKey(item) == _selectedKey)
        .toList();
    final monthSummary = widget.summary.byMonth.where(
      (row) => '${row.year}-${row.month}' == _selectedKey,
    );
    final monthlyAverage = monthSummary.isEmpty
        ? null
        : monthSummary.first.averageRating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FeedbackOverallCard(summary: widget.summary),
        const SizedBox(height: 20),
        StudentSectionCard(
          icon: Icons.calendar_month_rounded,
          title: AppStrings.selectMonth,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in widget.items.map(_monthKey).toSet())
                ChoiceChip(
                  label: Text(
                    widget.items
                        .firstWhere((item) => _monthKey(item) == key)
                        .monthLabel,
                  ),
                  selected: key == _selectedKey,
                  onSelected: (_) => setState(() => _selectedKey = key),
                  selectedColor: StudentColors.forestTint,
                  labelStyle: TextStyle(
                    color: key == _selectedKey
                        ? StudentColors.forest
                        : Brand.navy,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(
                    color: key == _selectedKey
                        ? StudentColors.forestBorder
                        : StudentColors.border,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StudentSectionCard(
          icon: Icons.rate_review_rounded,
          title: monthItems.isEmpty
              ? selected.monthLabel
              : monthItems.first.monthLabel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (monthlyAverage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Monthly overall · ${monthlyAverage.toStringAsFixed(1)} / 10',
                    style: const TextStyle(
                      color: Brand.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              MonthlyRatingHistoryList(items: monthItems),
            ],
          ),
        ),
        if (widget.summary.byMonth.length > 1) ...[
          const SizedBox(height: 16),
          StudentSectionCard(
            icon: Icons.show_chart_rounded,
            title: AppStrings.monthWiseTrend,
            child: FeedbackMonthlyTrendChart(months: widget.summary.byMonth),
          ),
        ],
      ],
    );
  }
}
