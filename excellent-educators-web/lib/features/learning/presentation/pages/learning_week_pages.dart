import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
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
    this.onOptionSelected,
  });

  final int index;
  final LearningQuestionDto question;
  final String? selectedOptionId;
  final bool isReadOnly;
  final ValueChanged<String>? onOptionSelected;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

  @override
  Widget build(BuildContext context) {
    final isAnswered = selectedOptionId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAnswered ? const Color(0xFFA5D6A7) : Academy.line,
          width: isAnswered ? 1.4 : 1.0,
        ),
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
                    ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
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
              if (isAnswered) ...[
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
          const SizedBox(height: 10),

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
    this.onTap,
  });

  final String letter;
  final LearningOptionDto option;
  final bool selected;
  final bool isReadOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Brand.gold.withValues(alpha: 0.14) : const Color(0xFFFAF9F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? Brand.gold : Academy.line,
              width: selected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? Brand.navy : const Color(0xFFEAE5DC),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: TextStyle(
                    color: selected ? Colors.white : Academy.ink,
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
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Brand.navy : Academy.ink,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? Brand.navy : const Color(0xFFCBC5B8),
                size: 18,
              ),
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
        builder: (weekData) => ListView(
          children: [
            Text(weekData.studentName ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text('${weekData.level.name} · Week ${weekData.weekNumber}'),
            const SizedBox(height: 8),
            Text('Study date: ${weekData.studyDate ?? '—'}'),
            Text('Attempts ${weekData.attemptsUsed}/${weekData.attemptsMax}'),
            const SizedBox(height: 16),
            if (weekData.hasVideo && weekData.videoUrl != null)
              FilledButton.icon(
                onPressed: () => launchUrl(Uri.parse(weekData.videoUrl!), webOnlyWindowName: '_blank'),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Open video'),
              ),
            const SizedBox(height: 16),
            for (final attempt in weekData.attempts) _AttemptReview(week: weekData, attempt: attempt, staff: true),
          ],
        ),
      ),
    );
  }
}

class _AssignmentForm extends StatelessWidget {
  const _AssignmentForm({required this.week, required this.answers, required this.onChanged});

  final LearningWeekDto week;
  final Map<String, String> answers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AcademySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcademyLabel('Assignment'),
          const SizedBox(height: 12),
          for (final question in week.questions) ...[
            Text(question.questionText, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            for (final option in question.options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option.optionText),
                leading: Icon(
                  answers[question.id] == option.id ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: answers[question.id] == option.id ? Brand.navy : Academy.muted,
                ),
                onTap: () {
                  answers[question.id] = option.id;
                  onChanged();
                },
              ),
            const SizedBox(height: 12),
          ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AcademySurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attempt ${attempt.attemptNumber}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            for (final question in week.questions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${question.questionText}\n${_optionText(question, attempt.optionIdFor(question.id))}',
                  style: const TextStyle(height: 1.4),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _optionText(LearningQuestionDto question, String? optionId) {
    final match = question.options.where((option) => option.id == optionId).firstOrNull;
    if (match == null) return 'No answer';
    final extra = staff && match.isCorrect == true ? ' · correct' : '';
    return match.optionText + extra;
  }
}
