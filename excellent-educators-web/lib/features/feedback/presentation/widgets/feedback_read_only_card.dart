import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/feedback/data/dto/feedback_dtos.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/feedback_rating_bar.dart';
import 'package:flutter/material.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class FeedbackReadOnlyCard extends StatelessWidget {
  const FeedbackReadOnlyCard({
    super.key,
    required this.feedback,
    this.onEdit,
  });

  final MonthlyFeedbackDto feedback;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    feedback.monthLabel,
                    style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                if (feedback.editable && onEdit != null)
                  TextButton(onPressed: onEdit, child: const Text(AppStrings.edit)),
              ],
            ),
            if (feedback.masterTeacherName != null)
              Text('Master Teacher: ${feedback.masterTeacherName}', style: const TextStyle(color: Brand.muted)),
            const SizedBox(height: 12),
            if (feedback.positivePoints != null && feedback.positivePoints!.isNotEmpty)
              Text('Positive points: ${feedback.positivePoints}'),
            for (final item in feedback.items) ...[
              Text(item.targetName, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              FeedbackRatingBar(rating: item.rating, readOnly: true),
              if (item.positivePoints != null && item.positivePoints!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Positive points: ${item.positivePoints}'),
              ],
              if (item.areasForImprovement != null && item.areasForImprovement!.isNotEmpty)
                Text('Areas for improvement: ${item.areasForImprovement}'),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
