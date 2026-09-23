import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_feature_providers.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/pages/student_booking_pages.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
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
              id: 'u_1',
              name: 'John Student',
              email: 'john@example.com',
              status: 'active',
              roles: roles,
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const student = StudentDto(
    id: 's_1',
    studentCode: '26-0001',
    fullName: 'John Student',
    email: 'john@example.com',
    phone: '9876543210',
    classGrade: 7,
    status: 'active',
    level: NamedRef(id: 'lvl_1', label: 'Level 1'),
    batch: NamedRef(id: 'batch_1', label: 'Batch 1'),
  );

  testWidgets('StudentBookingsPage renders header, KPI metrics, spotlight card, and session list', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final futureDate1 = now.add(const Duration(days: 1));
    final futureDate2 = now.add(const Duration(days: 3));
    final pastDate1 = now.subtract(const Duration(days: 2));

    final upcoming1 = SessionBookingDto(
      id: 'b_up_1',
      studentId: 's_1',
      teacherId: 't_1',
      type: 'master_class',
      date: '${futureDate1.year}-${futureDate1.month.toString().padLeft(2, '0')}-${futureDate1.day.toString().padLeft(2, '0')}',
      start: '16:00',
      end: '17:00',
      status: 'scheduled',
      startsAtIso: futureDate1.toIso8601String(),
      endsAtIso: futureDate1.add(const Duration(hours: 1)).toIso8601String(),
      teacherName: 'Sarah Master Teacher',
    );

    final upcoming2 = SessionBookingDto(
      id: 'b_up_2',
      studentId: 's_1',
      teacherId: 't_2',
      type: 'introduction_call',
      date: '${futureDate2.year}-${futureDate2.month.toString().padLeft(2, '0')}-${futureDate2.day.toString().padLeft(2, '0')}',
      start: '10:00',
      end: '10:30',
      status: 'scheduled',
      startsAtIso: futureDate2.toIso8601String(),
      endsAtIso: futureDate2.add(const Duration(minutes: 30)).toIso8601String(),
      teacherName: 'David Advisor',
    );

    final past1 = SessionBookingDto(
      id: 'b_past_1',
      studentId: 's_1',
      teacherId: 't_1',
      type: 'master_class',
      date: '${pastDate1.year}-${pastDate1.month.toString().padLeft(2, '0')}-${pastDate1.day.toString().padLeft(2, '0')}',
      start: '14:00',
      end: '15:00',
      status: 'completed',
      startsAtIso: pastDate1.toIso8601String(),
      endsAtIso: pastDate1.add(const Duration(hours: 1)).toIso8601String(),
      teacherName: 'Sarah Master Teacher',
      attendance: const BookingAttendanceDto(canReportTeacherDidNotJoin: true),
    );

    final List<SessionBookingDto> bookings = [past1, upcoming2, upcoming1]; // deliberately unsorted

    final router = GoRouter(
      initialLocation: RoutePaths.studentBookings,
      routes: [
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
          studentAssessmentProvider.overrideWith((ref) => Future.value(const StudentAssessmentPayload(available: false))),
          unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
          studentEligibilityProvider.overrideWith(
            (ref) => Future.value(
              const BookingEligibilityDto(
                introductionCompleted: true,
                canBookIntroduction: false,
                canBookMasterClass: true,
                masterClassRemaining: 2,
              ),
            ),
          ),
          studentBookingsProvider.overrideWith((ref) => Future.value(bookings)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Page Header
    expect(find.text('My Sessions 👋'), findsOneWidget);
    expect(find.text('Keep track of your classes, mentoring sessions, and learning progress.'), findsOneWidget);
    expect(find.text('Book Master Class'), findsOneWidget);

    // Verify KPI Metrics
    expect(find.text('Completed'), findsWidgets);
    expect(find.text('Total Sessions'), findsOneWidget);
    expect(find.text('Next Session'), findsOneWidget);
    expect(find.text('1'), findsWidgets); // 1 completed
    expect(find.text('3'), findsWidgets); // 3 total
    expect(find.textContaining('Ready on calendar'), findsNothing);

    // Verify Spotlight Next Session Card
    expect(find.text('NEXT UP ON CALENDAR'), findsOneWidget);
    expect(find.text('Sarah Master Teacher'), findsWidgets);

    // Verify Filter Switcher Tabs
    expect(find.text('All Sessions'), findsOneWidget);
    expect(find.text('Past Sessions'), findsOneWidget);

    // Verify Section Headers for Timeline
    expect(find.text('UPCOMING SESSIONS (2)'), findsOneWidget);
    expect(find.text('PAST SESSION HISTORY (1)'), findsOneWidget);

    // Verify Chronological Ordering: b_up_1 (tomorrow) before b_up_2 (in 3 days)
    final sarahFinder = find.text('Sarah Master Teacher');
    final davidFinder = find.text('David Advisor');
    expect(davidFinder, findsOneWidget);
    // Find timeline cards
    final sarahCard = tester.getTopLeft(sarahFinder.first);
    final davidCard = tester.getTopLeft(davidFinder);
    expect(sarahCard.dy < davidCard.dy, isTrue);

    // Verify Tab Switching: Switch to 'Past Sessions'
    await tester.tap(find.text('Past Sessions'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('SESSION HISTORY (1)'), findsOneWidget);
    expect(find.text('UPCOMING SESSIONS (2)'), findsNothing);

    // Switch to 'Upcoming' tab pill
    await tester.tap(find.text('Upcoming'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('UPCOMING TIMELINE (2)'), findsOneWidget);
    expect(find.text('PAST SESSION HISTORY (1)'), findsNothing);
  });

  testWidgets('StudentBookingsPage enables Join button when attendance canJoin is true', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final liveBooking = SessionBookingDto(
      id: 'b_live',
      studentId: 's_1',
      teacherId: 't_1',
      type: 'master_class',
      date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      start: '${now.hour.toString().padLeft(2, '0')}:00',
      end: '${(now.hour + 1).toString().padLeft(2, '0')}:00',
      status: 'scheduled',
      startsAtIso: now.toIso8601String(),
      endsAtIso: now.add(const Duration(hours: 1)).toIso8601String(),
      meetingUrl: 'https://meet.google.com/abc-defg-hij',
      teacherName: 'Sarah Master Teacher',
      attendance: const BookingAttendanceDto(canJoin: true),
    );

    final router = GoRouter(
      initialLocation: RoutePaths.studentBookings,
      routes: [
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
          studentAssessmentProvider.overrideWith((ref) => Future.value(const StudentAssessmentPayload(available: false))),
          unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
          studentEligibilityProvider.overrideWith(
            (ref) => Future.value(
              const BookingEligibilityDto(
                introductionCompleted: true,
                canBookIntroduction: false,
                canBookMasterClass: true,
              ),
            ),
          ),
          studentBookingsProvider.overrideWith((ref) => Future.value([liveBooking])),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Spotlight card shows live session status
    expect(find.text('LIVE SESSION SPOTLIGHT'), findsOneWidget);
    expect(find.text('Happening Now'), findsOneWidget);
    // Join button is available and enabled
    expect(find.text('Join Master Class Now'), findsWidgets);
  });
}
