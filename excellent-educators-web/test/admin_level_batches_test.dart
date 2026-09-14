import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/academic/data/academic_repository.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/pages/admin_batches_page.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';
import 'package:excellent_educators_web/features/auth/domain/repositories/auth_repository.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
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

class _FakeAuthController extends StateNotifier<AuthState> implements AuthController {
  _FakeAuthController()
      : super(
          const AuthState(
            isReady: true,
            user: AppUser(
              id: 'admin_1',
              name: 'Admin User',
              email: 'admin@test.com',
              status: 'active',
              roles: ['super_admin'],
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAcademicRepository extends Fake implements AcademicRepository {
  AcademicLevelDto _level = const AcademicLevelDto(
    id: 'level_1',
    name: 'Level 1',
    academicYear: 2026,
    status: 'active',
    studentsCount: 1,
    batches: [
      BatchDto(
        id: 'batch_1',
        levelId: 'level_1',
        name: 'Batch 1',
        academicYear: 2026,
        year: 2026,
        month: 4,
        status: 'active',
        activeStudentCount: 49,
        maxActiveStudents: 50,
      ),
    ],
  );

  @override
  Future<AcademicLevelDto> adminLevel(String id) async => _level;

  @override
  Future<List<StudentDto>> adminBatchStudents(String batchId) async => [
        const StudentDto(
          id: 'student_1',
          studentCode: '26-0001',
          fullName: 'Aarav Patel',
          email: 'aarav@test.com',
          classGrade: 6,
          status: 'active',
          phone: '9876543210',
        ),
      ];

  @override
  Future<BatchDto> toggleBatchStatus(String batchId) async {
    final current = _level.batches.first;
    final newStatus = current.status == 'active' ? 'inactive' : 'active';
    _level = AcademicLevelDto(
      id: _level.id,
      name: _level.name,
      academicYear: _level.academicYear,
      status: _level.status,
      studentsCount: _level.studentsCount,
      batches: [
        BatchDto(
          id: current.id,
          levelId: current.levelId,
          name: current.name,
          academicYear: current.academicYear,
          year: current.year,
          month: current.month,
          status: newStatus,
          activeStudentCount: current.activeStudentCount,
          maxActiveStudents: current.maxActiveStudents,
        ),
      ],
    );
    return _level.batches.first;
  }
}

void main() {
  testWidgets('Level Detail page shows Level, child Batch with 50-student limit, and toggle button', (tester) async {
    final fakeRepo = _FakeAcademicRepository();

    final router = GoRouter(
      initialLocation: RoutePaths.adminBatch('level_1'),
      routes: [
        GoRoute(
          path: RoutePaths.adminBatch(':batchId'),
          builder: (context, state) => AdminBatchDetailPage(
            batchId: state.pathParameters['batchId']!,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          authControllerProvider.overrideWith((ref) => _FakeAuthController()),
          unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
          academicRepositoryProvider.overrideWithValue(fakeRepo),
          adminLevelProvider('level_1').overrideWith((ref) => Future.value(fakeRepo._level)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Level details
    expect(find.text('Level Details'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Academic Year 2026 · Unlimited student capacity'), findsOneWidget);
    expect(find.text('Add Batch'), findsOneWidget);

    // Verify child Batch 1 inside Level
    expect(find.text('Batch 1'), findsOneWidget);
    expect(find.text('2026 · Apr'), findsOneWidget);
    expect(find.text('49/50 students'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    // Verify Deactivate button is present and clickable
    final toggleBtn = find.text('Deactivate');
    expect(toggleBtn, findsOneWidget);

    await tester.tap(toggleBtn);
    await tester.pumpAndSettle();

    // After toggling, batch is Inactive and button says Activate
    expect(find.text('Inactive'), findsOneWidget);
    expect(find.text('Activate'), findsOneWidget);
  });
}
