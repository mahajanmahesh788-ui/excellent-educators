import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/features/feedback/data/dto/feedback_dtos.dart';
import 'package:flutter/material.dart';

class MonthlyRatingHistoryList extends StatelessWidget {
  const MonthlyRatingHistoryList({
    super.key,
    required this.items,
    this.onEdit,
    this.onDelete,
    this.expandedFeedbackId,
  });

  final List<MonthlyFeedbackDto> items;
  final void Function(String feedbackId)? onEdit;
  final void Function(String feedbackId)? onDelete;
  final String? expandedFeedbackId;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = [...items]
      ..sort((a, b) {
        final yearCompare = b.year.compareTo(a.year);
        if (yearCompare != 0) {
          return yearCompare;
        }
        return b.month.compareTo(a.month);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sorted.length; i++) ...[
          _MonthlyRatingHistoryTile(
            feedback: sorted[i],
            initiallyExpanded: sorted[i].id == expandedFeedbackId,
            onEdit: sorted[i].editable && onEdit != null ? () => onEdit!(sorted[i].id) : null,
            onDelete: sorted[i].deletable && onDelete != null ? () => onDelete!(sorted[i].id) : null,
          ),
          if (i < sorted.length - 1)
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Container(height: 16, width: 2, color: const Color(0xFFE6DCCB)),
            ),
        ],
      ],
    );
  }
}

class _MonthlyRatingHistoryTile extends StatefulWidget {
  const _MonthlyRatingHistoryTile({
    required this.feedback,
    this.initiallyExpanded = false,
    this.onEdit,
    this.onDelete,
  });

  final MonthlyFeedbackDto feedback;
  final bool initiallyExpanded;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<_MonthlyRatingHistoryTile> createState() => _MonthlyRatingHistoryTileState();
}

class _MonthlyRatingHistoryTileState extends State<_MonthlyRatingHistoryTile> {
  late var _expanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(covariant _MonthlyRatingHistoryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyExpanded && widget.feedback.id != oldWidget.feedback.id) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedback = widget.feedback;
    final average = feedback.averageRating;
    final sessionDate = formatDisplayDate(feedback.sessionDate ?? feedback.submittedAt);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE6DCCB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF6EA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Brand.gold.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, size: 18, color: Brand.goldDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedback.monthLabel,
                          style: const TextStyle(
                            color: Brand.navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Session · $sessionDate',
                          style: const TextStyle(color: Brand.muted, fontSize: 12),
                        ),
                        if (feedback.items.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final item in feedback.items)
                                _RatingChip(label: item.targetName, rating: item.rating),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AverageBadge(rating: average),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Brand.muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFE6DCCB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (feedback.masterTeacherName != null)
                    _DetailLine(
                      label: 'Master Teacher',
                      value: feedback.masterTeacherName!,
                    ),
                  for (final item in feedback.items) ...[
                    const SizedBox(height: 10),
                    Text(
                      item.targetName,
                      style: const TextStyle(
                        color: Brand.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _RatingMeter(rating: item.rating),
                    if (item.positivePoints != null && item.positivePoints!.trim().isNotEmpty)
                      _DetailLine(label: 'Positive', value: item.positivePoints!.trim()),
                    if (item.areasForImprovement != null && item.areasForImprovement!.trim().isNotEmpty)
                      _DetailLine(label: 'Improve', value: item.areasForImprovement!.trim()),
                    if (item.recommendedNextAction != null && item.recommendedNextAction!.trim().isNotEmpty)
                      _DetailLine(label: 'Next step', value: item.recommendedNextAction!.trim()),
                  ],
                  if (widget.onEdit != null || widget.onDelete != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (widget.onEdit != null)
                          TextButton.icon(
                            onPressed: widget.onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit rating'),
                          ),
                        if (widget.onDelete != null)
                          TextButton.icon(
                            onPressed: widget.onDelete,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Delete rating'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB42318)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AverageBadge extends StatelessWidget {
  const _AverageBadge({required this.rating});

  final double? rating;

  @override
  Widget build(BuildContext context) {
    if (rating == null) {
      return const Text('—', style: TextStyle(color: Brand.muted, fontWeight: FontWeight.w700));
    }

    final color = _ratingColor(rating!);
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        rating!.toStringAsFixed(1),
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.label, required this.rating});

  final String label;
  final int rating;

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(rating.toDouble());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$label · $rating',
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}

class _RatingMeter extends StatelessWidget {
  const _RatingMeter({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(rating.toDouble());
    final fraction = (rating / 10).clamp(0.05, 1.0);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFEDE4D4)),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$rating/10',
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Brand.navy, fontSize: 12, height: 1.4),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Brand.muted, fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

Color _ratingColor(double rating) {
  if (rating >= 8) {
    return const Color(0xFF2E7D32);
  }
  if (rating >= 5) {
    return Brand.goldDark;
  }
  return const Color(0xFFC62828);
}
