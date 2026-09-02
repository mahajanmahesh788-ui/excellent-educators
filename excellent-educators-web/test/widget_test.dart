import 'package:excellent_educators_web/app/app.dart';
import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/core/storage/in_memory_token_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows login screen when signed out', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        ],
        child: const ExcellentEducatorsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Excellent Educators'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
