import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/compact_assessment_card.dart';
import 'package:flutter/material.dart';

/// Horizontal carousel of compact aptitude result cards.
/// Newest / highest level first (e.g. Level 2, then Level 1).
class CompactAssessmentResultsScroller extends StatelessWidget {
  const CompactAssessmentResultsScroller({
    super.key,
    required this.results,
    this.cardWidth = 360,
    this.height = 210,
  });

  final List<AssessmentResultDto> results;
  final double cardWidth;
  final double height;

  static List<AssessmentResultDto> sortedNewestLevelFirst(
    List<AssessmentResultDto> results,
  ) {
    final items = [...results];
    items.sort((a, b) {
      final levelCmp = _levelNumber(b).compareTo(_levelNumber(a));
      if (levelCmp != 0) return levelCmp;
      final aTime = a.submittedAt ?? '';
      final bTime = b.submittedAt ?? '';
      return bTime.compareTo(aTime);
    });
    return items;
  }

  static int _levelNumber(AssessmentResultDto result) {
    final title = result.assessmentTitle ?? '';
    final match = RegExp(r'level\s*(\d+)', caseSensitive: false).firstMatch(title);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final items = sortedNewestLevelFirst(results);
    if (items.isEmpty) return const SizedBox.shrink();
    if (items.length == 1) {
      return CompactAssessmentCard(result: items.first);
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: cardWidth,
              child: CompactAssessmentCard(result: items[index]),
            ),
          );
        },
      ),
    );
  }
}
