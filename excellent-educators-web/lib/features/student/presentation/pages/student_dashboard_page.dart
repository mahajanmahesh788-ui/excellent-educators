import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_dashboard.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/achievement_cards.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/book_class_section.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/fresh_student_onboarding.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/learning_journal_preview.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/mandatory_assessment_panel.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/next_class_card.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/progress_overview.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_hero_section.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_journey.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_motivational_card.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/upcoming_classes_timeline.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/weekly_journey.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/weekly_learning_section.dart';

class StudentDashboardPage extends ConsumerWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentProfileProvider);
    final eligibility = ref.watch(studentEligibilityProvider);
    final bookings = ref.watch(studentBookingsProvider);
    final assessment = ref.watch(studentAssessmentProvider);
    final learning = ref.watch(studentLearningDashboardProvider);
    final journal = ref.watch(studentLearningJournalProvider);

    final assessmentPending = assessment.maybeWhen(
      data: (payload) => payload.available && payload.assessment != null,
      orElse: () => false,
    );

    return StudentScaffold(
      title: AppStrings.dashboard,
      body: profile.when(
        skipLoadingOnReload: true,
        loading: () => ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: const [
            AcademySkeleton(height: 240),
            SizedBox(height: 18),
            AcademySkeleton(height: 160),
            SizedBox(height: 18),
            AcademySkeleton(height: 200),
          ],
        ),
        error: (_, _) =>
            AcademyError(onRetry: () => ref.invalidate(studentProfileProvider)),
        data: (student) {
          if (assessmentPending) {
            return _FreshStudentOnboardingView(student: student);
          }

          final loadingJourney = eligibility.isLoading || bookings.isLoading;
          if (eligibility.hasError || bookings.hasError) {
            return ListView(
              children: [
                StudentHeroSection(
                  student: student,
                  snapshot: StudentJourneySnapshot(
                    nextSession: null,
                    introduction: const JourneyNode(
                      title: AppStrings.introduction,
                      detail: '—',
                      phase: JourneyPhase.upcoming,
                    ),
                    masterClass: const JourneyNode(
                      title: AppStrings.masterClass,
                      detail: '—',
                      phase: JourneyPhase.upcoming,
                    ),
                    nextMonth: const JourneyNode(
                      title: AppStrings.nextMonth,
                      detail: '—',
                      phase: JourneyPhase.upcoming,
                    ),
                    masterThisMonth: 0,
                    introductionCompleted: false,
                    canBookIntroduction: false,
                    canBookMasterClass: false,
                  ),
                ),
                const SizedBox(height: 24),
                AcademyError(
                  message:
                      AppStrings.somethingWentWrongWhileLoadingYourSessions,
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

          final learningDashboard = learning.valueOrNull;
          final journalData = journal.valueOrNull;
          final bookingsList = bookings.valueOrNull ?? const [];

          if (snapshot == null) {
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: const [
                AcademySkeleton(height: 240),
                SizedBox(height: 18),
                AcademySkeleton(height: 160),
                SizedBox(height: 18),
                AcademySkeleton(height: 200),
              ],
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1080;
              final isTablet =
                  constraints.maxWidth >= 680 && constraints.maxWidth < 1080;

              if (isDesktop) {
                return _buildDesktopLayout(
                  student: student,
                  snapshot: snapshot,
                  learningDashboard: learningDashboard,
                  journalData: journalData,
                  bookingsList: bookingsList,
                );
              }

              if (isTablet) {
                return _buildTabletLayout(
                  student: student,
                  snapshot: snapshot,
                  learningDashboard: learningDashboard,
                  journalData: journalData,
                  bookingsList: bookingsList,
                );
              }

              return _buildMobileLayout(
                student: student,
                snapshot: snapshot,
                learningDashboard: learningDashboard,
                journalData: journalData,
                bookingsList: bookingsList,
              );
            },
          );
        },
      ),
    );
  }

  /// Modern Asymmetric Desktop 2-Column Layout
  Widget _buildDesktopLayout({
    required dynamic student,
    required StudentJourneySnapshot snapshot,
    required dynamic learningDashboard,
    required dynamic journalData,
    required List<dynamic> bookingsList,
  }) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 48),
      children: [
        // 1. Personalized Hero Banner
        StudentHeroSection(
          student: student,
          snapshot: snapshot,
          learning: learningDashboard,
        ),

        if (snapshot.hasExtraMasterClasses) ...[
          const SizedBox(height: 16),
          const ExtraMasterClassBanner(),
        ],

        const SizedBox(height: 16),

        // Asymmetric Two-Column Grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Main Journey Column (65% width)
            Expanded(
              flex: 65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Weekly Learning Pathway
                  WeeklyJourneyWidget(
                    snapshot: snapshot,
                    learning: learningDashboard,
                  ),
                  const SizedBox(height: 14),

                  // Dynamic Weekly Learning Activities
                  if (learningDashboard != null) ...[
                    WeeklyLearningSection(dashboard: learningDashboard),
                    const SizedBox(height: 14),
                  ],

                  // Book a Master Class CTA & Mentor Showcase
                  BookClassSection(student: student, snapshot: snapshot),
                  const SizedBox(height: 14),

                  // Learning Journal Notebook Preview
                  LearningJournalPreviewWidget(
                    learning: learningDashboard,
                    journal: journalData,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Right Command Sidebar (35% width)
            Expanded(
              flex: 35,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Next Class / Today Action Card
                  NextClassCard(snapshot: snapshot),
                  const SizedBox(height: 14),

                  // Circular Progress & Milestone Gauges
                  ProgressOverviewWidget(
                    student: student,
                    snapshot: snapshot,
                    learning: learningDashboard,
                  ),
                  const SizedBox(height: 14),

                  // Upcoming Schedule Timeline Rail
                  UpcomingClassesTimeline(
                    bookings: List.from(bookingsList),
                    snapshot: snapshot,
                  ),
                  const SizedBox(height: 14),

                  // Achievements & Learning Streak
                  AchievementCardsWidget(
                    student: student,
                    snapshot: snapshot,
                    learning: learningDashboard,
                  ),
                  const SizedBox(height: 14),

                  // Motivational Quote
                  const StudentMotivationalCard(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Tablet Responsive Layout
  Widget _buildTabletLayout({
    required dynamic student,
    required StudentJourneySnapshot snapshot,
    required dynamic learningDashboard,
    required dynamic journalData,
    required List<dynamic> bookingsList,
  }) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 36),
      children: [
        StudentHeroSection(
          student: student,
          snapshot: snapshot,
          learning: learningDashboard,
        ),
        if (snapshot.hasExtraMasterClasses) ...[
          const SizedBox(height: 14),
          const ExtraMasterClassBanner(),
        ],
        const SizedBox(height: 14),

        // Row of 2 Action & Progress cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: NextClassCard(snapshot: snapshot)),
            const SizedBox(width: 16),
            Expanded(
              child: ProgressOverviewWidget(
                student: student,
                snapshot: snapshot,
                learning: learningDashboard,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        WeeklyJourneyWidget(snapshot: snapshot, learning: learningDashboard),
        const SizedBox(height: 14),

        if (learningDashboard != null) ...[
          WeeklyLearningSection(dashboard: learningDashboard),
          const SizedBox(height: 14),
        ],

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: UpcomingClassesTimeline(
                bookings: List.from(bookingsList),
                snapshot: snapshot,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  BookClassSection(student: student, snapshot: snapshot),
                  const SizedBox(height: 16),
                  AchievementCardsWidget(
                    student: student,
                    snapshot: snapshot,
                    learning: learningDashboard,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        LearningJournalPreviewWidget(
          learning: learningDashboard,
          journal: journalData,
        ),
        const SizedBox(height: 14),

        const StudentMotivationalCard(),
      ],
    );
  }

  /// Mobile Priority Layout
  /// Priority:
  /// 1. Greeting
  /// 2. Next Class
  /// 3. Today's Activities / Weekly Journey
  /// 4. Progress
  /// 5. Weekly Learning
  /// 6. Upcoming Classes
  /// 7. Booking
  /// 8. Journal
  /// 9. Achievements
  /// 10. Motivation
  Widget _buildMobileLayout({
    required dynamic student,
    required StudentJourneySnapshot snapshot,
    required dynamic learningDashboard,
    required dynamic journalData,
    required List<dynamic> bookingsList,
  }) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        // 1. Greeting & Hero
        StudentHeroSection(
          student: student,
          snapshot: snapshot,
          learning: learningDashboard,
        ),
        if (snapshot.hasExtraMasterClasses) ...[
          const SizedBox(height: 12),
          const ExtraMasterClassBanner(),
        ],
        const SizedBox(height: 14),

        // 2. Next Class ("Next Up")
        NextClassCard(snapshot: snapshot),
        const SizedBox(height: 14),

        // 3. Today's Activities / Weekly Journey
        WeeklyJourneyWidget(snapshot: snapshot, learning: learningDashboard),
        const SizedBox(height: 14),

        // 4. Progress (Level & Ring)
        ProgressOverviewWidget(
          student: student,
          snapshot: snapshot,
          learning: learningDashboard,
        ),
        const SizedBox(height: 14),

        // 5. Weekly Learning
        if (learningDashboard != null) ...[
          WeeklyLearningSection(dashboard: learningDashboard),
          const SizedBox(height: 14),
        ],

        // 6. Upcoming Classes
        UpcomingClassesTimeline(
          bookings: List.from(bookingsList),
          snapshot: snapshot,
        ),
        const SizedBox(height: 14),

        // 7. Booking Master Class
        BookClassSection(student: student, snapshot: snapshot),
        const SizedBox(height: 14),

        // 8. Learning Journal
        LearningJournalPreviewWidget(
          learning: learningDashboard,
          journal: journalData,
        ),
        const SizedBox(height: 14),

        // 9. Achievements
        AchievementCardsWidget(
          student: student,
          snapshot: snapshot,
          learning: learningDashboard,
        ),
        const SizedBox(height: 14),

        // 10. Motivation
        const StudentMotivationalCard(),
      ],
    );
  }
}

class _FreshStudentOnboardingView extends StatefulWidget {
  const _FreshStudentOnboardingView({required this.student});

  final StudentDto student;

  @override
  State<_FreshStudentOnboardingView> createState() =>
      _FreshStudentOnboardingViewState();
}

class _FreshStudentOnboardingViewState
    extends State<_FreshStudentOnboardingView> {
  final _scrollController = ScrollController();
  final _questionnaireKey = GlobalKey();

  void _scrollToQuestionnaire() {
    final ctx = _questionnaireKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 48),
      children: [
        FreshStudentHero(
          student: widget.student,
          onStartQuestionnaire: _scrollToQuestionnaire,
        ),
        const SizedBox(height: 14),
        const FreshStudentStepper(),
        const SizedBox(height: 18),
        FreshStudentLockBanner(onContinue: _scrollToQuestionnaire),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _questionnaireKey,
          child: const MandatoryAssessmentPanel(),
        ),
        const SizedBox(height: 24),
        const FreshStudentRoadmapCard(),
      ],
    );
  }
}
