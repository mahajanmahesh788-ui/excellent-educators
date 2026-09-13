import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/academic/presentation/pages/admin_teachers_page.dart';
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
  testWidgets('Add teacher page has Address field, password toggle eye icon, and no Employee Code or Common Teacher', (tester) async {
    final router = GoRouter(
      initialLocation: RoutePaths.adminTeacherNew,
      routes: [
        GoRoute(
          path: RoutePaths.adminTeacherNew,
          builder: (context, state) => const AdminCreateTeacherPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify fields present
    expect(find.widgetWithText(TextFormField, 'Full name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Temporary password'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Address'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Phone number'), findsOneWidget);

    // Verify Employee Code is NOT present
    expect(find.text('Employee code'), findsNothing);
    expect(find.text('Employee Code'), findsNothing);

    // Verify Common Teacher role selection is NOT present
    expect(find.text('Common Teacher'), findsNothing);

    // Verify password toggle eye icon
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });
}
