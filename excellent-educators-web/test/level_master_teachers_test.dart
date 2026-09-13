import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/features/academic/data/academic_repository.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/pages/admin_batches_page.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_cards.dart';
import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_feature_providers.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/student/presentation/pages/student_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthController extends StateNotifier<AuthState> implements AuthController {
  _FakeAuthController({List<String> roles = const ['super_admin']})
      : super(
          AuthState(
            isReady: true,
            user: AppUser(
              id: 'u_1',
              name: 'Test User',
              email: 'test@example.com',
              status: 'active',
              roles: roles,
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAcademicRepo extends Fake implements AcademicRepository {
  AcademicLevelDto level = const AcademicLevelDto(
    id: 'lvl_1',
    name: 'Level 1',
    academicYear: 2026,
    status: 'active',
    studentsCount: 25,
    batchesCount: 1,
    batches: [
      BatchDto(
        id: 'batch_1',
        name: 'Batch 1',
        academicYear: 2026,
        status: 'active',
        activeStudentCount: 25,
        maxActiveStudents: 50,
      ),
    ],
    masterTeachers: [
      TeacherDto(
        id: 't_1',
        fullName: 'Master John Doe',
        email: 'john@example.com',
        phone: '9876543210',
        status: 'active',
        roles: ['master_teacher'],
      ),
    ],
  );

  @override
  Future<AcademicLevelDto> adminLevel(String id) async => level;

  @override
  Future<List<StudentDto>> adminBatchStudents(String batchId) async => [];

  @override
  Future<PagedResult> adminTeachers({
    String? search,
    String? status,
    String? role,
    String? excludeLevelId,
    int page = 1,
    int perPage = 25,
  }) async {
    return const PagedResult(
      items: [
        {
          'id': 't_1',
          'full_name': 'Teacher 1',
          'email': 't1@example.com',
          'status': 'active',
          'roles': ['master_teacher'],
          'assigned_levels': ['Level 1'],
        },
        {
          'id': 't_2',
          'full_name': 'Teacher 2',
          'email': 't2@example.com',
          'status': 'active',
          'roles': ['master_teacher'],
          'assigned_levels': [],
        },
      ],
      meta: {
        'total': 2,
        'page': 1,
        'per_page': 25,
      },
    );
  }

  @override
  List<TeacherDto> parseTeachers(PagedResult page) {
    return page.items.map((i) => TeacherDto.fromJson(i)).toList();
  }
}

void main() {
  testWidgets('StudentCard does not show Master Teacher: Not assigned', (tester) async {
    const student = StudentDto(
      id: 's_1',
      studentCode: '26-0001',
      fullName: 'Alice Walker',
      email: 'alice@example.com',
      phone: '9876543210',
      classGrade: 6,
      status: 'active',
      level: NamedRef(id: 'lvl_1', label: 'Level 1'),
      batch: NamedRef(id: 'batch_1', label: 'Batch 1'),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StudentCard(student: student),
        ),
      ),
    );

    expect(find.text('Master Teacher: Not assigned'), findsNothing);
    expect(find.text('Master Teacher'), findsNothing);
    expect(find.text('Career Compass'), findsNothing);
    expect(find.text('Alice Walker (26-0001)'), findsOneWidget);
    expect(find.textContaining('Level: Level 1'), findsOneWidget);
    expect(find.textContaining('Batch: Batch 1'), findsOneWidget);
  });

  testWidgets('StudentCard displays Assessment pending in top right when status is pending', (tester) async {
    const student = StudentDto(
      id: 's_1',
      studentCode: '26-0001',
      fullName: 'Alice Walker',
      email: 'alice@example.com',
      phone: '9876543210',
      classGrade: 6,
      status: 'active',
      aptitudeAssessmentStatus: 'pending',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StudentCard(student: student),
        ),
      ),
    );

    expect(find.text('Assessment pending'), findsOneWidget);
    expect(find.text('Alice Walker (26-0001)'), findsOneWidget);
  });

  testWidgets('Level Details displays Master Teachers section with assigned teachers', (tester) async {
    final fakeRepo = _FakeAcademicRepo();
    final router = GoRouter(
      initialLocation: '/admin/levels/lvl_1',
      routes: [
        GoRoute(
          path: '/admin/levels/:batchId',
          builder: (context, state) => AdminBatchDetailPage(
            batchId: state.pathParameters['batchId']!,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => _FakeAuthController(roles: ['super_admin'])),
          unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
          academicRepositoryProvider.overrideWithValue(fakeRepo),
          adminLevelProvider('lvl_1').overrideWith((ref) => Future.value(fakeRepo.level)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Master Teachers (1)'), findsOneWidget);
    expect(find.text('Master John Doe'), findsOneWidget);
    expect(find.text('Add Master Teacher'), findsOneWidget);
  });

  testWidgets('Student Dashboard does not show teacher grid', (tester) async {
    const student = StudentDto(
      id: 's_1',
      studentCode: '26-0001',
      fullName: 'Alice Walker',
      email: 'alice@example.com',
      phone: '9876543210',
      classGrade: 6,
      status: 'active',
      level: NamedRef(id: 'lvl_1', label: 'Level 1'),
      batch: NamedRef(id: 'batch_1', label: 'Batch 1'),
      masterTeachers: [
        TeacherDto(
          id: 't_1',
          fullName: 'Master John Doe',
          email: 'john@example.com',
          status: 'active',
          roles: ['master_teacher'],
        ),
      ],
    );

    final router = GoRouter(
      initialLocation: '/student/dashboard',
      routes: [
        GoRoute(
          path: '/student/dashboard',
          builder: (context, state) => const StudentDashboardPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => _FakeAuthController(roles: ['student'])),
          studentProfileProvider.overrideWith((ref) => Future.value(student)),
          studentAssessmentProvider.overrideWith(
            (ref) => Future.value(const StudentAssessmentPayload(available: false)),
          ),
          studentFeedbackProvider.overrideWith((ref) => Future.value([])),
          unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
          studentEligibilityProvider.overrideWith(
            (ref) => Future.value(
              const BookingEligibilityDto(
                introductionCompleted: false,
                canBookIntroduction: true,
                canBookMasterClass: false,
              ),
            ),
          ),
          studentBookingsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Master John Doe'), findsNothing);
    expect(find.text('YOUR TEACHERS'), findsNothing);
  });

  testWidgets('pickTeacher excludes already assigned teachers, removes employee code in search, and displays correct level data', (tester) async {
    final fakeRepo = _FakeAcademicRepo();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => pickTeacher(
                context: context,
                repo: fakeRepo,
                title: 'Assign Master Teacher to Level 1',
                role: 'master_teacher',
                excludeTeacherIds: {'t_1'},
              ),
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Verify search hint does not contain 'employee code'
    expect(find.text('Search name, employee code, or email'), findsNothing);
    expect(find.text('Search name, phone, or email'), findsOneWidget);

    // Verify Teacher 1 (already assigned) is excluded
    expect(find.text('Teacher 1'), findsNothing);

    // Verify Teacher 2 is shown
    expect(find.text('Teacher 2'), findsOneWidget);

    // Verify 'No batches assigned' is NOT shown, but 'No levels assigned' is shown
    expect(find.text('No batches assigned'), findsNothing);
    expect(find.text('No levels assigned'), findsOneWidget);
  });
}
