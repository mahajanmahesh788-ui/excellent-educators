import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/features/academic/data/academic_repository.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/master_teacher_students_filter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final academicRepositoryProvider = Provider<AcademicRepository>((ref) {
  return AcademicRepository(ref.watch(apiClientProvider));
});

final careerCompassLevelsProvider = FutureProvider<List<CareerCompassLevelDto>>((ref) {
  return ref.watch(academicRepositoryProvider).careerCompassLevels();
});

final adminBatchProvider = FutureProvider.autoDispose.family<BatchDto, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).adminBatch(id);
});

final adminBatchStudentsProvider =
    FutureProvider.autoDispose.family<List<StudentDto>, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).adminBatchStudents(id);
});

final teacherBatchesProvider = FutureProvider.autoDispose<List<BatchDto>>((ref) {
  return ref.watch(academicRepositoryProvider).teacherBatches();
});

final teacherBatchStudentsProvider =
    FutureProvider.autoDispose.family<List<StudentDto>, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).teacherBatchStudents(id);
});

final masterTeacherStudentsFilterProvider = StateProvider<MasterTeacherStudentsFilter>((ref) {
  return MasterTeacherStudentsFilter.currentMonth();
});

final masterTeacherStudentsProvider = FutureProvider.autoDispose<List<StudentDto>>((ref) {
  final filter = ref.watch(masterTeacherStudentsFilterProvider);
  return ref.watch(academicRepositoryProvider).masterTeacherStudents(filter);
});

final masterTeacherDashboardProvider = FutureProvider.autoDispose<MasterTeacherDashboardDto>((ref) {
  return ref.watch(academicRepositoryProvider).masterTeacherDashboard();
});

final studentProfileProvider = FutureProvider.autoDispose<StudentDto>((ref) {
  return ref.watch(academicRepositoryProvider).studentProfile();
});

final teacherProfileProvider = FutureProvider.autoDispose<TeacherDto>((ref) {
  return ref.watch(academicRepositoryProvider).teacherProfile();
});
