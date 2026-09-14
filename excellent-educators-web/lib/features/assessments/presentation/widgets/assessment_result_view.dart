import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/dimension_charts.dart';
import 'package:flutter/material.dart';

class AssessmentResultView extends StatelessWidget {
  const AssessmentResultView({
    super.key,
    required this.result,
    this.compact = false,
    this.showCharts = true,
  });

  final AssessmentResultDto result;
  final bool compact;
  final bool showCharts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact && result.assessmentTitle != null)
          Text(
            result.assessmentTitle!,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Brand.navy,
                  fontWeight: FontWeight.w800,
                ),
          ),
        if (compact && result.assessmentTitle != null)
          Text(
            result.assessmentTitle!,
            style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        if (result.submittedAt != null && !compact) ...[
          const SizedBox(height: 4),
          Text(
            'Completed ${formatDisplayDateTime(result.submittedAt)}',
            style: const TextStyle(color: Brand.muted, fontSize: 13),
          ),
        ],
        SizedBox(height: compact ? 8 : 16),
        if (showCharts && !compact && result.dimensions.isNotEmpty) ...[
          Center(child: DimensionRadarChart(dimensions: result.dimensions, size: 220)),
          const SizedBox(height: 20),
          DimensionBarChart(dimensions: result.dimensions),
        ] else if (compact)
          _CompactDimensionGrid(dimensions: result.dimensions)
        else
          for (final dimension in result.dimensions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dimension.name,
                      style: const TextStyle(
                        color: Brand.navy,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Brand.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${dimension.score}',
                      key: ValueKey('score-${dimension.name}'),
                      style: const TextStyle(
                        color: Brand.goldDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _CompactDimensionGrid extends StatelessWidget {
  const _CompactDimensionGrid({required this.dimensions});

  final List<DimensionScoreDto> dimensions;

  @override
  Widget build(BuildContext context) {
    if (dimensions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final dimension in dimensions)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF6EA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE6DCCB)),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: dimension.name,
                    style: const TextStyle(
                      color: Brand.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const TextSpan(
                    text: ' · ',
                    style: TextStyle(color: Brand.muted, fontSize: 12),
                  ),
                  TextSpan(
                    text: '${dimension.score}',
                    style: const TextStyle(
                      color: Brand.goldDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
