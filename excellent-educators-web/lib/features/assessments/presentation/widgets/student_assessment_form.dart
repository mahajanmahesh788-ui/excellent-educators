import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:flutter/material.dart';

class StudentAssessmentForm extends StatelessWidget {
  const StudentAssessmentForm({
    super.key,
    required this.assessment,
    required this.selections,
    required this.onSelect,
    this.errorText,
  });

  final AptitudeAssessmentDto assessment;
  final Map<String, String> selections;
  final void Function(String questionId, String optionId) onSelect;
  final String? errorText;

  static String? validate(AptitudeAssessmentDto assessment, Map<String, String> selections) {
    for (final question in assessment.questions) {
      if (!selections.containsKey(question.id)) {
        return 'Please answer every question before submitting.';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!assessment.title.contains('Welcome'))
          Text(
            assessment.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Brand.navy,
                ),
          ),
        if (assessment.description != null && assessment.description!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(assessment.description!, style: const TextStyle(color: Brand.muted, height: 1.3, fontSize: 13)),
        ],
        const SizedBox(height: 10),
        if (errorText != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(errorText!, style: const TextStyle(color: Color(0xFFB42318)))),
              ],
            ),
          ),
        for (var q = 0; q < assessment.questions.length; q++)
          _QuestionCard(
            index: q + 1,
            question: assessment.questions[q],
            selectedOptionId: selections[assessment.questions[q].id],
            onSelect: (optionId) => onSelect(assessment.questions[q].id, optionId),
          ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selectedOptionId,
    required this.onSelect,
  });

  final int index;
  final AptitudeQuestionDto question;
  final String? selectedOptionId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DCCB)),
      ),
      clipBehavior: Clip.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Brand.navyDeep.withValues(alpha: 0.08),
                  Brand.navy.withValues(alpha: 0.04),
                ],
              ),
              border: Border(
                bottom: BorderSide(color: Brand.gold.withValues(alpha: 0.35)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Brand.navyDeep,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Moment $index',
                    style: const TextStyle(
                      color: Brand.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question.questionText,
                    style: const TextStyle(
                      color: Brand.navyDeep,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              children: [
                for (final option in question.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: _OptionTile(
                      label: option.optionText,
                      selected: selectedOptionId == option.id,
                      onTap: () => onSelect(option.id),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Brand.gold.withValues(alpha: 0.12) : const Color(0xFFF5F1E8),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? Brand.gold : const Color(0xFFE8E0D4),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? Brand.goldDark : const Color(0xFF9CA3AF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Brand.navyDeep : Brand.muted,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
