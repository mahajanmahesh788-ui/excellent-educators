import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/assessment_result_view.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/student_assessment_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AptitudeAssessmentDto _assessment() {
  return const AptitudeAssessmentDto(
    id: 'a1',
    title: 'CC1 Compass',
    status: 'active',
    description: 'Answer every question.',
    questions: [
      AptitudeQuestionDto(
        id: 'q1',
        questionText: 'Which activity do you enjoy most?',
        displayOrder: 1,
        options: [
          AptitudeOptionDto(id: 'o1', optionText: 'Solving problems', displayOrder: 1),
          AptitudeOptionDto(id: 'o2', optionText: 'Working with others', displayOrder: 2),
        ],
      ),
      AptitudeQuestionDto(
        id: 'q2',
        questionText: 'How do you like to work?',
        displayOrder: 2,
        options: [
          AptitudeOptionDto(id: 'o3', optionText: 'Leading', displayOrder: 1),
          AptitudeOptionDto(id: 'o4', optionText: 'Listening', displayOrder: 2),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('renders assessment questions without dimension codes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentAssessmentForm(
            assessment: _assessment(),
            selections: const {},
            onSelect: (_, _) {},
          ),
        ),
      ),
    );

    expect(find.textContaining('Which activity do you enjoy most?'), findsOneWidget);
    expect(find.text('Solving problems'), findsOneWidget);
    expect(find.text('Working with others'), findsOneWidget);
    expect(find.text('TW'), findsNothing);
    expect(find.text('CR'), findsNothing);
    expect(find.textContaining('dimension'), findsNothing);
  });

  test('requires every question before submit', () {
    final assessment = _assessment();
    expect(StudentAssessmentForm.validate(assessment, {}), isNotNull);
    expect(StudentAssessmentForm.validate(assessment, {'q1': 'o1'}), isNotNull);
    expect(StudentAssessmentForm.validate(assessment, {'q1': 'o1', 'q2': 'o3'}), isNull);
  });

  testWidgets('submit stays disabled in UI until questions are answered', (tester) async {
    var selections = <String, String>{};
    String? error;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    StudentAssessmentForm(
                      assessment: _assessment(),
                      selections: selections,
                      errorText: error,
                      onSelect: (questionId, optionId) {
                        setState(() => selections[questionId] = optionId);
                      },
                    ),
                    FilledButton(
                      onPressed: () {
                        setState(() => error = StudentAssessmentForm.validate(_assessment(), selections));
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(find.text('Please answer every question before submitting.'), findsOneWidget);

    await tester.tap(find.text('Solving problems'));
    await tester.tap(find.text('Leading'));
    await tester.pump();
    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(find.text('Please answer every question before submitting.'), findsNothing);
  });

  testWidgets('renders all ten dimension scores', (tester) async {
    const result = AssessmentResultDto(
      id: 'r1',
      assessmentTitle: 'CC1 Compass',
      dimensions: [
        DimensionScoreDto(name: 'Personality', score: 8),
        DimensionScoreDto(name: 'Interests', score: 6),
        DimensionScoreDto(name: 'Confidence', score: 9),
        DimensionScoreDto(name: 'Leadership', score: 7),
        DimensionScoreDto(name: 'Communication', score: 10),
        DimensionScoreDto(name: 'Decision-making', score: 5),
        DimensionScoreDto(name: 'Creativity', score: 8),
        DimensionScoreDto(name: 'Curiosity', score: 6),
        DimensionScoreDto(name: 'Teamwork', score: 9),
        DimensionScoreDto(name: 'Future Aspirations', score: 7),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: AssessmentResultView(result: result, showCharts: false))),
      ),
    );

    expect(find.text('Personality'), findsOneWidget);
    expect(find.text('Future Aspirations'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('TW'), findsNothing);
  });
}
