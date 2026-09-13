import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:excellent_educators_web/features/learning/presentation/widgets/current_learning_card.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_dashboard.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/mandatory_assessment_panel.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_journey.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentDashboardPage extends ConsumerWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentProfileProvider);
    final eligibility = ref.watch(studentEligibilityProvider);
    final bookings = ref.watch(studentBookingsProvider);
    final assessment = ref.watch(studentAssessmentProvider);
    final learning = ref.watch(studentLearningDashboardProvider);
    final assessmentPending = assessment.maybeWhen(
      data: (payload) => payload.available && payload.assessment != null,
      orElse: () => false,
    );

    return StudentScaffold(
      title: 'Dashboard',
      body: profile.when(
        skipLoadingOnReload: true,
        loading: () => ListView(
          children: const [
            AcademySkeleton(height: 220),
            SizedBox(height: 16),
            AcademySkeleton(height: 180),
          ],
        ),
        error: (_, _) => AcademyError(onRetry: () => ref.invalidate(studentProfileProvider)),
        data: (student) {
          if (assessmentPending) {
            return ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                StudentHero(
                  student: student,
                  snapshot: StudentJourneySnapshot(
                    nextSession: null,
                    introduction: const JourneyNode(
                      title: 'Introduction',
                      detail: 'Waiting',
                      phase: JourneyPhase.upcoming,
                    ),
                    masterClass: const JourneyNode(
                      title: 'Master Class',
                      detail: 'Upcoming',
                      phase: JourneyPhase.upcoming,
                    ),
                    nextMonth: const JourneyNode(
                      title: 'Next Month',
                      detail: 'Upcoming',
                      phase: JourneyPhase.upcoming,
                    ),
                    masterThisMonth: 0,
                    introductionCompleted: false,
                    canBookIntroduction: false,
                    canBookMasterClass: false,
                  ),
                ),
                const SizedBox(height: 24),
                const MandatoryAssessmentPanel(),
              ],
            );
          }

          final loadingJourney = eligibility.isLoading || bookings.isLoading;
          if (eligibility.hasError || bookings.hasError) {
            return ListView(
              children: [
                StudentHero(
                  student: student,
                  snapshot: StudentJourneySnapshot(
                    nextSession: null,
                    introduction: const JourneyNode(title: 'Introduction', detail: '—', phase: JourneyPhase.upcoming),
                    masterClass: const JourneyNode(title: 'Master Class', detail: '—', phase: JourneyPhase.upcoming),
                    nextMonth: const JourneyNode(title: 'Next Month', detail: '—', phase: JourneyPhase.upcoming),
                    masterThisMonth: 0,
                    introductionCompleted: false,
                    canBookIntroduction: false,
                    canBookMasterClass: false,
                  ),
                ),
                const SizedBox(height: 24),
                AcademyError(
                  message: 'Something went wrong while loading your sessions.',
                  onRetry: () {
                    ref.invalidate(studentEligibilityProvider);
                    ref.invalidate(studentBookingsProvider);
                  },
                ),
              ],
            );
          }

          final snapshot = loadingJourney
              ? null
              : buildStudentJourney(
                  eligibility: eligibility.requireValue,
                  bookings: bookings.requireValue,
                );
          return ListView(
            padding: const EdgeInsets.only(bottom: 48),
            children: [
              if (snapshot == null)
                const AcademySkeleton(height: 220)
              else
                StudentHero(student: student, snapshot: snapshot),
              const SizedBox(height: 24),
              learning.when(
                loading: () => const AcademySkeleton(height: 180),
                error: (_, _) => AcademyError(onRetry: () => ref.invalidate(studentLearningDashboardProvider)),
                data: (dashboard) => CurrentLearningCard(dashboard: dashboard),
              ),
              const SizedBox(height: 24),
              if (snapshot == null)
                const AcademySkeleton(height: 200)
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 900) {
                      return Column(
                        children: [
                          NextSessionCard(snapshot: snapshot),
                          const SizedBox(height: 16),
                          LearningJourney(snapshot: snapshot),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: NextSessionCard(snapshot: snapshot)),
                        const SizedBox(width: 16),
                        Expanded(child: LearningJourney(snapshot: snapshot)),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 32),
              if (snapshot != null) MonthlyProgressCard(snapshot: snapshot),
              const SizedBox(height: 32),
              const AcademyLabel('What would you like to do?'),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 640 ? 2 : 1;
                  const gap = 12.0;
                  final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
                  final actions = [
                    QuickActionCard(
                      title: bookingActionLabel(snapshot?.primaryType),
                      body: 'Find your next available time.',
                      onTap: () {
                        final type = snapshot?.primaryType;
                        context.go(type == null ? RoutePaths.studentBookNew : '${RoutePaths.studentBookNew}?type=$type');
                      },
                    ),
                    QuickActionCard(
                      title: 'My sessions',
                      body: 'View upcoming and past sessions.',
                      onTap: () => context.go(RoutePaths.studentBookings),
                    ),
                    QuickActionCard(
                      title: 'Feedback',
                      body: 'Review your monthly guidance & notes.',
                      onTap: () => context.go(RoutePaths.studentFeedback),
                    ),
                    QuickActionCard(
                      title: 'Request help',
                      body: 'Need something from our team?',
                      onTap: () => context.go(RoutePaths.studentRequests),
                    ),
                  ];
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [for (final action in actions) SizedBox(width: width, child: action)],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
