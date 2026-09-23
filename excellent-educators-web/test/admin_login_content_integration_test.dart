import 'package:excellent_educators_web/app/app.dart';
import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/core/storage/in_memory_token_store.dart';
import 'package:excellent_educators_web/features/auth/data/dto/login_page_dtos.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/login_page_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const customAdminContent = LoginPageContentDto(
    tagline: 'Custom Admin Tagline',
    headline: 'Custom Admin Headline',
    description: 'Custom Admin Description about mentorship excellence.',
    missionQuote: 'Custom Admin Mission Quote for future leaders.',
    formTitle: 'Admin Custom Welcome',
    formSubtitle: 'Admin Custom Subtitle for login access.',
    whyHeading: 'Why Choose Our Method',
    pillars: [
      LoginPagePillarDto(
        icon: 'lightbulb_outline',
        title: 'Custom Discovery Pillar',
        body: 'Custom description for discovery stage.',
      ),
      LoginPagePillarDto(
        icon: 'rocket_launch_outlined',
        title: 'Custom Launch Pillar',
        body: 'Custom description for career launch.',
      ),
    ],
    trustSignals: [
      LoginPageTrustSignalDto(
        icon: 'verified_outlined',
        value: '99.8%',
        label: 'Satisfaction Rate',
      ),
    ],
    stories: [
      LoginPageStoryDto(
        title: 'Admin Success Story One',
        body: 'Story of a student who accelerated their growth.',
        imageUrl: 'https://example.com/test-story.jpg',
        imageOnLeft: true,
      ),
    ],
    testimonialsHeading: 'What Parents Say',
    testimonials: [
      LoginPageTestimonialDto(
        quote: 'This platform transformed how our child learns.',
        attribution: 'Priya Sharma',
        role: 'Parent of 10th Grader',
      ),
    ],
    forgotFormTitle: 'Reset Password',
    forgotFormSubtitle: 'Enter email to reset',
  );

  testWidgets('public login page renders 100% of admin-customized content', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          loginPageContentProvider.overrideWith((ref) => Future.value(customAdminContent)),
        ],
        child: const ExcellentEducatorsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Admin custom tagline in brand badge
    expect(find.text('CUSTOM ADMIN TAGLINE'), findsWidgets);

    // Verify Admin custom headline & description
    expect(find.text('Custom Admin Headline'), findsOneWidget);
    expect(find.text('Custom Admin Description about mentorship excellence.'), findsOneWidget);

    // Verify Admin custom mission quote
    expect(find.text('Custom Admin Mission Quote for future leaders.'), findsOneWidget);

    // Verify Admin custom form title & subtitle
    expect(find.text('Admin Custom Welcome'), findsOneWidget);
    expect(find.text('Admin Custom Subtitle for login access.'), findsOneWidget);

    // Verify Admin custom pillars in hero pills
    expect(find.text('Custom Discovery Pillar'), findsWidgets);
    expect(find.text('Custom Launch Pillar'), findsWidgets);

    // Scroll to below-the-fold sections
    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -600));
    await tester.pumpAndSettle();

    // Verify Admin custom whyHeading
    expect(find.text('Why Choose Our Method'), findsOneWidget);
    expect(find.text('Custom description for discovery stage.'), findsOneWidget);
    expect(find.text('Custom description for career launch.'), findsOneWidget);

    // Verify Admin custom stories section
    expect(find.text('Admin Success Story One'), findsOneWidget);
    expect(find.text('Story of a student who accelerated their growth.'), findsOneWidget);

    // Scroll further down to Trust Signals & Testimonials
    await tester.drag(scrollable, const Offset(0, -700));
    await tester.pumpAndSettle();

    // Verify Admin custom trust signals
    expect(find.text('99.8%'), findsOneWidget);
    expect(find.text('Satisfaction Rate'), findsOneWidget);

    // Verify Admin custom testimonials
    expect(find.text('What Parents Say'), findsOneWidget);
    expect(find.text('"This platform transformed how our child learns."'), findsOneWidget);
    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('Parent of 10th Grader'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
