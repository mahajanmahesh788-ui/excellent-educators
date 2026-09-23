import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_confirm_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/student_assessment_form.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';

/// Inline Discovery Questionnaire card shown on the fresh student dashboard until submission.
class MandatoryAssessmentPanel extends ConsumerStatefulWidget {
  const MandatoryAssessmentPanel({super.key});

  @override
  ConsumerState<MandatoryAssessmentPanel> createState() =>
      _MandatoryAssessmentPanelState();
}

class _MandatoryAssessmentPanelState
    extends ConsumerState<MandatoryAssessmentPanel> {
  final _selections = <String, String>{};
  var _submitting = false;
  var _submitted = false;
  String? _error;

  Future<void> _submit(AptitudeAssessmentDto assessment) async {
    final error = StudentAssessmentForm.validate(assessment, _selections);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Submit Discovery Questionnaire',
      message: 'Ready to submit your discovery responses? This will unlock your learning journey, weekly curriculum, and mentor session bookings.',
      confirmLabel: 'Complete My Discovery',
      cancelLabel: AppStrings.cancel,
    );
    if (confirmed != true) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final answers = [
        for (final entry in _selections.entries)
          {'question_id': entry.key, 'option_id': entry.value},
      ];
      await ref
          .read(assessmentRepositoryProvider)
          .submitAssessment(assessment.id, answers);
      if (mounted) {
        setState(() => _submitted = true);
      }
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _DiscoveryCompletionCard(
        onFinished: () => ref.invalidate(studentAssessmentProvider),
      );
    }

    final payload = ref.watch(studentAssessmentProvider);

    return payload.when(
      loading: () => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: StudentColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: StudentColors.indigoPrimary),
        ),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: StudentColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: StudentColors.textMuted,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(studentAssessmentProvider),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
      data: (data) {
        final assessment = data.assessment;
        if (!data.available || assessment == null) {
          return const SizedBox.shrink();
        }

        final answered = _selections.length;
        final total = assessment.questions.length;
        final progress = total == 0 ? 0.0 : (answered / total).clamp(0.0, 1.0);
        final percent = (progress * 100).round();
        final isMobile = MediaQuery.sizeOf(context).width < 768;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: StudentColors.amberBorder, // Warm amber border
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: StudentColors.textPrimary.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Mandatory Header Hero Banner (Bright, Sunny & Multi-colored)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 20 : 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.discoveryHeaderGradient,
                  ),
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Badges Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: StudentColors.amberLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: StudentColors.amberBorder,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                size: 12,
                                color: StudentColors.amberDeep,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Required First Step',
                                style: TextStyle(
                                  color: StudentColors.amberDeep,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: StudentColors.forestLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: StudentColors.forestBorder,
                            ),
                          ),
                          child: const Text(
                            'Mandatory for new students',
                            style: TextStyle(
                              color: StudentColors.forest,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Main Title
                    const Row(
                      children: [
                        Flexible(
                          child: Text(
                            'DISCOVER WHAT LIGHTS YOU UP ✨',
                            style: TextStyle(
                              color: StudentColors.forest,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start Your Journey',
                      style: TextStyle(
                        color: StudentColors.textPrimary,
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Before you book your first session, help us understand YOU.',
                      style: TextStyle(
                        color: StudentColors.forestDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: const Text(
                        'Answer these questions about your interests, hobbies, focus and mindset. There are no right or wrong answers — your responses help us understand you and guide your learning journey.',
                        style: TextStyle(
                          color: StudentColors.textSecondary,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Spark chips (distinct, cheerful education colors!)
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SparkPill(
                          label: 'Interests',
                          icon: Icons.favorite_rounded,
                          bg: StudentColors.forestLight,
                          borderColor: StudentColors.forestBorder,
                          color: StudentColors.forestDark,
                        ),
                        _SparkPill(
                          label: 'Hobbies',
                          icon: Icons.palette_rounded,
                          bg: StudentColors.successSoft,
                          borderColor: StudentColors.successBorder,
                          color: StudentColors.liveDeep,
                        ),
                        _SparkPill(
                          label: 'Focus',
                          icon: Icons.center_focus_strong_rounded,
                          bg: StudentColors.skyLight,
                          borderColor: StudentColors.skyBorder,
                          color: StudentColors.skyDark,
                        ),
                        _SparkPill(
                          label: 'Mindset',
                          icon: Icons.psychology_rounded,
                          bg: StudentColors.amberLight,
                          borderColor: StudentColors.amberBorder,
                          color: StudentColors.amberBrown,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Progress Bar Section
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: StudentColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: StudentColors.textPrimary.withValues(
                              alpha: 0.03,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Question $answered of $total completed',
                                style: const TextStyle(
                                  color: StudentColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: StudentColors.forestLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$percent%',
                                  style: const TextStyle(
                                    color: StudentColors.forest,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: StudentColors.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                StudentColors.forest,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Interactive Form Questions
              Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StudentAssessmentForm(
                      assessment: assessment,
                      selections: _selections,
                      errorText: _error,
                      onSelect: (questionId, optionId) {
                        setState(() {
                          _selections[questionId] = optionId;
                          _error = null;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // 3. Completion Submission Card
                    Container(
                      padding: EdgeInsets.all(isMobile ? 18 : 24),
                      decoration: BoxDecoration(
                        color: StudentColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: StudentColors.border),
                      ),
                      child: Column(
                        children: [
                          FilledButton(
                            onPressed: _submitting
                                ? null
                                : () => _submit(assessment),
                            style: FilledButton.styleFrom(
                              backgroundColor: StudentColors.indigoPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Complete My Discovery',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Required before you can continue.',
                            style: TextStyle(
                              color: StudentColors.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// Spark Category Pill
/// ---------------------------------------------------------------------------
class _SparkPill extends StatelessWidget {
  const _SparkPill({
    required this.label,
    required this.icon,
    this.bg,
    this.borderColor,
    this.color,
  });

  final String label;
  final IconData icon;
  final Color? bg;
  final Color? borderColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? StudentColors.forest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg ?? StudentColors.forestLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? StudentColors.forestBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Post-Submission Celebration Card
/// ---------------------------------------------------------------------------
class _DiscoveryCompletionCard extends StatelessWidget {
  const _DiscoveryCompletionCard({required this.onFinished});

  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: StudentColors.emeraldBorder, width: 1.6),
        boxShadow: StudentColors.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: StudentColors.emeraldLight,
              shape: BoxShape.circle,
              border: Border.all(color: StudentColors.emeraldBorder, width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.celebration_rounded,
                color: StudentColors.emeraldDark,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '🎉 You\'re all set!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: StudentColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ve got to know you a little better.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: StudentColors.indigoPrimary,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: const Text(
              'Your learning journey is now unlocked. You can now access your weekly curriculum, learning journal, and book your first 1-on-1 mentor session!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: StudentColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onFinished,
            style: FilledButton.styleFrom(
              backgroundColor: StudentColors.indigoPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text(
              'Continue to Dashboard',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
