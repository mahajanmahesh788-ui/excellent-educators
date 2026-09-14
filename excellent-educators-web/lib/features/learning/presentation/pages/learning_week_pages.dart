import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentLearningWeekPage extends ConsumerStatefulWidget {
  const StudentLearningWeekPage({
    super.key,
    required this.journeyId,
    required this.week,
  });

  final String journeyId;
  final int week;

  @override
  ConsumerState<StudentLearningWeekPage> createState() => _StudentLearningWeekPageState();
}

class _StudentLearningWeekPageState extends ConsumerState<StudentLearningWeekPage> {
  final _answers = <String, String>{};
  final _questionKeys = <int, GlobalKey>{};
  var _submitting = false;
  String? _error;

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
      studentLearningWeekProvider((journeyId: widget.journeyId, week: widget.week)),
    );

    return StudentScaffold(
      title: 'Week ${widget.week} Assignment',
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
            studentLearningWeekProvider((journeyId: widget.journeyId, week: widget.week)),
          ),
        ),
        data: (week) {
          final totalQuestions = week.questions.length;
          final latestAttempt = week.attempts.lastOrNull;

          // Prepopulate answers from latest attempt if available and not yet touched
          if (_answers.isEmpty && latestAttempt != null && week.canSubmit) {
            for (final q in week.questions) {
              final optId = latestAttempt.optionIdFor(q.id);
              if (optId != null) {
                _answers[q.id] = optId;
              }
            }
          }

          final displayAnswers = week.canSubmit
              ? _answers
              : {
                  for (final q in week.questions)
                    if (latestAttempt?.optionIdFor(q.id) != null)
                      q.id: latestAttempt!.optionIdFor(q.id)!,
                };

          final answeredCount = displayAnswers.length;

          for (var i = 0; i < totalQuestions; i++) {
            _questionKeys.putIfAbsent(i, () => GlobalKey());
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 48),
            children: [
              // Header navigation breadcrumb & back
              Row(
                children: [
                  InkWell(
                    onTap: () => context.go(RoutePaths.studentJournal),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, size: 18, color: Academy.muted),
                          SizedBox(width: 4),
                          Text(
                            'Back to Journey',
                            style: TextStyle(color: Academy.muted, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Brand.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Brand.gold.withValues(alpha: 0.4)),
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
              const SizedBox(height: 14),

              // Title and status banner
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                              ? 'Assignment completed! Your selected answers are shown below.'
                              : !week.canSubmit
                                  ? 'Submissions closed · Your selected answers are shown below.'
                                  : 'Attempt ${week.attemptsUsed + 1} of ${week.attemptsMax} · All questions on this screen.',
                          style: const TextStyle(fontSize: 14, color: Academy.muted),
                        ),
                      ],
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
                        child: const Icon(Icons.play_circle_fill_rounded, color: Brand.gold, size: 26),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly Video Lesson',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Recommended to watch before submitting',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Brand.gold,
                          foregroundColor: Brand.navy,
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        onPressed: () => launchUrl(Uri.parse(week.videoUrl!), webOnlyWindowName: '_blank'),
                        icon: const Icon(Icons.open_in_new_rounded, size: 15),
                        label: const Text('Watch Video'),
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assignment Completed',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Your selected answers are displayed below.',
                              style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (!week.canSubmit && week.attemptsUsed >= week.attemptsMax) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFCC80)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFE65100), size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Maximum Attempts Reached',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFFE65100),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Submissions are closed. Your selected answers are displayed below.',
                              style: TextStyle(color: Color(0xFFE65100), fontSize: 13),
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                          const Icon(Icons.assignment_outlined, size: 18, color: Brand.navy),
                          const SizedBox(width: 8),
                          const Text(
                            'Questions',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Academy.ink,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (answeredCount == totalQuestions) ...[
                                  const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  '$answeredCount / $totalQuestions ${week.canSubmit ? 'answered' : 'selected'}',
                                  style: TextStyle(
                                    color: answeredCount == totalQuestions
                                        ? const Color(0xFF1B5E20)
                                        : const Color(0xFF6B4D00),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: totalQuestions > 0 ? (answeredCount / totalQuestions) : 0.0,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFEFE9DC),
                          valueColor: AlwaysStoppedAnimation(
                            answeredCount == totalQuestions ? const Color(0xFF2E7D32) : Brand.gold,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: displayAnswers.containsKey(week.questions[i].id)
                                          ? const Color(0xFFE8F5E9)
                                          : const Color(0xFFF4F1EA),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: displayAnswers.containsKey(week.questions[i].id)
                                            ? const Color(0xFF81C784)
                                            : Academy.line,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (displayAnswers.containsKey(week.questions[i].id)) ...[
                                          const Icon(Icons.check_rounded, size: 12, color: Color(0xFF2E7D32)),
                                          const SizedBox(width: 3),
                                        ],
                                        Text(
                                          'Q${i + 1}',
                                          style: TextStyle(
                                            color: displayAnswers.containsKey(week.questions[i].id)
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
                    selectedOptionId: displayAnswers[week.questions[i].id],
                    isReadOnly: !week.canSubmit,
                    showResult: !week.canSubmit && (week.completed || week.attemptsUsed > 0),
                    onOptionSelected: week.canSubmit
                        ? (optId) {
                            setState(() {
                              _answers[week.questions[i].id] = optId;
                              _error = null;
                            });
                          }
                        : null,
                  ),

                // Error message banner
                if (_error != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Bar (Submit if open, or Back to Journey if closed/completed)
                if (week.canSubmit) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                answeredCount == totalQuestions
                                    ? 'All $totalQuestions questions answered!'
                                    : '$answeredCount of $totalQuestions answered',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Academy.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                answeredCount == totalQuestions
                                    ? 'You are ready to submit your assignment.'
                                    : 'Select answers for the remaining questions above.',
                                style: const TextStyle(fontSize: 13, color: Academy.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Brand.navy,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _submitting ? null : () => _submit(week),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Brand.gold),
                          label: Text(
                            _submitting ? 'Submitting…' : 'Submit Assignment',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Center(
                    child: AcademyButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'Back to Journey',
                      onPressed: () => context.go(RoutePaths.studentJournal),
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(LearningWeekDto week) async {
    final unansweredIndex = week.questions.indexWhere((q) => !_answers.containsKey(q.id));
    if (unansweredIndex != -1) {
      _scrollToQuestion(unansweredIndex);
      final remaining = week.questions.length - _answers.length;
      setState(() {
        _error = 'Please answer all questions before submitting ($remaining remaining).';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(learningRepositoryProvider).submitWeek(
            journeyId: widget.journeyId,
            week: widget.week,
            answers: [
              for (final question in week.questions)
                {'question_id': question.id, 'option_id': _answers[question.id]},
            ],
          );
      _answers.clear();
      ref.invalidate(studentLearningWeekProvider((journeyId: widget.journeyId, week: widget.week)));
      ref.invalidate(studentLearningJournalProvider);
      ref.invalidate(studentLearningDashboardProvider);

      if (!mounted) return;

      // Submit successful popup dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
                      border: Border.all(color: const Color(0xFF81C784), width: 2),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF2E7D32),
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Submitted Successfully!',
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.go(RoutePaths.studentJournal);
                      },
                      child: const Text(
                        'OK',
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
    required this.selectedOptionId,
    this.isReadOnly = false,
    this.showResult = false,
    this.onOptionSelected,
  });

  final int index;
  final LearningQuestionDto question;
  final String? selectedOptionId;
  final bool isReadOnly;
  final bool showResult;
  final ValueChanged<String>? onOptionSelected;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

  @override
  Widget build(BuildContext context) {
    final isAnswered = selectedOptionId != null;
    final selectedOption = question.options.where((o) => o.id == selectedOptionId).firstOrNull;
    final isStudentCorrect = isAnswered && selectedOption?.isCorrect == true;
    final isStudentWrong = isAnswered &&
        (selectedOption?.isCorrect == false ||
            (selectedOption?.isCorrect == null && question.options.any((o) => o.isCorrect == true)));

    Color borderColor;
    double borderWidth;
    if (showResult && isAnswered) {
      if (isStudentCorrect) {
        borderColor = const Color(0xFF81C784);
        borderWidth = 1.5;
      } else if (isStudentWrong) {
        borderColor = const Color(0xFFEF9A9A);
        borderWidth = 1.5;
      } else {
        borderColor = Academy.line;
        borderWidth = 1.0;
      }
    } else if (isAnswered) {
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
                  color: showResult && isAnswered
                      ? (isStudentCorrect ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F))
                      : (isAnswered ? const Color(0xFF2E7D32) : Brand.navy),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: showResult && isAnswered
                    ? Icon(
                        isStudentCorrect ? Icons.check_rounded : Icons.close_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : (isAnswered
                        ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          )),
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
              if (showResult && isAnswered) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isStudentCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isStudentCorrect ? const Color(0xFFA5D6A7) : const Color(0xFFFFCDD2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isStudentCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        size: 13,
                        color: isStudentCorrect ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isStudentCorrect ? 'Correct' : 'Incorrect',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isStudentCorrect ? const Color(0xFF1B5E20) : const Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (showResult && !isAnswered) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Academy.line),
                  ),
                  child: const Text(
                    'Not Answered',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Academy.muted,
                    ),
                  ),
                ),
              ] else if (isAnswered) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Text(
                    isReadOnly ? 'Selected' : 'Answered',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Options (2 columns when wide, 1 column when narrow)
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
                    for (var optIndex = 0; optIndex < question.options.length; optIndex++)
                      SizedBox(
                        width: cardWidth,
                        child: _CompactOptionTile(
                          letter: optIndex < _letters.length ? _letters[optIndex] : '${optIndex + 1}',
                          option: question.options[optIndex],
                          selected: selectedOptionId == question.options[optIndex].id,
                          isReadOnly: isReadOnly,
                          showResult: showResult,
                          onTap: onOptionSelected != null
                              ? () => onOptionSelected!(question.options[optIndex].id)
                              : null,
                        ),
                      ),
                  ],
                );
              }

              return Column(
                children: [
                  for (var optIndex = 0; optIndex < question.options.length; optIndex++) ...[
                    if (optIndex > 0) const SizedBox(height: gap),
                    _CompactOptionTile(
                      letter: optIndex < _letters.length ? _letters[optIndex] : '${optIndex + 1}',
                      option: question.options[optIndex],
                      selected: selectedOptionId == question.options[optIndex].id,
                      isReadOnly: isReadOnly,
                      showResult: showResult,
                      onTap: onOptionSelected != null
                          ? () => onOptionSelected!(question.options[optIndex].id)
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
    final isCorrectOption = option.isCorrect == true;

    Color tileBg;
    Color borderColor;
    double borderWidth;
    Color letterBg;
    Color letterTextColor;
    Color optionTextColor;
    FontWeight optionFontWeight;
    Widget trailingWidget;

    if (showResult) {
      if (selected && isCorrectOption) {
        // User picked this answer and it is CORRECT: Green border, green background, checkmark
        tileBg = const Color(0xFFE8F5E9);
        borderColor = const Color(0xFF2E7D32);
        borderWidth = 1.8;
        letterBg = const Color(0xFF2E7D32);
        letterTextColor = Colors.white;
        optionTextColor = const Color(0xFF1B5E20);
        optionFontWeight = FontWeight.w700;
        trailingWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFFA5D6A7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, color: Color(0xFF1B5E20), size: 14),
              SizedBox(width: 3),
              Text(
                'Correct answer',
                style: TextStyle(color: Color(0xFF1B5E20), fontSize: 10.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      } else if (selected && !isCorrectOption) {
        // User picked this answer and it is WRONG: Red border, red background, cross
        tileBg = const Color(0xFFFFEBEE);
        borderColor = const Color(0xFFD32F2F);
        borderWidth = 1.8;
        letterBg = const Color(0xFFD32F2F);
        letterTextColor = Colors.white;
        optionTextColor = const Color(0xFFB71C1C);
        optionFontWeight = FontWeight.w700;
        trailingWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFCDD2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close_rounded, color: Color(0xFFD32F2F), size: 14),
              SizedBox(width: 3),
              Text(
                'Wrong answer',
                style: TextStyle(color: Color(0xFFC62828), fontSize: 10.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      } else if (!selected && isCorrectOption) {
        // This is the correct answer, not picked by user: Green border so user/staff can see what was correct
        tileBg = const Color(0xFFF1F8E9);
        borderColor = const Color(0xFF4CAF50);
        borderWidth = 1.5;
        letterBg = const Color(0xFF4CAF50);
        letterTextColor = Colors.white;
        optionTextColor = const Color(0xFF2E7D32);
        optionFontWeight = FontWeight.w600;
        trailingWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFFC8E6C9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, color: Color(0xFF1B5E20), size: 14),
              SizedBox(width: 3),
              Text(
                'Correct answer',
                style: TextStyle(color: Color(0xFF1B5E20), fontSize: 10.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      } else {
        // Unselected other options
        tileBg = const Color(0xFFFAF9F6);
        borderColor = Academy.line;
        borderWidth = 1.0;
        letterBg = const Color(0xFFEAE5DC);
        letterTextColor = Academy.ink;
        optionTextColor = Academy.ink;
        optionFontWeight = FontWeight.w500;
        trailingWidget = const Icon(
          Icons.radio_button_unchecked_rounded,
          color: Color(0xFFCBC5B8),
          size: 18,
        );
      }
    } else {
      // Normal Quiz Mode
      tileBg = selected ? Brand.gold.withValues(alpha: 0.14) : const Color(0xFFFAF9F6);
      borderColor = selected ? Brand.gold : Academy.line;
      borderWidth = selected ? 1.8 : 1.0;
      letterBg = selected ? Brand.navy : const Color(0xFFEAE5DC);
      letterTextColor = selected ? Colors.white : Academy.ink;
      optionTextColor = selected ? Brand.navy : Academy.ink;
      optionFontWeight = selected ? FontWeight.w700 : FontWeight.w500;
      trailingWidget = Icon(
        selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        color: selected ? Brand.navy : const Color(0xFFCBC5B8),
        size: 18,
      );
    }

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
    required this.masterTeacher,
  });

  final String studentId;
  final String journeyId;
  final int week;
  final bool masterTeacher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = masterTeacher
        ? ref.watch(masterTeacherLearningWeekProvider((studentId: studentId, journeyId: journeyId, week: week)))
        : ref.watch(adminLearningWeekProvider((studentId: studentId, journeyId: journeyId, week: week)));
    return AppScaffold(
      title: 'Week $week',
      backTo: masterTeacher ? RoutePaths.masterTeacherStudentJournalFor(studentId) : RoutePaths.adminStudentJournalFor(studentId),
      body: AsyncBody(
        value: value,
        onRetry: () {
          if (masterTeacher) {
            ref.invalidate(masterTeacherLearningWeekProvider((studentId: studentId, journeyId: journeyId, week: week)));
          } else {
            ref.invalidate(adminLearningWeekProvider((studentId: studentId, journeyId: journeyId, week: week)));
          }
        },
        builder: (weekData) {
          // Calculate overall score / result
          int correct;
          int total;
          int percentage;
          if (weekData.score != null) {
            correct = weekData.score!.correct;
            total = weekData.score!.total;
            percentage = weekData.score!.percentage;
          } else if (weekData.attempts.isNotEmpty) {
            final latest = weekData.attempts.last;
            correct = 0;
            for (final q in weekData.questions) {
              final optId = latest.optionIdFor(q.id);
              final opt = q.options.where((o) => o.id == optId).firstOrNull;
              if (opt?.isCorrect == true) correct++;
            }
            total = weekData.questions.length;
            percentage = total > 0 ? ((correct / total) * 100).round() : 0;
          } else {
            correct = 0;
            total = weekData.questions.length;
            percentage = 0;
          }
          final hasAttempts = weekData.attempts.isNotEmpty;
          final isPassing = percentage >= 70;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            children: [
              // Executive Header Card
              AcademySurface(
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
                                weekData.studentName ?? 'Student',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Academy.ink,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _InfoBadge(
                                    icon: Icons.layers_outlined,
                                    label: '${weekData.level.name} · Week ${weekData.weekNumber}',
                                  ),
                                  if (weekData.studyDate != null)
                                    _InfoBadge(
                                      icon: Icons.calendar_today_outlined,
                                      label: 'Study date: ${formatDisplayDate(weekData.studyDate)}',
                                    ),
                                  _InfoBadge(
                                    icon: Icons.history_rounded,
                                    label: 'Attempts ${weekData.attemptsUsed}/${weekData.attemptsMax}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Overall Result Badge if attempts have been submitted
                        if (hasAttempts) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isPassing ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isPassing ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPassing ? Icons.verified_rounded : Icons.info_outline_rounded,
                                  size: 24,
                                  color: isPassing ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Result: $correct / $total ($percentage%)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14.5,
                                        color: isPassing ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                                      ),
                                    ),
                                    Text(
                                      isPassing ? 'Passing Score' : 'Needs Improvement',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isPassing ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (weekData.hasVideo && weekData.videoUrl != null) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: Academy.line),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Brand.navy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => launchUrl(Uri.parse(weekData.videoUrl!), webOnlyWindowName: '_blank'),
                            icon: const Icon(Icons.play_circle_fill_rounded, color: Brand.gold, size: 18),
                            label: const Text('Open Lesson Video', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (weekData.attempts.isEmpty)
                const AcademyEmpty(
                  icon: Icons.quiz_outlined,
                  title: 'No Attempts Submitted',
                  body: 'The student has not submitted any attempts for this week yet.',
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

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Academy.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Brand.navy),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
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
  const _AttemptReview({required this.week, required this.attempt, this.staff = false});

  final LearningWeekDto week;
  final LearningAttemptDto attempt;
  final bool staff;

  @override
  Widget build(BuildContext context) {
    // Calculate score for this attempt
    var correctCount = 0;
    for (final q in week.questions) {
      final optId = attempt.optionIdFor(q.id);
      final opt = q.options.where((o) => o.id == optId).firstOrNull;
      if (opt?.isCorrect == true) correctCount++;
    }
    final totalCount = week.questions.length;
    final percent = totalCount > 0 ? ((correctCount / totalCount) * 100).round() : 0;
    final isPassing = percent >= 70;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AcademySurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attempt Header with Title & Result Badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attempt ${attempt.attemptNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Academy.ink),
                      ),
                      if (attempt.submittedAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Submitted on ${formatDisplayDateTime(attempt.submittedAt)}',
                          style: const TextStyle(fontSize: 12, color: Academy.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                // Attempt Result Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPassing ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPassing ? const Color(0xFFA5D6A7) : const Color(0xFFFFCDD2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPassing ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        size: 15,
                        color: isPassing ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Result: $correctCount / $totalCount ($percent%)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isPassing ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (attempt.videoUrl != null && attempt.videoUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(attempt.videoUrl!), webOnlyWindowName: '_blank'),
                icon: const Icon(Icons.videocam_outlined, size: 16),
                label: const Text('View Student Submission Video', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ],
            const SizedBox(height: 16),
            // Full Question & Answer UI using the exact same components!
            for (var i = 0; i < week.questions.length; i++)
              _CompactQuestionCard(
                index: i,
                question: week.questions[i],
                selectedOptionId: attempt.optionIdFor(week.questions[i].id),
                isReadOnly: true,
                showResult: true,
              ),
          ],
        ),
      ),
    );
  }
}
