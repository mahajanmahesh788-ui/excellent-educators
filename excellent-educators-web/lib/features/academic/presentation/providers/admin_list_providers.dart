import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminListFilter {
  const AdminListFilter({
    this.search = '',
    this.levelId,
    this.status,
    this.attentionKey,
    this.page = 1,
  });

  final String search;
  final String? levelId;
  final String? status;
  final String? attentionKey;
  final int page;

  String? get attentionLabel => switch (attentionKey) {
        'without_batch' => 'Not in a batch',
        'without_master_teacher' => 'Without Master Teacher',
        'without_common_teacher' => 'Without Common Teacher',
        'assessment_pending' => 'Assessment pending',
        'without_rating_this_month' => 'No monthly rating',
        'full' => 'Full batches',
        _ => null,
      };

  AdminListFilter copyWith({
    String? search,
    String? levelId,
    String? status,
    String? attentionKey,
    int? page,
    bool clearLevel = false,
    bool clearStatus = false,
    bool clearAttention = false,
  }) {
    return AdminListFilter(
      search: search ?? this.search,
      levelId: clearLevel ? null : levelId ?? this.levelId,
      status: clearStatus ? null : status ?? this.status,
      attentionKey: clearAttention ? null : attentionKey ?? this.attentionKey,
      page: page ?? this.page,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdminListFilter &&
        other.search == search &&
        other.levelId == levelId &&
        other.status == status &&
        other.attentionKey == attentionKey &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(search, levelId, status, attentionKey, page);
}

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardDto>((ref) {
  return ref.watch(academicRepositoryProvider).adminDashboard();
});

final adminStudentsFilterProvider = StateProvider<AdminListFilter>((ref) => const AdminListFilter());

final adminTeachersFilterProvider = StateProvider<AdminListFilter>((ref) => const AdminListFilter());

final adminBatchesFilterProvider = StateProvider<AdminListFilter>((ref) => const AdminListFilter());

final adminStudentsProvider = FutureProvider.autoDispose.family<PagedResult, AdminListFilter>((ref, filter) {
  return ref.read(academicRepositoryProvider).adminStudents(
        search: filter.search,
        careerCompassLevelId: filter.levelId,
        status: filter.status,
        withoutBatch: filter.attentionKey == 'without_batch',
        withoutMasterTeacher: filter.attentionKey == 'without_master_teacher',
        assessmentPending: filter.attentionKey == 'assessment_pending',
        withoutRatingThisMonth: filter.attentionKey == 'without_rating_this_month',
        page: filter.page,
      );
});

final adminTeachersProvider = FutureProvider.autoDispose.family<PagedResult, AdminListFilter>((ref, filter) {
  return ref.read(academicRepositoryProvider).adminTeachers(
        search: filter.search,
        status: filter.status,
        page: filter.page,
      );
});

final adminBatchesProvider = FutureProvider.autoDispose.family<PagedResult, AdminListFilter>((ref, filter) {
  return ref.read(academicRepositoryProvider).adminBatches(
        search: filter.search,
        careerCompassLevelId: filter.levelId,
        status: filter.status,
        withoutCommonTeacher: filter.attentionKey == 'without_common_teacher',
        full: filter.attentionKey == 'full',
        page: filter.page,
      );
});

final adminStudentProvider = FutureProvider.autoDispose.family<StudentDto, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).adminStudent(id);
});

final adminTeacherProvider = FutureProvider.autoDispose.family<TeacherDto, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).adminTeacher(id);
});

final adminTeacherDashboardProvider = FutureProvider.autoDispose.family<MasterTeacherDashboardDto, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).adminTeacherDashboard(id);
});
