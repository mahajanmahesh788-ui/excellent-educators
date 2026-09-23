import 'package:excellent_educators_web/features/feedback/data/dto/feedback_dtos.dart';
import 'package:excellent_educators_web/features/feedback/domain/feedback_form_value.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/feedback_read_only_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feedback form validation requires all dimensions and a positive point', () {
    expect(
      FeedbackFormValue.validate(
        const FeedbackFormValue(ratings: {'d1': 4}, positivePoints: 'Nice'),
        expectedCount: 10,
      ),
      isNotNull,
    );
    expect(
      FeedbackFormValue.validate(
        FeedbackFormValue(
          ratings: {for (var i = 0; i < 10; i++) 'd$i': 8},
          positivePoints: '',
        ),
        expectedCount: 10,
      ),
      isNotNull,
    );
    expect(
      FeedbackFormValue.validate(
        FeedbackFormValue(
          ratings: {for (var i = 0; i < 10; i++) 'd$i': 8},
          positivePoints: 'Strong curiosity',
        ),
        expectedCount: 10,
      ),
      isNull,
    );
  });

  testWidgets('shows edit only while feedback is still editable', (tester) async {
    const editable = MonthlyFeedbackDto(
      id: 'f1',
      year: 2026,
      month: 8,
      sessionDate: '2026-08-15',
      editable: true,
      deletable: true,
      masterTeacherName: 'Anita',
      positivePoints: 'Collaborates well',
      items: [
        FeedbackItemDto(
          id: 'i1',
          targetType: 'dimension',
          targetId: 'd1',
          targetName: 'Teamwork',
          rating: 4,
        ),
      ],
    );
    const locked = MonthlyFeedbackDto(
      id: 'f2',
      year: 2026,
      month: 7,
      sessionDate: '2026-07-20',
      editable: false,
      deletable: false,
      masterTeacherName: 'Anita',
      items: [
        FeedbackItemDto(
          id: 'i2',
          targetType: 'dimension',
          targetId: 'd1',
          targetName: 'Leadership',
          rating: 3,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              FeedbackReadOnlyCard(feedback: editable, onEdit: () {}),
              FeedbackReadOnlyCard(feedback: locked, onEdit: () {}),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Edit'), findsOneWidget);
  });
}
