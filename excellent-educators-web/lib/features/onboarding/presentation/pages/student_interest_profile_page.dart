import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/onboarding/data/dto/onboarding_dtos.dart';
import 'package:excellent_educators_web/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:excellent_educators_web/features/onboarding/presentation/widgets/onboarding_scaffold_layout.dart';
import 'package:excellent_educators_web/features/onboarding/presentation/widgets/onboarding_static_content.dart';
import 'package:excellent_educators_web/features/onboarding/presentation/widgets/onboarding_stepper_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentInterestProfilePage extends ConsumerStatefulWidget {
  const StudentInterestProfilePage({super.key});

  @override
  ConsumerState<StudentInterestProfilePage> createState() =>
      _StudentInterestProfilePageState();
}

class _StudentInterestProfilePageState
    extends ConsumerState<StudentInterestProfilePage> {
  final _selected = <String, Set<String>>{};
  final _otherEnabled = <String, bool>{};
  final _otherText = <String, TextEditingController>{};
  var _submitting = false;
  var _initializedSavedAnswers = false;

  void _initSavedAnswers(InterestProfileDto profile) {
    if (_initializedSavedAnswers) return;
    _initializedSavedAnswers = true;
    if (profile.savedAnswers.isNotEmpty) {
      for (final entry in profile.savedAnswers.entries) {
        final qId = entry.key;
        final ans = entry.value;
        if (ans.optionIds.isNotEmpty) {
          _selected[qId] = ans.optionIds.toSet();
        }
        if (ans.otherText.isNotEmpty) {
          _otherEnabled[qId] = true;
          _otherController(qId).text = ans.otherText;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _otherText.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _otherController(String questionId) {
    return _otherText.putIfAbsent(questionId, TextEditingController.new);
  }

  int _selectionCount(String questionId) {
    final selected = _selected[questionId]?.length ?? 0;
    final otherOn = _otherEnabled[questionId] == true;
    return selected + (otherOn ? 1 : 0);
  }

  void _toggleOption({
    required InterestQuestionDto question,
    required String optionId,
  }) {
    final selected = _selected.putIfAbsent(question.id, () => <String>{});
    if (selected.contains(optionId)) {
      setState(() => selected.remove(optionId));
      return;
    }
    if (_selectionCount(question.id) >= question.maxSelections) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can select up to ${question.maxSelections} options for this question.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => selected.add(optionId));
  }

  void _toggleOther(InterestQuestionDto question) {
    final enabled = _otherEnabled[question.id] == true;
    if (enabled) {
      setState(() => _otherEnabled[question.id] = false);
      return;
    }
    if (_selectionCount(question.id) >= question.maxSelections) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can select up to ${question.maxSelections} options for this question.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _otherEnabled[question.id] = true);
  }

  Future<void> _submit(List<InterestQuestionDto> questions) async {
    if (_submitting) return;
    final answers = <Map<String, dynamic>>[];
    for (final question in questions) {
      final optionIds = _selected[question.id]?.toList() ?? <String>[];
      final otherOn = question.allowOther && _otherEnabled[question.id] == true;
      final other = otherOn ? _otherController(question.id).text.trim() : '';
      if (otherOn && (other.length < 2)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('${AppStrings.otherOption}: Please enter at least 2 characters.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (optionIds.isEmpty && !otherOn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select at least 1 option for "${question.questionText}".'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      answers.add({
        'question_id': question.id,
        'option_ids': optionIds,
        if (otherOn) 'other_text': other,
      });
    }

    setState(() => _submitting = true);
    try {
      final user = await ref
          .read(onboardingRepositoryProvider)
          .submitInterestProfile(answers);
      ref.read(authControllerProvider.notifier).applyUser(user);
      ref.invalidate(studentProfileProvider);
      if (!mounted) return;
      final next = user.nextOnboardingPath;
      context.go(next ?? RoutePaths.studentProfile);
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
    final async = ref.watch(studentInterestProfileProvider);
    final compact = MediaQuery.sizeOf(context).width < 640;

    return OnboardingScaffoldLayout(
      sideTitlePrefix: OnboardingStaticContent.step1SideTitlePrefix,
      sideTitleHighlight: OnboardingStaticContent.step1SideTitleHighlight,
      sideDescription: OnboardingStaticContent.step1SideDescription,
      sideStickyWords: OnboardingStaticContent.step1StickyWords,
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
              onPressed: () => ref.invalidate(studentInterestProfileProvider),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
        data: (profile) {
          if (profile.questions.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.go(RoutePaths.studentDashboard);
            });
            return const SizedBox.shrink();
          }
          _initSavedAnswers(profile);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Progress Stepper (Interests -> Parent Details)
              OnboardingStepperHeader(
                currentStep: 1,
                compact: compact,
              ),

              const SizedBox(height: 18),

              // Kicker & Heading
              Text(
                OnboardingStaticContent.step1Kicker,
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
                      text: OnboardingStaticContent.step1HeadingPrefix,
                      style: TextStyle(color: Color(0xFF0B192C)),
                    ),
                    TextSpan(
                      text: OnboardingStaticContent.step1HeadingHighlight,
                      style: TextStyle(color: Color(0xFFF59E0B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                OnboardingStaticContent.step1Description,
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 12),

              // Green Friendly Highlight Tip Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1.5),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        OnboardingStaticContent.step1TipBanner,
                        style: TextStyle(
                          color: const Color(0xFF166534),
                          fontSize: compact ? 11 : 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Questions List
              for (var qIndex = 0; qIndex < profile.questions.length; qIndex++) ...[
                _buildQuestionCard(
                  question: profile.questions[qIndex],
                  questionIndex: qIndex,
                  compact: compact,
                ),
                const SizedBox(height: 14),
              ],

              const SizedBox(height: 4),

              // Bottom Continue Action Button
              FilledButton(
                onPressed: _submitting ? null : () => _submit(profile.questions),
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
                            profile.completed
                                ? AppStrings.saveAndReturnToProfile
                                : 'Continue to Parent Details',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            profile.completed
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 16,
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard({
    required InterestQuestionDto question,
    required int questionIndex,
    required bool compact,
  }) {
    final chosen = _selectionCount(question.id);
    final otherOn = question.allowOther && _otherEnabled[question.id] == true;

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
          // Question Header Row: Number Badge, Question Text & Counter Chip
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
              // Question Titles
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
                      'Select the activities you like the most.',
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Counter Badge: "X of Y chosen"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  '$chosen of ${question.maxSelections} chosen',
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Options Grid
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
                  for (final option in question.options) ...[
                    SizedBox(
                      width: itemWidth,
                      child: _InterestOptionCard(
                        label: option.optionText,
                        selected: _selected[question.id]?.contains(option.id) == true,
                        onTap: () => _toggleOption(
                          question: question,
                          optionId: option.id,
                        ),
                      ),
                    ),
                  ],

                  // Other option button
                  if (question.allowOther) ...[
                    SizedBox(
                      width: itemWidth,
                      child: _InterestOptionCard(
                        label: '... Other',
                        selected: otherOn,
                        onTap: () => _toggleOther(question),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),

          // Other option expand input
          if (otherOn) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.edit_note_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Your Custom Interest',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B192C),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _toggleOther(question),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _otherController(question.id),
                    maxLength: 25,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g. Robotics, Astronomy, Chess, Creative Writing...',
                      hintStyle: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w400,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF0B192C),
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B192C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InterestOptionCard extends StatelessWidget {
  const _InterestOptionCard({
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
