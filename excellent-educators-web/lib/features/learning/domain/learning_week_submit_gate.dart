import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';

/// True when on-screen answers differ from the last saved attempt.
///
/// No prior attempt ⇒ compare against empty (Submit stays off until options
/// are filled; the page also requires every question answered).
bool learningWeekHasAnswerChanges({
  required bool allowSubmit,
  required List<LearningQuestionDto> questions,
  required LearningAttemptDto? latestAttempt,
  required Map<String, String> optionAnswers,
  required Map<String, String> textAnswers,
}) {
  if (!allowSubmit) {
    return false;
  }

  for (final question in questions) {
    if (question.isText) {
      final current = (textAnswers[question.id] ?? '').trim();
      final saved = latestAttempt?.textAnswerFor(question.id)?.trim() ?? '';
      if (current != saved) {
        return true;
      }
    } else {
      final current = optionAnswers[question.id];
      final saved = latestAttempt?.optionIdFor(question.id);
      if (current != saved) {
        return true;
      }
    }
  }
  return false;
}
