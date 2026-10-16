import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/learning/domain/learning_week_submit_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const q1 = LearningQuestionDto(
    id: 'q1',
    questionText: 'Q1',
    questionType: 'options',
    options: [
      LearningOptionDto(id: 'o1', optionText: 'A'),
      LearningOptionDto(id: 'o2', optionText: 'B'),
    ],
  );
  const q2 = LearningQuestionDto(
    id: 'q2',
    questionText: 'Q2',
    questionType: 'options',
    options: [
      LearningOptionDto(id: 'o3', optionText: 'C'),
      LearningOptionDto(id: 'o4', optionText: 'D'),
    ],
  );
  const questions = [q1, q2];

  test('new week open empty → Submit gate off until options filled', () {
    expect(
      learningWeekHasAnswerChanges(
        allowSubmit: true,
        questions: questions,
        latestAttempt: null,
        optionAnswers: const {},
        textAnswers: const {},
      ),
      isFalse,
    );
    expect(
      learningWeekHasAnswerChanges(
        allowSubmit: true,
        questions: questions,
        latestAttempt: null,
        optionAnswers: const {'q1': 'o1', 'q2': 'o4'},
        textAnswers: const {},
      ),
      isTrue,
    );
  });

  test('re-open prefilled same → gate off; change one → gate on', () {
    final saved = LearningAttemptDto(
      attemptNumber: 1,
      answers: const [
        {'question_id': 'q1', 'option_id': 'o1'},
        {'question_id': 'q2', 'option_id': 'o4'},
      ],
    );
    expect(
      learningWeekHasAnswerChanges(
        allowSubmit: true,
        questions: questions,
        latestAttempt: saved,
        optionAnswers: const {'q1': 'o1', 'q2': 'o4'},
        textAnswers: const {},
      ),
      isFalse,
    );
    expect(
      learningWeekHasAnswerChanges(
        allowSubmit: true,
        questions: questions,
        latestAttempt: saved,
        optionAnswers: const {'q1': 'o2', 'q2': 'o4'},
        textAnswers: const {},
      ),
      isTrue,
    );
  });
}
