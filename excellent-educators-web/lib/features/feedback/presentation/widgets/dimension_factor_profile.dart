import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/feedback/data/dto/feedback_dtos.dart';
import 'package:flutter/material.dart';

class DimensionFactorProfile extends StatelessWidget {
  const DimensionFactorProfile({
    super.key,
    required this.items,
    this.onChanged,
    this.readOnly = false,
  });

  final List<DimensionRatingValue> items;
  final void Function(String targetId, int rating)? onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final mid = (items.length / 2).ceil();
    final left = items.sublist(0, mid);
    final right = items.sublist(mid);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;
        if (stacked) {
          return Column(
            children: [
              for (final item in items)
                _FactorRow(item: item, readOnly: readOnly, onChanged: onChanged),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (final item in left)
                    _FactorRow(item: item, readOnly: readOnly, onChanged: onChanged),
                ],
              ),
            ),
            const SizedBox(width: 48),
            Expanded(
              child: Column(
                children: [
                  for (final item in right)
                    _FactorRow(item: item, readOnly: readOnly, onChanged: onChanged),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class DimensionRatingValue {
  const DimensionRatingValue({
    required this.id,
    required this.name,
    required this.rating,
  });

  factory DimensionRatingValue.fromItem(FeedbackItemDto item) {
    return DimensionRatingValue(id: item.targetId, name: item.targetName, rating: item.rating);
  }

  final String id;
  final String name;
  final int rating;
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({
    required this.item,
    required this.readOnly,
    this.onChanged,
  });

  final DimensionRatingValue item;
  final bool readOnly;
  final void Function(String targetId, int rating)? onChanged;

  @override
  Widget build(BuildContext context) {
    final band = dimensionBand(item.rating);
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final labelWidth = isMobile ? 88.0 : 130.0;
    final fontSize = isMobile ? 12.0 : 14.0;
    final statusWidth = isMobile ? 52.0 : 70.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 5 : 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              item.name,
              style: TextStyle(
                color: Brand.navy,
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: readOnly
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: isMobile ? 8 : 10,
                      child: Stack(
                        children: [
                          Container(color: const Color(0xFFE8EEF5)),
                          FractionallySizedBox(
                            widthFactor: (item.rating / 10).clamp(0.08, 1),
                            child: Container(color: band.barColor),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 10,
                      activeTrackColor: band.barColor,
                      inactiveTrackColor: const Color(0xFFE8EEF5),
                      thumbColor: Colors.white,
                      overlayColor: band.barColor.withValues(alpha: 0.15),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                        elevation: 2,
                        pressedElevation: 4,
                      ),
                      trackShape: const RoundedRectSliderTrackShape(),
                      tickMarkShape: SliderTickMarkShape.noTickMark,
                    ),
                    child: Slider(
                      value: item.rating.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '${item.rating}',
                      onChanged: onChanged == null ? null : (value) => onChanged!(item.id, value.round()),
                    ),
                  ),
          ),
          SizedBox(width: isMobile ? 6 : 10),
          SizedBox(
            width: isMobile ? 18 : 22,
            child: Text(
              '${item.rating}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Brand.navy,
                fontWeight: FontWeight.w800,
                fontSize: fontSize,
              ),
            ),
          ),
          SizedBox(width: isMobile ? 4 : 8),
          SizedBox(
            width: statusWidth,
            child: Text(
              band.label,
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: band.color,
                fontWeight: FontWeight.w700,
                fontSize: isMobile ? 11 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

({String label, Color color, Color barColor, Color bgColor}) dimensionBand(int rating) {
  if (rating >= 8) {
    return (
      label: 'Strength',
      color: const Color(0xFF0F9D58),
      barColor: const Color(0xFF0F9D58),
      bgColor: const Color(0xFFE8F5E9),
    );
  }
  if (rating >= 6) {
    return (
      label: 'Explore',
      color: const Color(0xFFD97706),
      barColor: const Color(0xFFD97706),
      bgColor: const Color(0xFFFFFBEB),
    );
  }
  if (rating >= 4) {
    return (
      label: 'Develop',
      color: const Color(0xFFC4A35A),
      barColor: const Color(0xFFC4A35A),
      bgColor: const Color(0xFFFFF8E1),
    );
  }
  return (
    label: 'Focus',
    color: const Color(0xFFD93025),
    barColor: const Color(0xFFD93025),
    bgColor: const Color(0xFFFFEBEE),
  );
}
