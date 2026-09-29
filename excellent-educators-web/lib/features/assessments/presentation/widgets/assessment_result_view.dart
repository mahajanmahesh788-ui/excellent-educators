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
    this.showTitle = true,
  });

  final AssessmentResultDto result;
  final bool compact;
  final bool showCharts;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final title = result.assessmentTitle;
    final showHeading = showTitle && title != null && title.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeading && !compact)
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Brand.navy,
                  fontWeight: FontWeight.w800,
                ),
          ),
        if (showHeading && compact)
          Text(
            title,
            style: TextStyle(
              color: Brand.navy,
              fontWeight: FontWeight.w700,
              fontSize: isMobile ? 12.5 : 14,
            ),
          ),
        if (result.submittedAt != null && !compact) ...[
          const SizedBox(height: 4),
          Text(
            'Completed ${formatDisplayDateTime(result.submittedAt)}',
            style: const TextStyle(color: Brand.muted, fontSize: 13),
          ),
        ],
        if (showHeading || (result.submittedAt != null && !compact))
          SizedBox(height: compact ? 8 : 16),
        if (showCharts && !compact && result.dimensions.isNotEmpty) ...[
          Center(child: DimensionRadarChart(dimensions: result.dimensions, size: 220)),
          const SizedBox(height: 20),
          DimensionBarChart(dimensions: result.dimensions),
        ] else if (compact)
          _CompactDimensionGrid(dimensions: result.dimensions, compact: isMobile)
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
  const _CompactDimensionGrid({
    required this.dimensions,
    this.compact = false,
  });

  final List<DimensionScoreDto> dimensions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (dimensions.isEmpty) {
      return const SizedBox.shrink();
    }

    final fontSize = compact ? 11.0 : 12.0;
    final padH = compact ? 8.0 : 10.0;
    final padV = compact ? 4.0 : 6.0;

    return Wrap(
      spacing: compact ? 5 : 6,
      runSpacing: compact ? 5 : 6,
      children: [
        for (final dimension in dimensions)
          Container(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF6EA),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE6DCCB)),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: dimension.name,
                    style: TextStyle(
                      color: Brand.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize,
                    ),
                  ),
                  TextSpan(
                    text: ' · ',
                    style: TextStyle(color: Brand.muted, fontSize: fontSize),
                  ),
                  TextSpan(
                    text: '${dimension.score}',
                    style: TextStyle(
                      color: Brand.goldDark,
                      fontWeight: FontWeight.w800,
                      fontSize: fontSize,
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
