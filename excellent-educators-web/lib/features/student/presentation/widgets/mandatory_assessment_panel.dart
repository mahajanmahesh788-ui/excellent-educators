import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_confirm_dialog.dart';
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

    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Submit assessment?',
      message: 'This is a one-time snapshot of what you enjoy, how you focus, and how you think. You cannot change answers after you submit.',
      confirmLabel: 'Submit',
      cancelLabel: 'Cancel',
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
        icon: Icons.auto_awesome_rounded,
        title: 'Discover what lights you up',
        child: Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Brand.gold))),
      ),
      error: (error, _) => StudentSectionCard(
        icon: Icons.cloud_off_rounded,
        title: 'Discover what lights you up',
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
          title: 'Discover what lights you up',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0E2744), Color(0xFF1A3D66), Color(0xFF3D2E14)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your interests. Your hobbies. Your focus. Your mindset.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'There are no right answers — this is about you. Tell us what you enjoy, how you like to spend time, what holds your attention, and how you think. Your teachers will use this to guide you in a way that fits who you already are.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.84), fontSize: 13.5, height: 1.45),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _SparkChip('Interests'),
                        _SparkChip('Hobbies'),
                        _SparkChip('Focus'),
                        _SparkChip('Mindset'),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                      '$answered of $total moments captured',
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
                    : const Text('Submit'),
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
      title: 'You have been heard',
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
            'Thank you for sharing what you love and how you think. Your teachers will use this to guide you — and you will see their notes here on your dashboard.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Brand.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _SparkChip extends StatelessWidget {
  const _SparkChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Brand.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Brand.gold.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFFE8D19A), fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
