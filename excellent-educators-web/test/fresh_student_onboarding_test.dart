import 'dart:async';
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/assessments/data/assessment_repository.dart';
import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_feature_providers.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/pages/student_booking_pages.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/student/presentation/pages/student_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthController extends StateNotifier<AuthState> implements AuthController {
  _FakeAuthController({List<String> roles = const ['student']})
      : super(
          AuthState(
            isReady: true,
            user: AppUser(
              id: 's_1',
              name: 'Alice Student',
              email: 'alice@example.com',
              status: 'active',
              roles: roles,
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAssessmentRepo extends Fake implements AssessmentRepository {
  List<Map<String, dynamic>>? lastSubmittedAnswers;

  @override
  Future<void> submitAssessment(String id, List<Map<String, dynamic>> answers) async {
    lastSubmittedAnswers = answers;
  }
}

void main() {
  const student = StudentDto(
    id: 's_1',
    studentCode: '26-0001',
    fullName: 'Alice Student',
    email: 'alice@example.com',
    phone: '9876543210',
    classGrade: 7,
    status: 'active',
    level: NamedRef(id: 'lvl_1', label: 'Level 1'),
    batch: NamedRef(id: 'batch_1', label: 'Batch 1'),
  );

  const activeAssessment = AptitudeAssessmentDto(
    id: 'assess_1',
    title: 'Interest & Discovery Assessment',
    description: 'Help us learn what you enjoy',
    status: 'active',
    questionsCount: 2,
    questions: [
      AptitudeQuestionDto(
        id: 'q_1',
        questionText: 'When working on a group challenge, which activity brings you the most energy?',
        displayOrder: 1,
        options: [
          AptitudeOptionDto(id: 'opt_1_a', displayOrder: 1, optionText: 'Brainstorming creative ideas and concepts'),
          AptitudeOptionDto(id: 'opt_1_b', displayOrder: 2, optionText: 'Organizing tasks, deadlines, and coordination'),
        ],
      ),
      AptitudeQuestionDto(
        id: 'q_2',
        questionText: 'What kind of topics make you lose track of time when exploring?',
        displayOrder: 2,
        options: [
          AptitudeOptionDto(id: 'opt_2_a', displayOrder: 1, optionText: 'How things work scientifically or logically'),
          AptitudeOptionDto(id: 'opt_2_b', displayOrder: 2, optionText: 'Human stories, cultures, and communication'),
        ],
      ),
    ],
  );

  const pendingPayload = StudentAssessmentPayload(
    available: true,
    assessment: activeAssessment,
  );

  testWidgets('Fresh Student Dashboard renders complete onboarding experience', (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeRepo = _FakeAssessmentRepo();

    final router = GoRouter(
      initialLocation: RoutePaths.studentDashboard,
      routes: [
        GoRoute(
          path: RoutePaths.studentDashboard,
          builder: (context, state) => const StudentDashboardPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => _FakeAuthController()),
          studentProfileProvider.overrideWith((ref) => Future.value(student)),
          studentAssessmentProvider.overrideWith((ref) => Future.value(pendingPayload)),
          assessmentRepositoryProvider.overrideWithValue(fakeRepo),
          unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
          studentEligibilityProvider.overrideWith(
            (ref) => Future.value(
              const BookingEligibilityDto(
                introductionCompleted: false,
                canBookIntroduction: false,
                canBookMasterClass: false,
              ),
            ),
          ),
          studentBookingsProvider.overrideWith((ref) => Future.value([])),
          studentLearningDashboardProvider.overrideWith((ref) => Completer<LearningDashboardDto>().future),
          studentLearningJournalProvider.overrideWith((ref) => Completer<LearningJournalDto>().future),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 1. Welcome Hero
    expect(find.text('Welcome to Excellent Educators, Alice 👋'), findsOneWidget);
    expect(find.text('STEP 1 OF YOUR JOURNEY'), findsOneWidget);
    expect(find.text('Start Questionnaire'), findsOneWidget);

    // 2. 4-Step Stepper
    expect(find.text('YOUR ONBOARDING JOURNEY'), findsOneWidget);
    expect(find.text('Discover Yourself'), findsWidgets);
    expect(find.text('Understand Strengths'), findsOneWidget);
    expect(find.text('Build Your Journey'), findsOneWidget);
    expect(find.text('Start Sessions'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);

    // 3. Lock State Action Banner
    expect(find.text('Your first step starts here 🚀'), findsOneWidget);
    expect(
      find.text('Complete your Discovery Questionnaire to unlock your learning journey and booking.'),
      findsOneWidget,
    );
    expect(find.text('Continue Questionnaire'), findsOneWidget);

    // 4. Discovery Questionnaire Header & Compulsory Badges
    expect(find.text('Required First Step'), findsOneWidget);
    expect(find.text('Mandatory for new students'), findsOneWidget);
    expect(find.text('DISCOVER WHAT LIGHTS YOU UP ✨'), findsOneWidget);
    expect(find.text('Start Your Journey'), findsOneWidget);
    expect(find.text('Before you book your first session, help us understand YOU.'), findsOneWidget);
    expect(
      find.text(
        'Answer these questions about your interests, hobbies, focus and mindset. There are no right or wrong answers — your responses help us understand you and guide your learning journey.',
      ),
      findsOneWidget,
    );

    // 5. Progress Indicator
    expect(find.text('Question 0 of 2 completed'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    // 6. Interactive Questions & Large Answer Option Cards
    expect(find.text('MOMENT 1'), findsOneWidget);
    expect(find.text('MOMENT 2'), findsOneWidget);
    expect(find.text('Brainstorming creative ideas and concepts'), findsOneWidget);
    expect(find.text('Organizing tasks, deadlines, and coordination'), findsOneWidget);

    // Select Option 1 for Question 1
    final option1Finder = find.text('Brainstorming creative ideas and concepts');
    await tester.ensureVisible(option1Finder);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(option1Finder);
    await tester.pump(const Duration(milliseconds: 200));

    // Progress updates to 1 of 2 (50%)
    expect(find.text('Question 1 of 2 completed'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Answered'), findsOneWidget);

    // Select Option 2 for Question 2
    final option2Finder = find.text('How things work scientifically or logically');
    await tester.ensureVisible(option2Finder);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(option2Finder);
    await tester.pump(const Duration(milliseconds: 200));

    // Progress updates to 2 of 2 (100%)
    expect(find.text('Question 2 of 2 completed'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    // 7. Submit Action
    final submitFinder = find.text('Complete My Discovery');
    await tester.ensureVisible(submitFinder);
    await tester.pump(const Duration(milliseconds: 200));
    expect(submitFinder, findsOneWidget);
    expect(find.text('Required before you can continue.'), findsOneWidget);

    // 8. What Happens Next Roadmap Card
    final roadmapFinder = find.text('WHAT HAPPENS NEXT?');
    await tester.ensureVisible(roadmapFinder);
    await tester.pump(const Duration(milliseconds: 200));
    expect(roadmapFinder, findsOneWidget);
    expect(find.text('Your Path After Completing Discovery'), findsOneWidget);
    expect(find.text('1. Discover Yourself'), findsOneWidget);
    expect(find.text('2. Understand Your Strengths'), findsOneWidget);
    expect(find.text('3. Build Your Skills'), findsOneWidget);
    expect(find.text('4. Start Your Sessions'), findsOneWidget);
  });

  testWidgets('Locked navigation items show friendly modal notice dialog', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final router = GoRouter(
      initialLocation: RoutePaths.studentDashboard,
      routes: [
        GoRoute(
          path: RoutePaths.studentDashboard,
          builder: (context, state) => const StudentDashboardPage(),
        ),
        GoRoute(
          path: RoutePaths.studentBookings,
          builder: (context, state) => const StudentBookingsPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => _FakeAuthController()),
          studentProfileProvider.overrideWith((ref) => Future.value(student)),
          studentAssessmentProvider.overrideWith((ref) => Future.value(pendingPayload)),
          unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
          studentEligibilityProvider.overrideWith(
            (ref) => Future.value(
              const BookingEligibilityDto(
                introductionCompleted: false,
                canBookIntroduction: false,
                canBookMasterClass: false,
              ),
            ),
          ),
          studentBookingsProvider.overrideWith((ref) => Future.value([])),
          studentLearningDashboardProvider.overrideWith((ref) => Completer<LearningDashboardDto>().future),
          studentLearningJournalProvider.overrideWith((ref) => Completer<LearningJournalDto>().future),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap locked 'My Sessions' nav item in header
    final sessionsNavItem = find.text('My Sessions');
    expect(sessionsNavItem, findsOneWidget);
    await tester.tap(sessionsNavItem);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify friendly LockedFeatureNoticeDialog appears
    expect(find.text('Complete your Discovery Questionnaire first'), findsOneWidget);
    expect(
      find.text('Access to My Sessions and session bookings unlocks as soon as you finish your Interest & Mindset Discovery.'),
      findsOneWidget,
    );
    expect(find.text('Maybe Later'), findsOneWidget);
    expect(find.text('Continue Questionnaire'), findsWidgets);
  });

  testWidgets('Directly opening bookings or booking wizard shows BookingQuestionnaireGuardCard', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final router = GoRouter(
      initialLocation: RoutePaths.studentBookings,
      routes: [
        GoRoute(
          path: RoutePaths.studentBookings,
          builder: (context, state) => const StudentBookingsPage(),
        ),
        GoRoute(
          path: RoutePaths.studentBookNew,
          builder: (context, state) => const StudentBookingWizardPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => _FakeAuthController()),
          studentProfileProvider.overrideWith((ref) => Future.value(student)),
          studentAssessmentProvider.overrideWith((ref) => Future.value(pendingPayload)),
          unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
          studentEligibilityProvider.overrideWith(
            (ref) => Future.value(
              const BookingEligibilityDto(
                introductionCompleted: false,
                canBookIntroduction: false,
                canBookMasterClass: false,
              ),
            ),
          ),
          studentBookingsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Booking Protection Guard is displayed
    expect(find.text('COMPULSORY FOR NEW STUDENTS'), findsOneWidget);
    expect(find.text('Complete Your First Step'), findsOneWidget);
    expect(
      find.text('Your Discovery Questionnaire is required before booking your first session. Help our mentors understand your interests, hobbies, and learning mindset.'),
      findsOneWidget,
    );
    expect(find.text('Complete Questionnaire'), findsOneWidget);
  });

  testWidgets('Submitting completed questionnaire displays celebration screen', (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeRepo = _FakeAssessmentRepo();

    final router = GoRouter(
      initialLocation: RoutePaths.studentDashboard,
      routes: [
        GoRoute(
          path: RoutePaths.studentDashboard,
          builder: (context, state) => const StudentDashboardPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => _FakeAuthController()),
          studentProfileProvider.overrideWith((ref) => Future.value(student)),
          studentAssessmentProvider.overrideWith((ref) => Future.value(pendingPayload)),
          assessmentRepositoryProvider.overrideWithValue(fakeRepo),
          unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
          studentEligibilityProvider.overrideWith(
            (ref) => Future.value(
              const BookingEligibilityDto(
                introductionCompleted: false,
                canBookIntroduction: false,
                canBookMasterClass: false,
              ),
            ),
          ),
          studentBookingsProvider.overrideWith((ref) => Future.value([])),
          studentLearningDashboardProvider.overrideWith((ref) => Completer<LearningDashboardDto>().future),
          studentLearningJournalProvider.overrideWith((ref) => Completer<LearningJournalDto>().future),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Answer both questions
    final opt1 = find.text('Brainstorming creative ideas and concepts');
    await tester.ensureVisible(opt1);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(opt1);
    await tester.pump(const Duration(milliseconds: 200));

    final opt2 = find.text('How things work scientifically or logically');
    await tester.ensureVisible(opt2);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(opt2);
    await tester.pump(const Duration(milliseconds: 200));

    // Tap Complete My Discovery button
    final submitButton = find.text('Complete My Discovery');
    await tester.ensureVisible(submitButton);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Confirm in dialog
    final confirmButton = find.descendant(
      of: find.byType(Dialog),
      matching: find.widgetWithText(FilledButton, 'Complete My Discovery'),
    );
    expect(confirmButton, findsOneWidget);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    // Verify celebration screen
    expect(find.text("🎉 You're all set!"), findsOneWidget);
    expect(find.text("We've got to know you a little better."), findsOneWidget);
    expect(find.textContaining("Your learning journey is now unlocked."), findsOneWidget);
    expect(find.text('Continue to Dashboard'), findsOneWidget);
    expect(fakeRepo.lastSubmittedAnswers?.length, 2);
  });
}
