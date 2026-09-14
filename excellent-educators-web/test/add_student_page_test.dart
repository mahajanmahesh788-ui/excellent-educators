import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/academic/presentation/pages/admin_students_page.dart';
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
  testWidgets('Add student page has Class dropdown and Address field, and no Career Compass section', (tester) async {
    final router = GoRouter(
      initialLocation: RoutePaths.adminStudentNew,
      routes: [
        GoRoute(
          path: RoutePaths.adminStudentNew,
          builder: (context, state) => const AdminCreateStudentPage(),
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

    // Verify Career Compass level selection section is removed
    expect(find.text('Class range is already defined by the selected level.'), findsNothing);
    expect(find.text('Career Compass 1'), findsNothing);

    // Verify Class dropdown exists
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);

    // Verify Address field exists
    expect(find.widgetWithText(TextFormField, 'Address'), findsOneWidget);

    // Verify opening Class dropdown shows Class 5 and others
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();

    expect(find.text('Class 5 (5th Class)'), findsWidgets);
    expect(find.text('Class 6 (6th Class)'), findsWidgets);
    expect(find.text('Class 12 (12th Class)'), findsWidgets);
  });
}
