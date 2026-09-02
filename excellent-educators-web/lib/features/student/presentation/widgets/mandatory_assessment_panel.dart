import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/student_assessment_form.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inline assessment card shown on the student dashboard until first submission.
class MandatoryAssessmentPanel extends ConsumerStatefulWidget {
  const MandatoryAssessmentPanel({super.key});

  @override
  ConsumerState<MandatoryAssessmentPanel> createState() => _MandatoryAssessmentPanelState();
}

class _MandatoryAssessmentPanelState extends ConsumerState<MandatoryAssessmentPanel> {
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

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Submit your assessment?'),
        content: const Text(
          'This is a one-time aptitude assessment. Once submitted, you cannot change your answers.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Review')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit now')),
        ],
      ),
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
        for (final entry in _selections.entries) {'question_id': entry.key, 'option_id': entry.value},
      ];
      await ref.read(assessmentRepositoryProvider).submitAssessment(assessment.id, answers);
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
      return _CompletionCard(
        onFinished: () => ref.invalidate(studentAssessmentProvider),
      );
    }

    final payload = ref.watch(studentAssessmentProvider);

    return payload.when(
      loading: () => const StudentSectionCard(
        icon: Icons.quiz_rounded,
        title: 'Aptitude assessment',
        child: Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Brand.gold))),
      ),
      error: (error, _) => StudentSectionCard(
        icon: Icons.cloud_off_rounded,
        title: 'Aptitude assessment',
        child: Column(
          children: [
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(studentAssessmentProvider),
              child: const Text('Retry'),
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
        final progress = total == 0 ? 0.0 : answered / total;

        return StudentSectionCard(
          icon: Icons.auto_awesome_rounded,
          title: 'One-time aptitude assessment',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0E2744), Color(0xFF1A3D66)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete this assessment to unlock your dashboard.',
                      style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        color: Brand.gold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$answered of $total questions answered',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _submitting ? null : () => _submit(assessment),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Brand.navyDeep),
                      )
                    : const Text('Submit assessment'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompletionCard extends StatefulWidget {
  const _CompletionCard({required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<_CompletionCard> createState() => _CompletionCardState();
}

class _CompletionCardState extends State<_CompletionCard> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 2), widget.onFinished);
  }

  @override
  Widget build(BuildContext context) {
    return StudentSectionCard(
      icon: Icons.check_circle_rounded,
      title: 'Assessment complete',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 40),
          ),
          const SizedBox(height: 12),
          const Text(
            'Thank you! Your teachers will review your assessment and share feedback with you on your dashboard.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Brand.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}
