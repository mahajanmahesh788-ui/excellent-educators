import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/learning/data/learning_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository(ref.watch(apiClientProvider));
});

final studentLearningDashboardProvider =
    FutureProvider.autoDispose<LearningDashboardDto>((ref) {
      return ref.watch(learningRepositoryProvider).studentDashboard();
    });

final studentLearningJournalProvider =
    FutureProvider.autoDispose<LearningJournalDto>((ref) {
      return ref.watch(learningRepositoryProvider).studentJournal();
    });

final studentLearningWeekProvider = FutureProvider.autoDispose
    .family<LearningWeekDto, ({String journeyId, int week})>((ref, key) {
      return ref
          .watch(learningRepositoryProvider)
          .studentWeek(key.journeyId, key.week);
    });

final adminLearningJournalProvider = FutureProvider.autoDispose
    .family<LearningJournalDto, String>((ref, studentId) {
      return ref.watch(learningRepositoryProvider).adminJournal(studentId);
    });

final adminLearningWeekProvider = FutureProvider.autoDispose
    .family<LearningWeekDto, ({String studentId, String journeyId, int week})>((
      ref,
      key,
    ) {
      return ref
          .watch(learningRepositoryProvider)
          .adminWeek(key.studentId, key.journeyId, key.week);
    });

final teacherLearningJournalProvider = FutureProvider.autoDispose
    .family<LearningJournalDto, String>((ref, studentId) {
      return ref.watch(learningRepositoryProvider).teacherJournal(studentId);
    });

final masterTeacherLearningJournalProvider = FutureProvider.autoDispose
    .family<LearningJournalDto, String>((ref, studentId) {
      return ref
          .watch(learningRepositoryProvider)
          .masterTeacherJournal(studentId);
    });

final teacherLearningWeekProvider = FutureProvider.autoDispose
    .family<LearningWeekDto, ({String studentId, String journeyId, int week})>((
      ref,
      key,
    ) {
      return ref
          .watch(learningRepositoryProvider)
          .teacherWeek(key.studentId, key.journeyId, key.week);
    });

final masterTeacherLearningWeekProvider = FutureProvider.autoDispose
    .family<LearningWeekDto, ({String studentId, String journeyId, int week})>((
      ref,
      key,
    ) {
      return ref
          .watch(learningRepositoryProvider)
          .masterTeacherWeek(key.studentId, key.journeyId, key.week);
    });

final adminWeeklyLearningsProvider = FutureProvider.autoDispose
    .family<List<WeeklyLearningContentDto>, String>((ref, levelId) {
      return ref
          .watch(learningRepositoryProvider)
          .adminWeeklyLearnings(levelId);
    });
