import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class FeedbackRatingBar extends StatelessWidget {
  const FeedbackRatingBar({
    super.key,
    required this.rating,
    this.maxRating = 10,
    this.onChanged,
    this.readOnly = false,
  });

  final int rating;
  final int maxRating;
  final ValueChanged<int>? onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final clamped = rating.clamp(1, maxRating);
    final progress = clamped / maxRating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Rating',
                style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$clamped / $maxRating',
              style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: const Color(0xFFE8ECF4),
            color: const Color(0xFF3949AB),
          ),
        ),
        if (!readOnly && onChanged != null) ...[
          const SizedBox(height: 4),
          Slider(
            value: clamped.toDouble(),
            min: 1,
            max: maxRating.toDouble(),
            divisions: maxRating - 1,
            label: '$clamped',
            activeColor: const Color(0xFF3949AB),
            onChanged: (value) => onChanged!(value.round()),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1', style: TextStyle(color: Brand.muted, fontSize: 12)),
              Text('10', style: TextStyle(color: Brand.muted, fontSize: 12)),
            ],
          ),
        ],
      ],
    );
  }
}
