import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/onboarding/data/dto/onboarding_dtos.dart';
import 'package:excellent_educators_web/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:excellent_educators_web/features/onboarding/presentation/widgets/onboarding_scaffold_layout.dart';
import 'package:excellent_educators_web/features/onboarding/presentation/widgets/onboarding_static_content.dart';
import 'package:excellent_educators_web/features/onboarding/presentation/widgets/onboarding_stepper_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentParentIntakePage extends ConsumerStatefulWidget {
  const StudentParentIntakePage({super.key});

  @override
  ConsumerState<StudentParentIntakePage> createState() =>
      _StudentParentIntakePageState();
}

class _StudentParentIntakePageState
    extends ConsumerState<StudentParentIntakePage> {
  final _textAnswers = <String, TextEditingController>{};
  final _optionAnswers = <String, String?>{};
  var _submitting = false;
  var _initializedSavedAnswers = false;

  void _initSavedAnswers(ParentIntakeDto intake) {
    if (_initializedSavedAnswers) return;
    _initializedSavedAnswers = true;
    if (intake.savedAnswers.isNotEmpty) {
      for (final entry in intake.savedAnswers.entries) {
        final qId = entry.key;
        final ans = entry.value;
        if (ans.textAnswer.isNotEmpty) {
          _textController(qId).text = ans.textAnswer;
        }
        if (ans.optionId != null && ans.optionId!.isNotEmpty) {
          _optionAnswers[qId] = ans.optionId;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _textAnswers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _textController(String questionId) {
    return _textAnswers.putIfAbsent(questionId, TextEditingController.new);
  }

  Future<void> _submit(List<ParentQuestionDto> questions) async {
    if (_submitting) return;
    final answers = <Map<String, dynamic>>[];
    for (final question in questions) {
      if (question.isText) {
        final text = _textController(question.id).text.trim();
        if (text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please answer: "${question.questionText}"'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        answers.add({
          'question_id': question.id,
          'text_answer': text,
        });
        continue;
      }

      final optionId = _optionAnswers[question.id];
      if (optionId == null || optionId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select an option for "${question.questionText}".'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      answers.add({
        'question_id': question.id,
        'option_id': optionId,
      });
    }

    final returnToProfile = _editingExisting;
    setState(() => _submitting = true);
    try {
      final user = await ref
          .read(onboardingRepositoryProvider)
          .submitParentIntake(answers);
      ref.read(authControllerProvider.notifier).applyUser(user);
      ref.invalidate(studentProfileProvider);
      if (!mounted) return;
      context.go(
        returnToProfile
            ? RoutePaths.studentProfile
            : RoutePaths.studentDashboard,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool get _editingExisting {
    final intake = ref.read(studentParentIntakeProvider).asData?.value;
    return intake != null && (intake.completed || intake.skipped);
  }

  Future<void> _skip() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final user = await ref
          .read(onboardingRepositoryProvider)
          .skipParentIntake();
      ref.read(authControllerProvider.notifier).applyUser(user);
      ref.invalidate(studentProfileProvider);
      if (!mounted) return;
      context.go(RoutePaths.studentDashboard);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentParentIntakeProvider);
    final compact = MediaQuery.sizeOf(context).width < 640;

    return OnboardingScaffoldLayout(
      sideTitlePrefix: OnboardingStaticContent.step2SideTitlePrefix,
      sideTitleHighlight: OnboardingStaticContent.step2SideTitleHighlight,
      sideDescription: OnboardingStaticContent.step2SideDescription,
      sideStickyWords: OnboardingStaticContent.step2StickyWords,
      formContent: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(48),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(studentParentIntakeProvider),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
        data: (intake) {
          if (intake.questions.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.go(RoutePaths.studentDashboard);
            });
            return const SizedBox.shrink();
          }
          _initSavedAnswers(intake);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Progress Stepper (Interests completed -> Parent Details active)
              OnboardingStepperHeader(
                currentStep: 2,
                compact: compact,
              ),

              const SizedBox(height: 18),

              // Kicker & Heading
              Text(
                OnboardingStaticContent.step2Kicker,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    fontFamily: 'sans-serif',
                  ),
                  children: [
                    TextSpan(
                      text: OnboardingStaticContent.step2HeadingPrefix,
                      style: TextStyle(color: Color(0xFF0B192C)),
                    ),
                    TextSpan(
                      text: OnboardingStaticContent.step2HeadingHighlight,
                      style: TextStyle(color: Color(0xFFF59E0B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                OnboardingStaticContent.step2Description,
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 14),

              // Questions List
              for (var qIndex = 0; qIndex < intake.questions.length; qIndex++) ...[
                _buildParentQuestionCard(
                  question: intake.questions[qIndex],
                  questionIndex: qIndex,
                  compact: compact,
                ),
                const SizedBox(height: 14),
              ],

              const SizedBox(height: 4),

              // Primary Action Button (Complete Setup)
              FilledButton(
                onPressed: _submitting ? null : () => _submit(intake.questions),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B192C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            (intake.completed || intake.skipped)
                                ? AppStrings.saveAndReturnToProfile
                                : 'Complete Setup & Open Dashboard',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            (intake.completed || intake.skipped)
                                ? Icons.check_rounded
                                : Icons.rocket_launch_rounded,
                            size: 16,
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 8),

              // Bottom Actions: Back to Interests & Skip for Now
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _submitting
                        ? null
                        : () => (intake.completed || intake.skipped)
                            ? context.go(RoutePaths.studentProfile)
                            : context.go(RoutePaths.studentInterestProfile),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 14,
                      color: Color(0xFF0B192C),
                    ),
                    label: Text(
                      (intake.completed || intake.skipped)
                          ? '← Back to Profile'
                          : '← Back to Interests',
                      style: const TextStyle(
                        color: Color(0xFF0B192C),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!intake.completed && !intake.skipped)
                    TextButton(
                      onPressed: _submitting ? null : _skip,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      child: const Text(
                        AppStrings.skipForNow,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParentQuestionCard({
    required ParentQuestionDto question,
    required int questionIndex,
    required bool compact,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular Peach Number Badge
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${questionIndex + 1}',
                  style: const TextStyle(
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.questionText,
                      style: TextStyle(
                        fontSize: compact ? 13.5 : 14.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B192C),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      question.isText
                          ? 'Enter details below'
                          : 'Select an option below',
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Question Input / Option Grid
          if (question.isText)
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 84,
                maxHeight: 200,
              ),
              child: TextField(
                controller: _textController(question.id),
                minLines: 3,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Enter ${question.questionText.toLowerCase()}...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF0B192C), width: 1.5),
                  ),
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.4),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final colCount = width > 540 ? 3 : (width > 340 ? 2 : 1);
                final spacing = 8.0;
                final itemWidth = (width - (spacing * (colCount - 1))) / colCount;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final option in question.options)
                      SizedBox(
                        width: itemWidth,
                        child: _ParentOptionCard(
                          label: option.optionText,
                          selected: _optionAnswers[question.id] == option.id,
                          onTap: () => setState(() => _optionAnswers[question.id] = option.id),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ParentOptionCard extends StatelessWidget {
  const _ParentOptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeInOut,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0B192C) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF0B192C) : const Color(0xFFE2E8F0),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x220B192C),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF1E293B),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12.5,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: Color(0xFFF59E0B),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
