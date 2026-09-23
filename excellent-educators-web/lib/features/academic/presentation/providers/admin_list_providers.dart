import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AdminListFilter {
  const AdminListFilter({
    this.search = '',
    this.levelId,
    this.batchId,
    this.status,
    this.attentionKey,
    this.page = 1,
  });

  final String search;
  final String? levelId;
  final String? batchId;
  final String? status;
  final String? attentionKey;
  final int page;

  String? get attentionLabel => switch (attentionKey) {
        'without_batch' => AppStrings.notInABatch,
        'without_master_teacher' => AppStrings.withoutMasterTeacher,
        'assessment_pending' => AppStrings.assessmentPending,
        'without_rating_this_month' => AppStrings.noMonthlyRating,
        'full' => AppStrings.fullBatches,
        'top_rated' => AppStrings.topRated,
        'longest' => AppStrings.longestWithUs,
        'promoted' => AppStrings.levelledUp,
        _ => null,
      };

  AdminListFilter copyWith({
    String? search,
    String? levelId,
    String? batchId,
    String? status,
    String? attentionKey,
    int? page,
    bool clearLevel = false,
    bool clearBatch = false,
    bool clearStatus = false,
    bool clearAttention = false,
  }) {
    return AdminListFilter(
      search: search ?? this.search,
      levelId: clearLevel ? null : levelId ?? this.levelId,
      batchId: clearBatch ? null : batchId ?? this.batchId,
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
        other.batchId == batchId &&
        other.status == status &&
        other.attentionKey == attentionKey &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(search, levelId, batchId, status, attentionKey, page);
}

enum AdminDashboardCategory {
  all,
  attention,
  academic,
  progress,
  classes,
  conflicts,
}

class AdminDashboardFilter {
  const AdminDashboardFilter({
    this.year,
    this.month,
    this.category = AdminDashboardCategory.all,
  });

  final int? year;
  final int? month;
  final AdminDashboardCategory category;

  bool get hasActiveFilter =>
      year != null ||
      month != null ||
      category != AdminDashboardCategory.all;

  AdminDashboardFilter copyWith({
    int? year,
    int? month,
    AdminDashboardCategory? category,
    bool clearDate = false,
  }) {
    return AdminDashboardFilter(
      year: clearDate ? null : year ?? this.year,
      month: clearDate ? null : month ?? this.month,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdminDashboardFilter &&
        other.year == year &&
        other.month == month &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(year, month, category);
}

final adminDashboardFilterProvider = StateProvider<AdminDashboardFilter>((ref) => const AdminDashboardFilter());

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardDto>((ref) {
  final filter = ref.watch(adminDashboardFilterProvider);
  return ref.watch(academicRepositoryProvider).adminDashboard(
        year: filter.year,
        month: filter.month,
      );
});

final adminStudentsFilterProvider = StateProvider<AdminListFilter>((ref) => const AdminListFilter());

final adminTeachersFilterProvider = StateProvider<AdminListFilter>((ref) => const AdminListFilter());

final adminBatchesFilterProvider = StateProvider<AdminListFilter>((ref) => const AdminListFilter());

final adminStudentsProvider = FutureProvider.autoDispose.family<PagedResult, AdminListFilter>((ref, filter) {
  return ref.read(academicRepositoryProvider).adminStudents(
        search: filter.search,
        status: filter.status,
        levelId: filter.levelId,
        batchId: filter.batchId,
        withoutBatch: filter.attentionKey == 'without_batch',
        withoutMasterTeacher: filter.attentionKey == 'without_master_teacher',
        assessmentPending: filter.attentionKey == 'assessment_pending',
        withoutRatingThisMonth: filter.attentionKey == 'without_rating_this_month',
        spotlight: filter.attentionKey == 'top_rated' ||
                filter.attentionKey == 'longest' ||
                filter.attentionKey == 'promoted'
            ? filter.attentionKey
            : null,
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
        status: filter.status,
        full: filter.attentionKey == 'full',
        page: filter.page,
      );
});

final adminStudentProvider = FutureProvider.autoDispose.family<StudentDto, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).adminStudent(id);
});

final adminStudentHistoryProvider = FutureProvider.autoDispose.family<List<StudentActivityDto>, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).studentHistory(id);
});

final adminTeacherProvider = FutureProvider.autoDispose.family<TeacherDto, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).adminTeacher(id);
});

final adminTeacherDashboardProvider = FutureProvider.autoDispose.family<MasterTeacherDashboardDto, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).adminTeacherDashboard(id);
});

final adminTeacherHistoryProvider = FutureProvider.autoDispose.family<TeacherHistoryDto, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).adminTeacherHistory(id);
});

final adminTeacherPromotedProvider = FutureProvider.autoDispose.family<List<StudentDto>, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).adminTeacherPromotedStudents(id);
});

final adminSubAdminsFilterProvider = StateProvider<AdminListFilter>((ref) => const AdminListFilter());

final adminSubAdminsProvider = FutureProvider.autoDispose.family<PagedResult, AdminListFilter>((ref, filter) {
  return ref.read(academicRepositoryProvider).adminSubAdmins(
        search: filter.search,
        status: filter.status,
        page: filter.page,
      );
});

final adminSubAdminProvider = FutureProvider.autoDispose.family<SubAdminDto, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).adminSubAdmin(id);
});

final subAdminPermissionCatalogProvider = FutureProvider.autoDispose<List<PermissionCatalogGroupDto>>((ref) {
  return ref.watch(academicRepositoryProvider).subAdminPermissionCatalog();
});

final adminSubAdminHistoryProvider = FutureProvider.autoDispose.family<List<StudentActivityDto>, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).subAdminHistory(id);
});
