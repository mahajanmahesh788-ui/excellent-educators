import 'package:flutter/material.dart';

import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';

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

  static String? validate(
    AptitudeAssessmentDto assessment,
    Map<String, String> selections,
  ) {
    for (final question in assessment.questions) {
      if (!selections.containsKey(question.id)) {
        return AppStrings.pleaseAnswerEveryQuestionBeforeSubmitting;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorText != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFECACA), width: 1.4),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFB42318),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    errorText!,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        for (var q = 0; q < assessment.questions.length; q++)
          _QuestionCard(
            index: q + 1,
            question: assessment.questions[q],
            selectedOptionId: selections[assessment.questions[q].id],
            onSelect: (optionId) =>
                onSelect(assessment.questions[q].id, optionId),
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
    final isAnswered = selectedOptionId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAnswered
              ? StudentColors.indigoPrimary.withValues(alpha: 0.3)
              : StudentColors.border,
          width: isAnswered ? 1.4 : 1.0,
        ),
        boxShadow: StudentColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question Header Ribbon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: isAnswered
                  ? StudentColors.indigoLight.withValues(alpha: 0.35)
                  : StudentColors.surfaceMuted,
              border: Border(
                bottom: BorderSide(
                  color: isAnswered
                      ? StudentColors.indigoPrimary.withValues(alpha: 0.2)
                      : StudentColors.border,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: StudentColors.indigoPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'MOMENT $index',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    if (isAnswered)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: StudentColors.emeraldLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: StudentColors.emeraldDark,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Answered',
                              style: TextStyle(
                                color: StudentColors.emeraldDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  question.questionText,
                  style: const TextStyle(
                    color: StudentColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Options List
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                for (final option in question.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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

class _OptionTile extends StatefulWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    final Color bgColor = selected
        ? StudentColors.forestLight
        : (_hovered ? StudentColors.surfaceMuted : Colors.white);

    final Color borderColor = selected
        ? StudentColors.indigoPrimary
        : (_hovered ? StudentColors.textMuted : StudentColors.border);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: selected ? 1.8 : 1.2),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: StudentColors.indigoPrimary.withValues(
                        alpha: 0.12,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected
                      ? StudentColors.indigoPrimary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? StudentColors.indigoPrimary
                        : StudentColors.textMuted,
                    width: selected ? 2.0 : 1.6,
                  ),
                ),
                child: selected
                    ? const Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: selected
                        ? StudentColors.textPrimary
                        : StudentColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
