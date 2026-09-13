import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/core/widgets/portal_chrome.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/compact_assessment_card.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/monthly_rating_history.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:excellent_educators_web/features/learning/presentation/widgets/learning_journal_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherStudentBriefingPage extends ConsumerWidget {
  const TeacherStudentBriefingPage({
    super.key,
    required this.studentId,
    this.slotLabel,
  });

  final String studentId;
  final String? slotLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMaster = ref.watch(authControllerProvider).user?.isMasterTeacher ?? false;
    final profile = isMaster
        ? ref.watch(masterTeacherStudentProvider(studentId))
        : ref.watch(teacherStudentProvider(studentId));
    final results = isMaster
        ? ref.watch(masterTeacherStudentResultsProvider(studentId))
        : ref.watch(teacherStudentResultsProvider(studentId));
    final ratings = isMaster
        ? ref.watch(masterTeacherStudentFeedbackProvider(studentId))
        : ref.watch(teacherStudentFeedbackProvider(studentId));
    final journal = isMaster
        ? ref.watch(masterTeacherLearningJournalProvider(studentId))
        : ref.watch(teacherLearningJournalProvider(studentId));

    return AppScaffold(
      title: 'Student history',
      backTo: RoutePaths.teacherDaySchedule,
      body: AsyncBody(
        value: profile,
        onRetry: () {
          ref.invalidate(masterTeacherStudentProvider(studentId));
          ref.invalidate(teacherStudentProvider(studentId));
        },
        builder: (student) {
          return SizedBox.expand(
            child: DefaultTabController(
            length: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PortalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Brand.navy)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (student.studentCode.isNotEmpty) _InfoChip(student.studentCode),
                          if (student.classGrade > 0) _InfoChip('Class ${student.classGrade}'),
                          if (student.level != null && !student.level!.isEmpty) _InfoChip(student.level!.label),
                          if (student.batch != null && !student.batch!.isEmpty) _InfoChip(student.batch!.label),
                          if (slotLabel != null && slotLabel!.isNotEmpty) _InfoChip(slotLabel!),
                        ],
                      ),
                      if (student.feedbackOverallAverage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Overall rating ${student.feedbackOverallAverage!.toStringAsFixed(1)} / 10 · ${student.feedbackTotalSessions} monthly ratings',
                          style: const TextStyle(color: Brand.muted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const TabBar(
                  labelColor: Brand.navy,
                  indicatorColor: Brand.gold,
                  tabs: [
                    Tab(text: '1st assignment'),
                    Tab(text: 'Ratings'),
                    Tab(text: 'Weekly tests'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      AsyncBody(
                        value: results,
                        onRetry: () {
                          ref.invalidate(masterTeacherStudentResultsProvider(studentId));
                          ref.invalidate(teacherStudentResultsProvider(studentId));
                        },
                        builder: (items) {
                          if (items.isEmpty) {
                            return const EmptyHint(
                              'No first assignment yet',
                              subtitle: 'The Getting to Know You aptitude result will appear here after the student submits.',
                              fillHeight: false,
                            );
                          }
                          return ListView(
                            children: [
                              const Text('First assignment result', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Brand.navy)),
                              const SizedBox(height: 10),
                              for (final result in items) ...[
                                CompactAssessmentCard(result: result),
                                const SizedBox(height: 12),
                              ],
                            ],
                          );
                        },
                      ),
                      AsyncBody(
                        value: ratings,
                        onRetry: () {
                          ref.invalidate(masterTeacherStudentFeedbackProvider(studentId));
                          ref.invalidate(teacherStudentFeedbackProvider(studentId));
                        },
                        builder: (items) {
                          if (items.isEmpty) {
                            return const EmptyHint(
                              'No monthly ratings yet',
                              subtitle: 'Previous Master Class ratings will be listed here, newest first.',
                              fillHeight: false,
                            );
                          }
                          return ListView(
                            children: [
                              const Text('Previous ratings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Brand.navy)),
                              const SizedBox(height: 10),
                              MonthlyRatingHistoryList(items: items),
                            ],
                          );
                        },
                      ),
                      AsyncBody(
                        value: journal,
                        onRetry: () {
                          ref.invalidate(masterTeacherLearningJournalProvider(studentId));
                          ref.invalidate(teacherLearningJournalProvider(studentId));
                        },
                        builder: (data) {
                          if (data.levels.isEmpty) {
                            return const EmptyHint(
                              'No weekly tests yet',
                              subtitle: 'Weekly assignments from the Learning Journey will appear here by level and week.',
                              fillHeight: false,
                            );
                          }
                          return ListView(
                            children: [
                              LearningJournalTable(
                                journal: data,
                                staffView: true,
                                onOpenWeek: (group, week) {
                                  showDialog<void>(
                                    context: context,
                                    builder: (context) => _WeekTestResultDialog(
                                      studentId: studentId,
                                      group: group,
                                      week: week,
                                      isMaster: isMaster,
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        },
      ),
    );
  }
}

class _WeekTestResultDialog extends ConsumerStatefulWidget {
  const _WeekTestResultDialog({
    required this.studentId,
    required this.group,
    required this.week,
    required this.isMaster,
  });

  final String studentId;
  final LearningLevelGroupDto group;
  final LearningWeekDto week;
  final bool isMaster;

  @override
  ConsumerState<_WeekTestResultDialog> createState() => _WeekTestResultDialogState();
}

class _WeekTestResultDialogState extends ConsumerState<_WeekTestResultDialog> {
  int _selectedAttemptIndex = 0;

  @override
  Widget build(BuildContext context) {
    final weekAsync = widget.isMaster
        ? ref.watch(masterTeacherLearningWeekProvider((
            studentId: widget.studentId,
            journeyId: widget.group.journeyId,
            week: widget.week.weekNumber,
          )))
        : ref.watch(teacherLearningWeekProvider((
            studentId: widget.studentId,
            journeyId: widget.group.journeyId,
            week: widget.week.weekNumber,
          )));

    final loadedWeek = weekAsync.valueOrNull ?? widget.week;
    final videoUrl = (loadedWeek.hasVideo && (loadedWeek.videoUrl?.isNotEmpty ?? false))
        ? loadedWeek.videoUrl
        : (widget.week.hasVideo && (widget.week.videoUrl?.isNotEmpty ?? false) ? widget.week.videoUrl : null);

    final isCompleted = loadedWeek.completed;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Executive Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Brand.navy,
                border: Border(bottom: BorderSide(color: Color(0x33C5A55D), width: 2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Brand.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_turned_in_rounded, color: Brand.gold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.week.level.name} · Week ${widget.week.weekNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCompleted ? const Color(0xFF059669) : const Color(0xFFD97706),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isCompleted ? 'Completed' : 'Pending',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Attempts: ${loadedWeek.attemptsUsed} / ${loadedWeek.attemptsMax}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                            if (loadedWeek.studyDate != null) ...[
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              const SizedBox(width: 8),
                              Text(
                                'Study date: ${loadedWeek.studyDate}',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: Video Lesson Card
                    _buildVideoCard(videoUrl),

                    const SizedBox(height: 20),

                    // Section 2: Student's Test Result
                    const Row(
                      children: [
                        Icon(Icons.quiz_outlined, size: 18, color: Brand.navy),
                        SizedBox(width: 8),
                        Text(
                          "Student's Test Result",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Brand.navy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    weekAsync.when(
                      loading: () => Container(
                        padding: const EdgeInsets.all(36),
                        alignment: Alignment.center,
                        child: const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            const Text(
                              "Loading student's test results...",
                              style: TextStyle(color: Academy.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Unable to load test result: $err',
                                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                if (widget.isMaster) {
                                  ref.invalidate(masterTeacherLearningWeekProvider((
                                    studentId: widget.studentId,
                                    journeyId: widget.group.journeyId,
                                    week: widget.week.weekNumber,
                                  )));
                                } else {
                                  ref.invalidate(teacherLearningWeekProvider((
                                    studentId: widget.studentId,
                                    journeyId: widget.group.journeyId,
                                    week: widget.week.weekNumber,
                                  )));
                                }
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                      data: (weekData) => _buildResultContent(weekData),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: Brand.navy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(String? videoUrl) {
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 460;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasVideo ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasVideo ? Brand.navy.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hasVideo ? Brand.navy : const Color(0xFF94A3B8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      hasVideo ? Icons.play_circle_fill_rounded : Icons.videocam_off_rounded,
                      color: hasVideo ? Brand.gold : Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weekly Lesson Video',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Brand.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasVideo
                              ? "Watch this week's video lesson"
                              : 'No video lesson linked for this week.',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasVideo ? const Color(0xFF475569) : Academy.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasVideo && !isCompact) ...[
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Brand.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => launchUrl(Uri.parse(videoUrl), webOnlyWindowName: '_blank'),
                      icon: const Icon(Icons.open_in_new_rounded, size: 15, color: Brand.gold),
                      label: const Text('Watch Video', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ],
              ),
              if (hasVideo && isCompact) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Brand.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => launchUrl(Uri.parse(videoUrl), webOnlyWindowName: '_blank'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 15, color: Brand.gold),
                  label: const Text('Watch Video', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultContent(LearningWeekDto weekData) {
    if (weekData.attempts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.assignment_late_outlined, size: 40, color: Color(0xFF94A3B8)),
            SizedBox(height: 10),
            Text(
              'No test submission yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Brand.navy),
            ),
            SizedBox(height: 4),
            Text(
              'The student has not submitted any attempt for this weekly test.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final attempts = weekData.attempts;
    final activeIndex = _selectedAttemptIndex.clamp(0, attempts.length - 1);
    final activeAttempt = attempts[activeIndex];

    // Compute score for active attempt
    int correctCount = 0;
    for (final q in weekData.questions) {
      final chosenId = activeAttempt.optionIdFor(q.id);
      final chosen = q.options.where((o) => o.id == chosenId).firstOrNull;
      if (chosen?.isCorrect == true) {
        correctCount++;
      }
    }
    final totalCount = weekData.questions.length;
    final pct = totalCount > 0 ? ((correctCount / totalCount) * 100).round() : 0;
    final isPassing = pct >= 70;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Attempts switcher if multiple attempts
        if (attempts.length > 1) ...[
          Row(
            children: [
              for (int i = 0; i < attempts.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('Attempt ${attempts[i].attemptNumber}'),
                    selected: activeIndex == i,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedAttemptIndex = i);
                    },
                    selectedColor: Brand.navy,
                    labelStyle: TextStyle(
                      color: activeIndex == i ? Colors.white : Brand.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Score Summary Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isPassing ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPassing ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isPassing ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: isPassing ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: $correctCount of $totalCount correct ($pct%)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isPassing ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                    ),
                    if (activeAttempt.submittedAt != null)
                      Text(
                        'Submitted on ${_formatDateTime(activeAttempt.submittedAt)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPassing ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Questions List
        for (int i = 0; i < weekData.questions.length; i++) ...[
          _buildQuestionReviewCard(i + 1, weekData.questions[i], activeAttempt),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildQuestionReviewCard(int questionNum, LearningQuestionDto question, LearningAttemptDto attempt) {
    final chosenOptId = attempt.optionIdFor(question.id);
    final chosenOpt = question.options.where((o) => o.id == chosenOptId).firstOrNull;
    final isCorrect = chosenOpt?.isCorrect == true;
    final notAnswered = chosenOpt == null;

    final correctOpt = question.options.where((o) => o.isCorrect == true).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: notAnswered
              ? const Color(0xFFE2E8F0)
              : (isCorrect ? const Color(0xFF86EFAC) : const Color(0xFFFECACA)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Q$questionNum',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Brand.navy),
                ),
              ),
              const Spacer(),
              if (notAnswered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Not answered', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
                )
              else if (isCorrect)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 12, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text('Correct', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close_rounded, size: 12, color: Color(0xFFDC2626)),
                      SizedBox(width: 4),
                      Text('Incorrect', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.questionText,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          // Student's answer
          if (chosenOpt != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCorrect ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
                    size: 16,
                    color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                        children: [
                          const TextSpan(
                            text: "Student's answer: ",
                            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          ),
                          TextSpan(
                            text: chosenOpt.optionText,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isCorrect ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Correct answer if missed
          if (!isCorrect && correctOpt != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                        children: [
                          const TextSpan(
                            text: "Correct answer: ",
                            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                          ),
                          TextSpan(
                            text: correctOpt.optionText,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                          ),
                        ],
                      ),
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

  String _formatDateTime(String? raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[local.month - 1];
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day} $month ${local.year}, $hour:$minute $amPm';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDE0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Brand.navy)),
    );
  }
}
