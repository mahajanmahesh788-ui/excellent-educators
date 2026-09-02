import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/assessment_result_view.dart';
import 'package:flutter/material.dart';

class CompactAssessmentCard extends StatelessWidget {
  const CompactAssessmentCard({super.key, required this.result});

  final AssessmentResultDto result;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE6DCCB))),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: AssessmentResultView(
              result: result,
              compact: true,
              showCharts: false,
            ),
          ),
        ),
      ),
    );
  }
}
