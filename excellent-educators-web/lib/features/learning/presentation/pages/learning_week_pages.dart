import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/assessment_result_view.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class StudentLearningWeekPage extends ConsumerStatefulWidget {
  const StudentLearningWeekPage({
    super.key,
    required this.journeyId,
    required this.week,
  });

  final String journeyId;
  final int week;

  @override
  ConsumerState<StudentLearningWeekPage> createState() =>
      _StudentLearningWeekPageState();
}

class _StudentLearningWeekPageState
    extends ConsumerState<StudentLearningWeekPage> {
  final _answers = <String, String>{};
  final _textControllers = <String, TextEditingController>{};
  final _questionKeys = <int, GlobalKey>{};
  var _submitting = false;
  String? _error;

  TextEditingController _textControllerFor(String questionId, {String? seed}) {
    return _textControllers.putIfAbsent(
      questionId,
      () => TextEditingController(text: seed ?? ''),
    );
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _scrollToQuestion(int index) {
    final key = _questionKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.08,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekValue = ref.watch(
      studentLearningWeekProvider((
        journeyId: widget.journeyId,
        week: widget.week,
      )),
    );

    return StudentScaffold(
      title: 'Week ${widget.week} Assignment',
      backTo: RoutePaths.studentJournal,
      body: weekValue.when(
        loading: () => ListView(
          children: const [
            AcademySkeleton(height: 60),
            SizedBox(height: 16),
            AcademySkeleton(height: 220),
            SizedBox(height: 16),
            AcademySkeleton(height: 180),
          ],
        ),
        error: (_, _) => AcademyError(
          onRetry: () => ref.invalidate(
            studentLearningWeekProvider((
              journeyId: widget.journeyId,
              week: widget.week,
            )),
          ),
        ),
        data: (week) {
          final totalQuestions = week.questions.length;
          final latestAttempt = week.attempts.lastOrNull;

          // Prepopulate answers from latest attempt if available and not yet touched
          if (_answers.isEmpty &&
              _textControllers.isEmpty &&
              latestAttempt != null &&
              week.canSubmit) {
            for (final q in week.questions) {
              if (q.isText) {
                final text = latestAttempt.textAnswerFor(q.id);
                if (text != null) {
                  _textControllerFor(q.id, seed: text);
                }
              } else {
                final optId = latestAttempt.optionIdFor(q.id);
                if (optId != null) {
                  _answers[q.id] = optId;
                }
              }
            }
          }

          bool isAnswered(LearningQuestionDto q) {
            if (q.isText) {
              if (week.canSubmit) {
                return (_textControllers[q.id]?.text.trim().isNotEmpty ??
                    false);
              }
              return latestAttempt?.textAnswerFor(q.id) != null;
            }
            if (week.canSubmit) {
              return _answers.containsKey(q.id);
            }
            return latestAttempt?.optionIdFor(q.id) != null;
          }

          final answeredCount = week.questions.where(isAnswered).length;
          final isMobile = MediaQuery.sizeOf(context).width < 600;

          for (var i = 0; i < totalQuestions; i++) {
            _questionKeys.putIfAbsent(i, () => GlobalKey());
          }

          return ListView(
            padding: EdgeInsets.only(bottom: isMobile ? 32 : 48),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Week ${week.weekNumber} Assignment',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Academy.ink,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          week.completed
                              ? AppStrings
                                    .assignmentCompletedYourSelectedAnswersAreShownBelow
                              : !week.canSubmit
                              ? AppStrings
                                    .submissionsClosedYourSelectedAnswersAreShownBelow
                              : 'Attempt ${week.attemptsUsed + 1} of ${week.attemptsMax} · All questions on this screen.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Academy.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Brand.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Brand.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      week.level.name.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF6B4D00),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Weekly video card (if exists)
              if (week.hasVideo && week.videoUrl != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Brand.navy,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Brand.navy.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Brand.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Brand.gold,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.weeklyVideoLesson,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              AppStrings.recommendedToWatchBeforeSubmitting,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Brand.gold,
                          foregroundColor: Brand.navy,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () => launchUrl(
                          Uri.parse(week.videoUrl!),
                          webOnlyWindowName: AppStrings.blank,
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 15),
                        label: const Text(AppStrings.watchVideo),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Completion / Closed Status Banner (when submissions are finished)
              if (!week.canSubmit && week.completed) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF2E7D32),
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.assignmentCompleted,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              AppStrings.yourSelectedAnswersAreDisplayedBelow,
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (!week.canSubmit &&
                  week.attemptsUsed >= week.attemptsMax) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFCC80)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFE65100),
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.maximumAttemptsReached,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFFE65100),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              AppStrings
                                  .submissionsAreClosedYourSelectedAnswersAreDisplayedBelow,
                              style: TextStyle(
                                color: Color(0xFFE65100),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Single-Screen Space-Friendly Question & Answer View (with selected data)
              if (week.questions.isNotEmpty) ...[
                // Top Progress indicator bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Academy.line),
                    boxShadow: [
                      BoxShadow(
                        color: Brand.navy.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            size: 18,
                            color: Brand.navy,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            AppStrings.questions,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Academy.ink,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: answeredCount == totalQuestions
                                  ? const Color(0xFFE8F5E9)
                                  : Brand.gold.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: answeredCount == totalQuestions
                                    ? const Color(0xFF81C784)
                                    : Brand.gold.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              '$answeredCount / $totalQuestions',
                              style: TextStyle(
                                color: answeredCount == totalQuestions
                                    ? const Color(0xFF1B5E20)
                                    : const Color(0xFF6B4D00),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: totalQuestions > 0
                              ? (answeredCount / totalQuestions)
                              : 0.0,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFEFE9DC),
                          valueColor: AlwaysStoppedAnimation(
                            answeredCount == totalQuestions
                                ? const Color(0xFF2E7D32)
                                : Brand.gold,
                          ),
                        ),
                      ),
                      if (totalQuestions > 1) ...[
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (var i = 0; i < totalQuestions; i++) ...[
                                if (i > 0) const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _scrollToQuestion(i),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAnswered(week.questions[i])
                                          ? const Color(0xFFE8F5E9)
                                          : const Color(0xFFF4F1EA),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isAnswered(week.questions[i])
                                            ? const Color(0xFF81C784)
                                            : Academy.line,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isAnswered(week.questions[i])) ...[
                                          const Icon(
                                            Icons.check_rounded,
                                            size: 12,
                                            color: Color(0xFF2E7D32),
                                          ),
                                          const SizedBox(width: 3),
                                        ],
                                        Text(
                                          'Q${i + 1}',
                                          style: TextStyle(
                                            color:
                                                isAnswered(week.questions[i])
                                                ? const Color(0xFF1B5E20)
                                                : Academy.muted,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Compact Question Cards with selected data
                for (var i = 0; i < totalQuestions; i++)
                  _CompactQuestionCard(
                    key: _questionKeys[i],
                    index: i,
                    question: week.questions[i],
                    selectedOptionId: week.questions[i].isText
                        ? null
                        : (week.canSubmit
                              ? _answers[week.questions[i].id]
                              : latestAttempt?.optionIdFor(
                                  week.questions[i].id,
                                )),
                    textController: week.questions[i].isText && week.canSubmit
                        ? _textControllerFor(week.questions[i].id)
                        : null,
                    textAnswer: week.questions[i].isText
                        ? (week.canSubmit
                              ? _textControllers[week.questions[i].id]?.text
                              : latestAttempt?.textAnswerFor(
                                  week.questions[i].id,
                                ))
                        : null,
                    isReadOnly: !week.canSubmit,
                    showResult:
                        !week.canSubmit &&
                        (week.completed || week.attemptsUsed > 0),
                    onOptionSelected:
                        week.canSubmit && week.questions[i].isOptions
                        ? (optId) {
                            setState(() {
                              _answers[week.questions[i].id] = optId;
                              _error = null;
                            });
                          }
                        : null,
                    onTextChanged: week.canSubmit && week.questions[i].isText
                        ? (_) => setState(() => _error = null)
                        : null,
                  ),

                // Error message banner
                if (_error != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Submit action when assignment is still open
                if (week.canSubmit)
                  Builder(
                    builder: (context) {
                      final allAnswered = answeredCount == totalQuestions;
                      final statusTitle = allAnswered
                          ? (totalQuestions == 1
                              ? 'All questions answered!'
                              : 'All $totalQuestions questions answered!')
                          : (totalQuestions == 1
                              ? '$answeredCount of 1 question answered'
                              : '$answeredCount of $totalQuestions answered');
                      return Container(
                    padding: EdgeInsets.all(isMobile ? 14 : 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: allAnswered
                            ? const Color(0xFFCDEBD6)
                            : Academy.line,
                        width: allAnswered ? 1.4 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: allAnswered
                              ? const Color(0xFF16A34A).withValues(alpha: 0.05)
                              : Brand.navy.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: allAnswered
                                          ? const Color(0xFFE8F5E9)
                                          : Brand.gold.withValues(alpha: 0.16),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      allAnswered
                                          ? Icons.check_circle_rounded
                                          : Icons.pending_actions_rounded,
                                      color: allAnswered
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFF8C6600),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          statusTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: Academy.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          allAnswered
                                              ? AppStrings
                                                  .youAreReadyToSubmitYourAssignment
                                              : AppStrings
                                                  .selectAnswersForTheRemainingQuestionsAbove,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: Academy.muted,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Brand.navy,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _submitting
                                      ? null
                                      : () => _submit(week),
                                  icon: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 18,
                                    color: Brand.gold,
                                  ),
                                  label: Text(
                                    _submitting
                                        ? AppStrings.submitting
                                        : AppStrings.submitAssignment,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: allAnswered
                                      ? const Color(0xFFE8F5E9)
                                      : Brand.gold.withValues(alpha: 0.16),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  allAnswered
                                      ? Icons.check_circle_rounded
                                      : Icons.pending_actions_rounded,
                                  color: allAnswered
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFF8C6600),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      statusTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: Academy.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      allAnswered
                                          ? AppStrings
                                              .youAreReadyToSubmitYourAssignment
                                          : AppStrings
                                              .selectAnswersForTheRemainingQuestionsAbove,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Academy.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Brand.navy,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _submitting
                                    ? null
                                    : () => _submit(week),
                                icon: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 18,
                                  color: Brand.gold,
                                ),
                                label: Text(
                                  _submitting
                                      ? AppStrings.submitting
                                      : AppStrings.submitAssignment,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  );
                    },
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(LearningWeekDto week) async {
    final unansweredIndex = week.questions.indexWhere((q) {
      if (q.isText) {
        return (_textControllers[q.id]?.text.trim().isEmpty ?? true);
      }
      return !_answers.containsKey(q.id);
    });
    if (unansweredIndex != -1) {
      _scrollToQuestion(unansweredIndex);
      final remaining = week.questions.where((q) {
        if (q.isText) {
          return (_textControllers[q.id]?.text.trim().isEmpty ?? true);
        }
        return !_answers.containsKey(q.id);
      }).length;
      setState(() {
        _error =
            'Please answer all questions before submitting ($remaining remaining).';
      });
      return;
    }

    for (final question in week.questions.where((q) => q.isText)) {
      final text = _textControllers[question.id]?.text.trim() ?? '';
      if (text.length > 250) {
        setState(() {
          _error = AppStrings.enterATextAnswerMax250;
        });
        return;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(learningRepositoryProvider)
          .submitWeek(
            journeyId: widget.journeyId,
            week: widget.week,
            answers: [
              for (final question in week.questions)
                if (question.isText)
                  {
                    'question_id': question.id,
                    'text_answer':
                        _textControllers[question.id]?.text.trim() ?? '',
                  }
                else
                  {
                    'question_id': question.id,
                    'option_id': _answers[question.id],
                  },
            ],
          );
      _answers.clear();
      for (final controller in _textControllers.values) {
        controller.dispose();
      }
      _textControllers.clear();
      ref.invalidate(
        studentLearningWeekProvider((
          journeyId: widget.journeyId,
          week: widget.week,
        )),
      );
      ref.invalidate(studentLearningJournalProvider);
      ref.invalidate(studentLearningDashboardProvider);

      if (!mounted) return;

      // Submit successful popup dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF81C784),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF2E7D32),
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    AppStrings.submittedSuccessfully,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Academy.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your answers for Week ${widget.week} have been recorded.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Academy.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Brand.navy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        completeAndReturnTo(
                          context,
                          RoutePaths.studentJournal,
                        );
                      },
                      child: const Text(
                        AppStrings.ok,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _CompactQuestionCard extends StatelessWidget {
  const _CompactQuestionCard({
    super.key,
    required this.index,
    required this.question,
    this.selectedOptionId,
    this.textController,
    this.textAnswer,
    this.isReadOnly = false,
    this.showResult = false,
    this.onOptionSelected,
    this.onTextChanged,
  });

  final int index;
  final LearningQuestionDto question;
  final String? selectedOptionId;
  final TextEditingController? textController;
  final String? textAnswer;
  final bool isReadOnly;
  final bool showResult;
  final ValueChanged<String>? onOptionSelected;
  final ValueChanged<String>? onTextChanged;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
  static const _maxTextLength = 250;

  @override
  Widget build(BuildContext context) {
    final displayedText = textController?.text ?? textAnswer ?? '';
    final isAnswered = question.isText
        ? displayedText.trim().isNotEmpty
        : selectedOptionId != null;

    Color borderColor;
    double borderWidth;
    if (isAnswered) {
      borderColor = const Color(0xFFA5D6A7);
      borderWidth = 1.4;
    } else {
      borderColor = Academy.line;
      borderWidth = 1.0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Brand.navy.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isAnswered ? const Color(0xFF2E7D32) : Brand.navy,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: isAnswered
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Academy.ink,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (question.isText)
            _textAnswerField(displayedText)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 520;
                const gap = 8.0;

                if (isWide) {
                  final cardWidth = (constraints.maxWidth - gap) / 2;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (
                        var optIndex = 0;
                        optIndex < question.options.length;
                        optIndex++
                      )
                        SizedBox(
                          width: cardWidth,
                          child: _CompactOptionTile(
                            letter: optIndex < _letters.length
                                ? _letters[optIndex]
                                : '${optIndex + 1}',
                            option: question.options[optIndex],
                            selected:
                                selectedOptionId ==
                                question.options[optIndex].id,
                            isReadOnly: isReadOnly,
                            showResult: showResult,
                            onTap: onOptionSelected != null
                                ? () => onOptionSelected!(
                                    question.options[optIndex].id,
                                  )
                                : null,
                          ),
                        ),
                    ],
                  );
                }

                return Column(
                  children: [
                    for (
                      var optIndex = 0;
                      optIndex < question.options.length;
                      optIndex++
                    ) ...[
                      if (optIndex > 0) const SizedBox(height: gap),
                      _CompactOptionTile(
                        letter: optIndex < _letters.length
                            ? _letters[optIndex]
                            : '${optIndex + 1}',
                        option: question.options[optIndex],
                        selected:
                            selectedOptionId == question.options[optIndex].id,
                        isReadOnly: isReadOnly,
                        showResult: showResult,
                        onTap: onOptionSelected != null
                            ? () => onOptionSelected!(
                                question.options[optIndex].id,
                              )
                            : null,
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _textAnswerField(String displayedText) {
    final remaining = _maxTextLength - displayedText.length;
    if (isReadOnly) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F6F1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Academy.line),
        ),
        child: Text(
          displayedText.trim().isEmpty
              ? AppStrings.notAnswered
              : displayedText,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: displayedText.trim().isEmpty ? Academy.muted : Academy.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: textController,
          maxLength: _maxTextLength,
          minLines: 3,
          maxLines: 5,
          onChanged: onTextChanged,
          decoration: InputDecoration(
            labelText: AppStrings.yourAnswer,
            hintText: AppStrings.enterATextAnswerMax250,
            alignLabelWithHint: true,
            filled: true,
            fillColor: const Color(0xFFFAF8F3),
            border: AppOutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: AppOutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE8E0D4)),
            ),
            focusedBorder: AppOutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Brand.gold, width: 1.4),
            ),
            counterText: '',
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$remaining ${AppStrings.charactersRemaining}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: remaining < 20 ? Colors.orange.shade800 : Academy.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactOptionTile extends StatelessWidget {
  const _CompactOptionTile({
    required this.letter,
    required this.option,
    required this.selected,
    this.isReadOnly = false,
    this.showResult = false,
    this.onTap,
  });

  final String letter;
  final LearningOptionDto option;
  final bool selected;
  final bool isReadOnly;
  final bool showResult;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tileBg = selected
        ? Brand.gold.withValues(alpha: 0.14)
        : const Color(0xFFFAF9F6);
    final borderColor = selected ? Brand.gold : Academy.line;
    final borderWidth = selected ? 1.8 : 1.0;
    final letterBg = selected ? Brand.navy : const Color(0xFFEAE5DC);
    final letterTextColor = selected ? Colors.white : Academy.ink;
    final optionTextColor = selected ? Brand.navy : Academy.ink;
    final optionFontWeight = selected ? FontWeight.w700 : FontWeight.w500;
    final trailingWidget = Icon(
      selected
          ? Icons.check_circle_rounded
          : Icons.radio_button_unchecked_rounded,
      color: selected ? Brand.navy : const Color(0xFFCBC5B8),
      size: 18,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: letterBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: TextStyle(
                    color: letterTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  option.optionText,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: optionFontWeight,
                    color: optionTextColor,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              trailingWidget,
            ],
          ),
        ),
      ),
    );
  }
}

class StaffLearningWeekPage extends ConsumerWidget {
  const StaffLearningWeekPage({
    super.key,
    required this.studentId,
    required this.journeyId,
    required this.week,
    this.audience = StaffLearningAudience.admin,
  });

  final String studentId;
  final String journeyId;
  final int week;
  final StaffLearningAudience audience;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = switch (audience) {
      StaffLearningAudience.masterTeacher => ref.watch(
        masterTeacherLearningWeekProvider((
          studentId: studentId,
          journeyId: journeyId,
          week: week,
        )),
      ),
      StaffLearningAudience.teacher => ref.watch(
        teacherLearningWeekProvider((
          studentId: studentId,
          journeyId: journeyId,
          week: week,
        )),
      ),
      StaffLearningAudience.admin => ref.watch(
        adminLearningWeekProvider((
          studentId: studentId,
          journeyId: journeyId,
          week: week,
        )),
      ),
    };
    return AppScaffold(
      title: 'Week $week',
      backTo: switch (audience) {
        StaffLearningAudience.masterTeacher =>
          RoutePaths.masterTeacherStudentJournalFor(studentId),
        StaffLearningAudience.teacher =>
          RoutePaths.teacherScheduleStudentFor(studentId),
        StaffLearningAudience.admin =>
          RoutePaths.adminStudentJournalFor(studentId),
      },
      body: AsyncBody(
        value: value,
        onRetry: () {
          switch (audience) {
            case StaffLearningAudience.masterTeacher:
              ref.invalidate(
                masterTeacherLearningWeekProvider((
                  studentId: studentId,
                  journeyId: journeyId,
                  week: week,
                )),
              );
            case StaffLearningAudience.teacher:
              ref.invalidate(
                teacherLearningWeekProvider((
                  studentId: studentId,
                  journeyId: journeyId,
                  week: week,
                )),
              );
            case StaffLearningAudience.admin:
              ref.invalidate(
                adminLearningWeekProvider((
                  studentId: studentId,
                  journeyId: journeyId,
                  week: week,
                )),
              );
          }
        },
        builder: (weekData) {
          final hasAttempts = weekData.attempts.isNotEmpty;
          final isMobile = MediaQuery.sizeOf(context).width < 600;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 12 : 16,
              isMobile ? 10 : 16,
              isMobile ? 12 : 16,
              48,
            ),
            children: [
              AcademySurface(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weekData.studentName ?? AppStrings.student,
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: Academy.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: isMobile ? 8 : 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _InfoBadge(
                          icon: Icons.layers_outlined,
                          label:
                              '${weekData.level.name} · Week ${weekData.weekNumber}',
                          compact: isMobile,
                        ),
                        if (weekData.studyDate != null)
                          _InfoBadge(
                            icon: Icons.calendar_today_outlined,
                            label: formatDisplayDate(weekData.studyDate),
                            compact: isMobile,
                          ),
                        _InfoBadge(
                          icon: Icons.history_rounded,
                          label:
                              '${weekData.attemptsUsed}/${weekData.attemptsMax} attempts',
                          compact: isMobile,
                        ),
                      ],
                    ),
                    if (weekData.hasVideo && weekData.videoUrl != null) ...[
                      SizedBox(height: isMobile ? 10 : 14),
                      SizedBox(
                        width: isMobile ? double.infinity : null,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Brand.navy,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: isMobile ? 10 : 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => launchUrl(
                            Uri.parse(weekData.videoUrl!),
                            webOnlyWindowName: AppStrings.blank,
                          ),
                          icon: const Icon(
                            Icons.play_circle_fill_rounded,
                            color: Brand.gold,
                            size: 18,
                          ),
                          label: Text(
                            AppStrings.openLessonVideo,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: isMobile ? 12.5 : 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 12 : 20),
              if (!hasAttempts)
                const AcademyEmpty(
                  icon: Icons.quiz_outlined,
                  title: AppStrings.noAttemptsSubmitted,
                  body: AppStrings
                      .theStudentHasNotSubmittedAnyAttemptsForThisWeek,
                )
              else
                for (final attempt in weekData.attempts)
                  _AttemptReview(week: weekData, attempt: attempt, staff: true),
            ],
          );
        },
      ),
    );
  }
}

enum StaffLearningAudience { admin, masterTeacher, teacher }

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Academy.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 13, color: Brand.navy),
          SizedBox(width: compact ? 4 : 5),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: Academy.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttemptReview extends StatelessWidget {
  const _AttemptReview({
    required this.week,
    required this.attempt,
    this.staff = false,
  });

  final LearningWeekDto week;
  final LearningAttemptDto attempt;
  final bool staff;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final totalCount = week.questions.length;
    final answeredCount = week.questions
        .where((q) => attempt.hasAnswerFor(q))
        .length;

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 12 : 24),
      child: AcademySurface(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attempt ${attempt.attemptNumber}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: isMobile ? 15 : 18,
                          color: Academy.ink,
                        ),
                      ),
                      if (attempt.submittedAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          formatDisplayDateTime(attempt.submittedAt),
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: Academy.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Text(
                    '$answeredCount / $totalCount',
                    style: TextStyle(
                      fontSize: isMobile ? 11.5 : 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
            if (attempt.result != null &&
                attempt.result!.dimensions.isNotEmpty) ...[
              SizedBox(height: isMobile ? 10 : 14),
              AssessmentResultView(
                result: attempt.result!,
                compact: true,
                showCharts: false,
                showTitle: false,
              ),
            ],
            if (attempt.videoUrl != null && attempt.videoUrl!.isNotEmpty) ...[
              SizedBox(height: isMobile ? 8 : 12),
              SizedBox(
                width: isMobile ? double.infinity : null,
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(attempt.videoUrl!),
                    webOnlyWindowName: AppStrings.blank,
                  ),
                  icon: const Icon(Icons.videocam_outlined, size: 16),
                  label: Text(
                    AppStrings.viewStudentSubmissionVideo,
                    style: TextStyle(
                      fontSize: isMobile ? 11.5 : 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: isMobile ? 12 : 16),
            for (var i = 0; i < week.questions.length; i++)
              _CompactQuestionCard(
                index: i,
                question: week.questions[i],
                selectedOptionId: week.questions[i].isText
                    ? null
                    : attempt.optionIdFor(week.questions[i].id),
                textAnswer: week.questions[i].isText
                    ? attempt.textAnswerFor(week.questions[i].id)
                    : null,
                isReadOnly: true,
                showResult: true,
              ),
          ],
        ),
      ),
    );
  }
}
