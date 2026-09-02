import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/assessments/data/assessment_repository.dart';
import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:excellent_educators_web/features/feedback/data/feedback_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  return AssessmentRepository(ref.watch(apiClientProvider));
});

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository(ref.watch(apiClientProvider));
});

final adminAssessmentsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(assessmentRepositoryProvider).adminAssessments();
});

final adminAssessmentProvider = FutureProvider.autoDispose.family<AptitudeAssessmentDto, String>((ref, id) {
  return ref.watch(assessmentRepositoryProvider).adminAssessment(id);
});

final adminAssessmentAttemptsProvider =
    FutureProvider.autoDispose.family<List<AssessmentResultDto>, String>((ref, id) {
  return ref.watch(assessmentRepositoryProvider).adminAttempts(id);
});

final adminStudentResultsProvider = FutureProvider.autoDispose.family<List<AssessmentResultDto>, String>((ref, id) {
  return ref.watch(assessmentRepositoryProvider).adminStudentResults(id);
});

final studentAssessmentProvider = FutureProvider.autoDispose<StudentAssessmentPayload>((ref) {
  return ref.watch(assessmentRepositoryProvider).studentAssessment();
});

final studentFeedbackProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(feedbackRepositoryProvider).ownFeedback();
});

final studentFeedbackSummaryProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(feedbackRepositoryProvider).ownFeedbackSummary();
});

final adminStudentFeedbackProvider = FutureProvider.autoDispose.family((ref, String studentId) {
  return ref.watch(feedbackRepositoryProvider).adminStudentFeedback(studentId);
});

final adminStudentFeedbackSummaryProvider = FutureProvider.autoDispose.family((ref, String studentId) {
  return ref.watch(feedbackRepositoryProvider).adminStudentFeedbackSummary(studentId);
});

final teacherStudentFeedbackProvider = FutureProvider.autoDispose.family((ref, String studentId) {
  return ref.watch(feedbackRepositoryProvider).teacherStudentFeedback(studentId);
});

final teacherStudentFeedbackSummaryProvider = FutureProvider.autoDispose.family((ref, String studentId) {
  return ref.watch(feedbackRepositoryProvider).teacherStudentFeedbackSummary(studentId);
});

final teacherStudentProvider = FutureProvider.autoDispose.family((ref, String studentId) {
  return ref.watch(academicRepositoryProvider).teacherStudent(studentId);
});

final adminFeedbackCatalogProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(feedbackRepositoryProvider).adminCatalog();
});

final masterTeacherFeedbackCatalogProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(feedbackRepositoryProvider).catalog();
});

final masterTeacherStudentFeedbackProvider = FutureProvider.autoDispose.family((ref, String studentId) {
  return ref.watch(feedbackRepositoryProvider).studentFeedback(studentId);
});

final masterTeacherStudentFeedbackSummaryProvider = FutureProvider.autoDispose.family((ref, String studentId) {
  return ref.watch(feedbackRepositoryProvider).masterTeacherStudentFeedbackSummary(studentId);
});

final masterTeacherStudentProvider = FutureProvider.autoDispose.family((ref, String studentId) {
  return ref.watch(academicRepositoryProvider).masterTeacherStudent(studentId);
});

final teacherStudentResultsProvider = FutureProvider.autoDispose.family((ref, String studentId) {
  return ref.watch(assessmentRepositoryProvider).teacherStudentResults(studentId);
});

final masterTeacherStudentResultsProvider = FutureProvider.autoDispose.family((ref, String studentId) {
  return ref.watch(assessmentRepositoryProvider).masterTeacherStudentResults(studentId);
});
