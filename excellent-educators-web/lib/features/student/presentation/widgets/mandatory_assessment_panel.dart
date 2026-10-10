import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/errors/api_error_message.dart';
import 'package:excellent_educators_web/core/widgets/app_confirm_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/student_assessment_form.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/ten_growth_pillars.dart';

/// Inline Discovery Questionnaire card shown until the current-level assessment is submitted.
class MandatoryAssessmentPanel extends ConsumerStatefulWidget {
  const MandatoryAssessmentPanel({super.key, required this.student});

  final StudentDto student;

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

  bool get _continuing => widget.student.isContinuingLearner;

  String get _levelLabel {
    final label = widget.student.level?.label.trim() ?? '';
    return label.isNotEmpty ? label : AppStrings.yourNextLevel;
  }

  Future<void> _submit(AptitudeAssessmentDto assessment) async {
    final error = StudentAssessmentForm.validate(assessment, _selections);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    final confirmed = await showAppConfirmDialog(
      context,
      title: _continuing
          ? AppStrings.submitLevelCheckInTitle(_levelLabel)
          : AppStrings.submitDiscoveryQuestionnaire,
      message: _continuing
          ? AppStrings.readyToSubmitLevelCheckIn(_levelLabel)
          : AppStrings.readyToSubmitDiscoveryResponses,
      confirmLabel: _continuing
          ? AppStrings.completeLevelCheckIn
          : AppStrings.completeMyDiscovery,
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
        continuing: _continuing,
        levelLabel: _levelLabel,
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
            Text(friendlyErrorMessage(error), textAlign: TextAlign.center),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _continuing
                                    ? Icons.trending_up_rounded
                                    : Icons.lock_rounded,
                                size: 12,
                                color: StudentColors.amberDeep,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _continuing
                                    ? AppStrings.nextLevelCheckpoint
                                    : AppStrings.requiredFirstStep,
                                style: const TextStyle(
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
                          child: Text(
                            _continuing
                                ? AppStrings.requiredForLevel(_levelLabel)
                                : AppStrings.mandatoryForNewStudents,
                            style: const TextStyle(
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _continuing
                                ? AppStrings.sameTenPillarsNewLevelBanner
                                : AppStrings.discoverWhatLightsYouUpBanner,
                            style: const TextStyle(
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
                      _continuing
                          ? AppStrings.continueIntoLevel(_levelLabel)
                          : AppStrings.startYourJourney,
                      style: TextStyle(
                        color: StudentColors.textPrimary,
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _continuing
                          ? AppStrings.levelledUpRevisitTenPillars
                          : AppStrings.beforeYouBookYourFirstSession,
                      style: const TextStyle(
                        color: StudentColors.forestDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Text(
                        _continuing
                            ? AppStrings.sameTenPillarsAtEveryLevel
                            : AppStrings.answerAcrossSameTenPillars,
                        style: const TextStyle(
                          color: StudentColors.textSecondary,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Same 10 pillars at every level
                    const TenGrowthPillars(),

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
                                AppStrings.questionProgressCompleted(
                                  answered,
                                  total,
                                ),
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
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _continuing
                                            ? AppStrings.completeLevelCheckIn
                                            : AppStrings.completeMyDiscovery,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _continuing
                                ? AppStrings.requiredBeforeLevelUnlocks(
                                    _levelLabel,
                                  )
                                : AppStrings.requiredBeforeYouCanContinue,
                            style: const TextStyle(
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
/// Post-Submission Celebration Card
/// ---------------------------------------------------------------------------
class _DiscoveryCompletionCard extends StatelessWidget {
  const _DiscoveryCompletionCard({
    required this.onFinished,
    required this.continuing,
    required this.levelLabel,
  });

  final VoidCallback onFinished;
  final bool continuing;
  final String levelLabel;

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
          Text(
            continuing
                ? AppStrings.levelUnlockedCelebration(levelLabel)
                : AppStrings.youreAllSet,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: StudentColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            continuing
                ? AppStrings.mentorsCanGuideWithLatestCheckIn
                : AppStrings.weveGotToKnowYouBetter,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: StudentColors.indigoPrimary,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              continuing
                  ? AppStrings.weeklyCurriculumReadyForLevel(levelLabel)
                  : AppStrings.learningJourneyNowUnlocked,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
              AppStrings.continueToDashboard,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
