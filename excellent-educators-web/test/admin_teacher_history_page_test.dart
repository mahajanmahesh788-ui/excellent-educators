import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/pages/admin_teacher_history_page.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';
import 'package:excellent_educators_web/features/auth/domain/repositories/auth_repository.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_feature_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<String?> readToken() async => 'fake-token';

  @override
  Future<AppUser> me() async => const AppUser(
        id: 'admin_1',
        name: 'Admin User',
        email: 'admin@test.com',
        status: 'active',
        roles: ['super_admin'],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const sampleCounts = TeacherHistoryCountsDto(
    interviews: 10,
    interviewsHeld: 8,
    masterClasses: 25,
    masterClassesHeld: 24,
    leaveDays: 2,
    ratingsSubmitted: 15,
    conflictsReported: 1,
    ratingAverage: 4.8,
    classesCancelled: 1,
  );

  final sampleHistory = TeacherHistoryDto(
    teacherName: 'John Doe',
    currentYear: 2026,
    currentMonth: 9,
    thisMonth: sampleCounts,
    allTime: sampleCounts,
    byMonth: const [
      TeacherHistoryMonthDto(
        year: 2026,
        month: 9,
        counts: sampleCounts,
      ),
      TeacherHistoryMonthDto(
        year: 2026,
        month: 8,
        counts: sampleCounts,
      ),
    ],
    events: const [
      TeacherHistoryEventDto(
        id: 'evt_1',
        kind: 'introduction_call',
        date: '2026-09-14',
        time: '10:00',
        endTime: '11:00',
        title: 'Introduction Call',
        detail: 'Initial onboarding call with student',
        status: 'held',
        tags: [TeacherHistoryTagDto(label: 'Call 1/1', tone: 'info')],
        facts: [TeacherHistoryFactDto(label: 'Level', value: 'Career Explorer')],
        studentId: 'stud_1',
        studentName: 'Alice Smith',
        studentCode: 'EE-2026-001',
      ),
      TeacherHistoryEventDto(
        id: 'evt_2',
        kind: 'master_class',
        date: '2026-09-13',
        time: '14:00',
        endTime: '15:00',
        title: 'Master Class: Week 2',
        detail: 'Weekly mentoring session',
        status: 'cancelled',
        tags: [TeacherHistoryTagDto(label: 'Cancelled', tone: 'danger')],
        facts: [TeacherHistoryFactDto(label: 'Attendance', value: 'Student Absent')],
        studentId: 'stud_2',
        studentName: 'Bob Jones',
        studentCode: 'EE-2026-002',
      ),
      TeacherHistoryEventDto(
        id: 'evt_3',
        kind: 'conflict',
        date: '2026-09-12',
        time: '09:00',
        endTime: '10:00',
        title: 'Class Conflict Reported',
        detail: 'Teacher reported student did not join',
        status: 'pending',
        tags: [TeacherHistoryTagDto(label: 'Conflict', tone: 'danger')],
        facts: [TeacherHistoryFactDto(label: 'Reason', value: 'No show')],
        conflictId: 'issue_1',
        conflictStatus: 'pending',
      ),
    ],
  );

  testWidgets('Teacher history renders compact KPI ribbon, search and filters', (tester) async {
    final router = GoRouter(
      initialLocation: RoutePaths.adminTeacherHistoryFor('teach_1'),
      routes: [
        GoRoute(
          path: RoutePaths.adminTeacherHistory,
          builder: (context, state) => AdminTeacherHistoryPage(
            teacherId: state.pathParameters['id']!,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
          adminTeacherHistoryProvider('teach_1').overrideWith((ref) => Future.value(sampleHistory)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify teacher name in header
    expect(find.text('John Doe'), findsOneWidget);

    // Verify compact metric ribbon labels
    expect(find.text('Interviews'), findsWidgets);
    expect(find.text('Master Classes'), findsWidgets);
    expect(find.text('8 / 10'), findsOneWidget);
    expect(find.text('24 / 25'), findsOneWidget);
    expect(find.text('4.8 ★'), findsOneWidget);

    // Verify search field exists
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search student, code, class, note...'), findsOneWidget);

    // Verify category filter chips
    expect(find.text('All (3)'), findsOneWidget);
    expect(find.text('Interviews (1)'), findsOneWidget);
    expect(find.text('Master Classes (1)'), findsOneWidget);
    expect(find.text('Conflicts (1)'), findsOneWidget);

    // Verify timeline view toggle and monthly table toggle
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Monthly Table'), findsOneWidget);

    // Verify events in timeline
    expect(find.text('Introduction Call'), findsOneWidget);
    expect(find.text('Master Class: Week 2'), findsOneWidget);
    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.text('(EE-2026-001)'), findsOneWidget);

    // Search filter test: type 'Alice'
    await tester.enterText(find.byType(TextField), 'Alice');
    await tester.pumpAndSettle();

    expect(find.text('Introduction Call'), findsOneWidget);
    expect(find.text('Master Class: Week 2'), findsNothing);
    expect(find.text('Showing 1'), findsOneWidget);

    // Clear search
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    expect(find.text('Master Class: Week 2'), findsOneWidget);

    // Switch to Monthly Table view
    await tester.tap(find.text('Monthly Table'));
    await tester.pumpAndSettle();

    expect(find.text('Interviews (Held / Total)'), findsOneWidget);
    expect(find.text('Master Classes (Held / Total)'), findsOneWidget);
    expect(find.text('View Events'), findsWidgets);
  });
}
