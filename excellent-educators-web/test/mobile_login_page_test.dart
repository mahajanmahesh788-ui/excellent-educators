import 'package:excellent_educators_web/app/app.dart';
import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/core/storage/in_memory_token_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders mobile login layout without overflow on compact 375x812 screen', (tester) async {
    // Set screen size to mobile iPhone dimensions (375 x 812)
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        ],
        child: const ExcellentEducatorsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Mobile Brand & Headline
    expect(find.text('STUDENT GROWTH & MENTORSHIP'), findsWidgets);
    expect(find.text('Discover what makes you different.'), findsOneWidget);
    expect(find.text('Build skills that matter · Find your direction'), findsOneWidget);

    // Verify Mobile Login Form Card components
    expect(find.text('Welcome back 👋'), findsOneWidget);
    expect(find.text('Continue your learning journey.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);

    // Scroll down to verify below-the-fold sections on mobile
    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -600));
    await tester.pumpAndSettle();

    // Verify 4 Journey Stages rendered on mobile
    expect(find.text('How Your Journey Works'), findsOneWidget);
    expect(find.text('Discover Yourself'), findsWidgets);
    expect(find.text('Build Your Skills'), findsWidgets);

    // Scroll down further to verify footer
    await tester.drag(scrollable, const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(find.text('Building Careers. Creating Leaders.'), findsWidgets);
    expect(find.textContaining('All rights reserved'), findsOneWidget);

    // Ensure absolutely no layout overflow exceptions were thrown
    expect(tester.takeException(), isNull);
  });
}
