import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
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

class _FakeAuthRepository extends Fake implements AuthRepository {
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
  @override
  Future<List<AcademicLevelDto>> adminLevels() async {
    return const [
      AcademicLevelDto(
        id: 'level_1',
        name: 'Level 1',
        academicYear: 2026,
        status: 'active',
        batchesCount: 1,
        studentsCount: 0,
      ),
    ];
  }

  @override
  List<BatchDto> parseBatches(PagedResult page) => [
        const BatchDto(
          id: 'batch_1',
          name: 'Level 1',
          academicYear: 2026,
          status: 'active',
          activeStudentCount: 0,
          maxActiveStudents: 50,
        ),
      ];

  @override
  Future<PagedResult> adminBatches({
    String? search,
    String? status,
    bool full = false,
    int page = 1,
    int perPage = 25,
  }) async {
    return const PagedResult(
      items: [],
      meta: {'page': 1, 'per_page': 25, 'total': 1},
    );
  }
}

void main() {
  testWidgets('Levels page displays Levels title, Add level, and no Career Compass filter', (tester) async {
    final router = GoRouter(
      initialLocation: RoutePaths.adminBatches,
      routes: [
        GoRoute(
          path: RoutePaths.adminBatches,
          builder: (context, state) => const AdminBatchesPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          authControllerProvider.overrideWith((ref) => _FakeAuthController()),
          academicRepositoryProvider.overrideWithValue(_FakeAcademicRepository()),
          unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Levels'), findsOneWidget);
    expect(find.text('Add level'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);

    // Verify Career Compass filter is NOT present in toolbar
    expect(find.text('Career Compass'), findsNothing);
  });

  testWidgets('Add level page only has Level name and Academic year, and no Career Compass dropdown', (tester) async {
    final router = GoRouter(
      initialLocation: RoutePaths.adminBatchNew,
      routes: [
        GoRoute(
          path: RoutePaths.adminBatchNew,
          builder: (context, state) => const AdminCreateBatchPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          authControllerProvider.overrideWith((ref) => _FakeAuthController()),
          unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Add level'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Level name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Academic year'), findsOneWidget);
    expect(find.text('Create level'), findsOneWidget);

    // Verify Career Compass dropdown is NOT present
    expect(find.text('Career Compass'), findsNothing);
  });
}
