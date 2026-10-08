import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:flutter/material.dart';

/// Shared, attractive Interest + Parent details presentation
/// used across Student Profile, Admin Student Detail, and Teacher Briefing.
class StudentOnboardingProfileSections extends StatelessWidget {
  const StudentOnboardingProfileSections({
    super.key,
    required this.student,
    this.onEditInterest,
    this.onEditParent,
    this.useStudentCards = false,
  });

  final StudentDto student;
  final VoidCallback? onEditInterest;
  final VoidCallback? onEditParent;
  final bool useStudentCards;

  @override
  Widget build(BuildContext context) {
    final interest = student.interestProfile;
    final parent = student.parentIntake;

    if (useStudentCards) {
      return Column(
        children: [
          _InterestSectionCard(
            interest: interest,
            onEdit: onEditInterest,
          ),
          const SizedBox(height: 18),
          _ParentSectionCard(
            parent: parent,
            onEdit: onEditParent,
          ),
        ],
      );
    }

    return Column(
      children: [
        DetailSection(
          title: AppStrings.interestProfile,
          trailing: onEditInterest == null
              ? null
              : _SleekEditPill(
                  label: (interest?.completed ?? false)
                      ? AppStrings.edit
                      : AppStrings.add,
                  onTap: onEditInterest!,
                ),
          children: [_InterestBody(interest: interest, onEdit: onEditInterest)],
        ),
        const SizedBox(height: 14),
        DetailSection(
          title: AppStrings.parentIntakeTitle,
          trailing: onEditParent == null
              ? null
              : _SleekEditPill(
                  label: (parent?.hasAnswers ?? false)
                      ? AppStrings.edit
                      : AppStrings.add,
                  onTap: onEditParent!,
                ),
          children: [_ParentBody(parent: parent, onEdit: onEditParent)],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Main Section Cards (Student Profile View)
// ---------------------------------------------------------------------------

class _InterestSectionCard extends StatelessWidget {
  const _InterestSectionCard({
    required this.interest,
    this.onEdit,
  });

  final InterestProfileSummaryDto? interest;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final isCompleted = interest?.completed == true && interest!.answers.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A03162B),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Vibrant Gradient Icon Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          AppStrings.interestProfile,
                          style: TextStyle(
                            color: Color(0xFF0B192C),
                            fontWeight: FontWeight.w800,
                            fontSize: 16.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                                SizedBox(width: 3.5),
                                Text(
                                  'Complete',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 1.5),
                    const Text(
                      'Your passions, favored activities & academic favorites',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                _SleekEditPill(
                  label: isCompleted ? AppStrings.edit : AppStrings.add,
                  onTap: onEdit!,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Body
          _InterestBody(interest: interest, onEdit: onEdit),
        ],
      ),
    );
  }
}

class _ParentSectionCard extends StatelessWidget {
  const _ParentSectionCard({
    required this.parent,
    this.onEdit,
  });

  final ParentIntakeSummaryDto? parent;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final hasAnswers = parent?.hasAnswers == true;
    final isSkipped = parent?.skipped == true;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A03162B),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Family Icon Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.family_restroom_rounded,
                  color: Color(0xFF1D4ED8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          AppStrings.parentIntakeTitle,
                          style: TextStyle(
                            color: Color(0xFF0B192C),
                            fontWeight: FontWeight.w800,
                            fontSize: 16.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (hasAnswers)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                                SizedBox(width: 3.5),
                                Text(
                                  'Submitted',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isSkipped)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Text(
                              'Skipped for now',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Text(
                              'Not added',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 1.5),
                    const Text(
                      'Guardian contact, guidance preferences & future goals',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                _SleekEditPill(
                  label: hasAnswers ? AppStrings.edit : AppStrings.add,
                  onTap: onEdit!,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Body
          _ParentBody(parent: parent, onEdit: onEdit),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sleek Action Pill Button
// ---------------------------------------------------------------------------

class _SleekEditPill extends StatelessWidget {
  const _SleekEditPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5.5),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.edit_outlined,
                size: 13,
                color: Color(0xFF0B192C),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B192C),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body Components
// ---------------------------------------------------------------------------

class _InterestBody extends StatelessWidget {
  const _InterestBody({required this.interest, this.onEdit});

  final InterestProfileSummaryDto? interest;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    if (interest == null || !interest!.completed || interest!.answers.isEmpty) {
      return _EmptyOnboardingPrompt(
        icon: Icons.auto_awesome_rounded,
        iconColor: const Color(0xFFD97706),
        title: 'No interest preferences added yet',
        description: 'Set up your favorite subjects and learning activities to customize your curriculum journey.',
        buttonLabel: '+ Add Interest Profile',
        onTap: onEdit,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < interest!.answers.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _InterestQuestionCard(
            questionIndex: i,
            answer: interest!.answers[i],
          ),
        ],
      ],
    );
  }
}

class _ParentBody extends StatelessWidget {
  const _ParentBody({required this.parent, this.onEdit});

  final ParentIntakeSummaryDto? parent;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    if (parent == null || !parent!.hasAnswers) {
      final isSkipped = parent?.skipped == true;
      return _EmptyOnboardingPrompt(
        icon: Icons.family_restroom_rounded,
        iconColor: const Color(0xFF2563EB),
        title: isSkipped
            ? 'Parent details were skipped for now'
            : 'No guardian details added yet',
        description: 'Provide parent guidance preferences and contact details for official reports and receipts.',
        buttonLabel: isSkipped ? 'Complete Parent Details' : '+ Add Parent Details',
        onTap: onEdit,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < parent!.answers.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _ParentQuestionCard(
            questionIndex: i,
            answer: parent!.answers[i],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Question Cards with Creative Chips and Structured Responses
// ---------------------------------------------------------------------------

class _InterestQuestionCard extends StatelessWidget {
  const _InterestQuestionCard({
    required this.questionIndex,
    required this.answer,
  });

  final int questionIndex;
  final OnboardingAnswerItemDto answer;

  @override
  Widget build(BuildContext context) {
    final cleaned = _cleanValues(answer.values);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Q1, Q2
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${questionIndex + 1}',
                  style: const TextStyle(
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  answer.question,
                  style: const TextStyle(
                    color: Color(0xFF0B192C),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (cleaned.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '${cleaned.length} chosen',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Chips Wrap
          if (cleaned.isEmpty)
            const Text(
              '— No selections recorded',
              style: TextStyle(color: Brand.muted, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in cleaned)
                  _InterestValueChip(label: item),
              ],
            ),
        ],
      ),
    );
  }
}

class _InterestValueChip extends StatelessWidget {
  const _InterestValueChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isCustom = label.toLowerCase().startsWith('custom:') ||
        label.toLowerCase().startsWith('other:');
    final displayLabel = isCustom
        ? (label.toLowerCase().startsWith('custom:')
            ? label.substring(7).trim()
            : label.substring(6).trim())
        : label;

    if (isCustom) {
      // Distinct Amber Badge for Custom student input
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.stars_rounded,
              size: 14,
              color: Color(0xFFD97706),
            ),
            const SizedBox(width: 6),
            Text(
              'Custom: $displayLabel',
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      );
    }

    // Clean white chip with navy text and category icon
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getInterestTagIcon(label),
            size: 14,
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentQuestionCard extends StatelessWidget {
  const _ParentQuestionCard({
    required this.questionIndex,
    required this.answer,
  });

  final int questionIndex;
  final OnboardingAnswerItemDto answer;

  @override
  Widget build(BuildContext context) {
    final values = answer.values;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${questionIndex + 1}',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  answer.question,
                  style: const TextStyle(
                    color: Color(0xFF0B192C),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Response content
          if (values.isEmpty)
            const Text(
              '— No answer provided',
              style: TextStyle(color: Brand.muted, fontSize: 12),
            )
          else ...[
            for (final text in values)
              _buildParentValue(text),
          ],
        ],
      ),
    );
  }

  Widget _buildParentValue(String text) {
    // Check if the answer is a numbered series, e.g. "1. Step one. 2. Step two."
    if (_isNumberedList(text)) {
      final steps = _splitNumberedList(text);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    // Single choice / short response quote box with left colored accent bar
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3.5,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: Color(0xFF059669),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State with Prompt
// ---------------------------------------------------------------------------

class _EmptyOnboardingPrompt extends StatelessWidget {
  const _EmptyOnboardingPrompt({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.buttonLabel,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B192C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0B192C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers: Deduplication, Numbered List Parsing & Tag Icons
// ---------------------------------------------------------------------------

List<String> _cleanValues(List<String> rawValues) {
  final result = <String>[];
  final seenNormalized = <String>{};

  for (final val in rawValues) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) continue;

    final isOther = trimmed.toLowerCase().startsWith('other:');
    final actual = isOther ? trimmed.substring(6).trim() : trimmed;
    final normalized = actual.toLowerCase();

    if (seenNormalized.contains(normalized)) {
      // Deduplicate: replace standard entry with the Custom entry if both existed
      if (isOther) {
        result.removeWhere((item) => item.toLowerCase() == normalized);
        result.add('Custom: $actual');
      }
      continue;
    }

    seenNormalized.add(normalized);
    if (isOther) {
      result.add('Custom: $actual');
    } else {
      result.add(trimmed);
    }
  }

  return result;
}

bool _isNumberedList(String text) {
  final matches = RegExp(r'(?:^|\s)\d+\.\s+').allMatches(text);
  return matches.length >= 2;
}

List<String> _splitNumberedList(String text) {
  final pattern = RegExp(r'(?:^|\s)\d+\.\s+');
  final parts = text.split(pattern);
  return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
}

IconData _getInterestTagIcon(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('creative') || lower.contains('art') || lower.contains('draw')) {
    return Icons.palette_outlined;
  }
  if (lower.contains('tech') || lower.contains('computer') || lower.contains('code')) {
    return Icons.laptop_chromebook_rounded;
  }
  if (lower.contains('sport') || lower.contains('physical') || lower.contains('athletic')) {
    return Icons.directions_run_rounded;
  }
  if (lower.contains('read') || lower.contains('learn') || lower.contains('book')) {
    return Icons.menu_book_rounded;
  }
  if (lower.contains('speak') || lower.contains('music') || lower.contains('perform')) {
    return Icons.mic_none_rounded;
  }
  if (lower.contains('build') || lower.contains('make') || lower.contains('craft')) {
    return Icons.settings_suggest_rounded;
  }
  if (lower.contains('math') || lower.contains('calc')) {
    return Icons.calculate_outlined;
  }
  if (lower.contains('science') || lower.contains('chem') || lower.contains('bio')) {
    return Icons.science_outlined;
  }
  if (lower.contains('english') || lower.contains('writ')) {
    return Icons.article_outlined;
  }
  if (lower.contains('business') || lower.contains('econom')) {
    return Icons.bar_chart_rounded;
  }
  return Icons.check_circle_outline_rounded;
}
