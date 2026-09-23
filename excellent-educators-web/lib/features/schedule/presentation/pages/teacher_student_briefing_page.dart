import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/core/widgets/portal_chrome.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/compact_assessment_card.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/monthly_rating_history.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:excellent_educators_web/features/learning/presentation/widgets/learning_journal_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

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
    final isMaster =
        ref.watch(authControllerProvider).user?.isMasterTeacher ?? false;
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
      title: AppStrings.studentHistory,
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
                        Text(
                          student.fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Brand.navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (student.studentCode.isNotEmpty)
                              _InfoChip(student.studentCode),
                            if (student.classGrade > 0)
                              _InfoChip('Class ${student.classGrade}'),
                            if (student.level != null &&
                                !student.level!.isEmpty)
                              _InfoChip(student.level!.label),
                            if (student.batch != null &&
                                !student.batch!.isEmpty)
                              _InfoChip(student.batch!.label),
                            if (slotLabel != null && slotLabel!.isNotEmpty)
                              _InfoChip(slotLabel!),
                          ],
                        ),
                        if (student.feedbackOverallAverage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Overall rating ${student.feedbackOverallAverage!.toStringAsFixed(1)} / 10 · ${student.feedbackTotalSessions} monthly ratings',
                            style: const TextStyle(
                              color: Brand.muted,
                              fontWeight: FontWeight.w600,
                            ),
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
                      Tab(text: AppStrings.n1stAssignment),
                      Tab(text: AppStrings.ratings),
                      Tab(text: AppStrings.weeklyTests),
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
                            ref.invalidate(
                              masterTeacherStudentResultsProvider(studentId),
                            );
                            ref.invalidate(
                              teacherStudentResultsProvider(studentId),
                            );
                          },
                          builder: (items) {
                            if (items.isEmpty) {
                              return const EmptyHint(
                                AppStrings.noFirstAssignmentYet,
                                subtitle: AppStrings
                                    .theGettingToKnowYouAptitudeResultWillAppearHere,
                                fillHeight: false,
                              );
                            }
                            return ListView(
                              children: [
                                const Text(
                                  AppStrings.firstAssignmentResult,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Brand.navy,
                                  ),
                                ),
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
                            ref.invalidate(
                              masterTeacherStudentFeedbackProvider(studentId),
                            );
                            ref.invalidate(
                              teacherStudentFeedbackProvider(studentId),
                            );
                          },
                          builder: (items) {
                            if (items.isEmpty) {
                              return const EmptyHint(
                                AppStrings.noMonthlyRatingsYet,
                                subtitle: AppStrings
                                    .previousMasterClassRatingsWillBeListedHereNewestFirst,
                                fillHeight: false,
                              );
                            }
                            return ListView(
                              children: [
                                const Text(
                                  AppStrings.previousRatings,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Brand.navy,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                MonthlyRatingHistoryList(items: items),
                              ],
                            );
                          },
                        ),
                        AsyncBody(
                          value: journal,
                          onRetry: () {
                            ref.invalidate(
                              masterTeacherLearningJournalProvider(studentId),
                            );
                            ref.invalidate(
                              teacherLearningJournalProvider(studentId),
                            );
                          },
                          builder: (data) {
                            if (data.levels.isEmpty) {
                              return const EmptyHint(
                                AppStrings.noWeeklyTestsYet,
                                subtitle: AppStrings
                                    .weeklyAssignmentsFromTheLearningJourneyWillAppearHereBy,
                                fillHeight: false,
                              );
                            }
                            return ListView(
                              children: [
                                LearningJournalTable(
                                  journal: data,
                                  staffView: true,
                                  onOpenWeek: (group, week) {
                                    final path = isMaster
                                        ? RoutePaths.masterTeacherStudentWeekFor(
                                            studentId,
                                            group.journeyId,
                                            week.weekNumber,
                                          )
                                        : RoutePaths.teacherScheduleStudentWeekFor(
                                            studentId,
                                            group.journeyId,
                                            week.weekNumber,
                                          );
                                    context.go(path);
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
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: Brand.navy,
        ),
      ),
    );
  }
}
