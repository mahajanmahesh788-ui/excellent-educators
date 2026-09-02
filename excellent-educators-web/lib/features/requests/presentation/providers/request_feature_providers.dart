import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/features/requests/data/dto/request_dtos.dart';
import 'package:excellent_educators_web/features/requests/data/request_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return RequestRepository(ref.watch(apiClientProvider));
});

final studentRequestsProvider = FutureProvider.autoDispose<List<AdminRequestDto>>((ref) {
  return ref.watch(requestRepositoryProvider).studentRequests();
});

final teacherRequestsProvider = FutureProvider.autoDispose<List<AdminRequestDto>>((ref) {
  return ref.watch(requestRepositoryProvider).teacherRequests();
});

class AdminRequestsFilter {
  const AdminRequestsFilter({
    this.page = 1,
    this.status,
    this.search = '',
  });

  final int page;
  final String? status;
  final String search;

  AdminRequestsFilter copyWith({
    int? page,
    String? status,
    String? search,
    bool clearStatus = false,
  }) {
    return AdminRequestsFilter(
      page: page ?? this.page,
      status: clearStatus ? null : (status ?? this.status),
      search: search ?? this.search,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdminRequestsFilter &&
        other.page == page &&
        other.status == status &&
        other.search == search;
  }

  @override
  int get hashCode => Object.hash(page, status, search);
}

final adminRequestsFilterProvider = StateProvider<AdminRequestsFilter>((ref) {
  return const AdminRequestsFilter(status: 'pending');
});

final adminRequestsProvider = FutureProvider.autoDispose.family<PagedResult, AdminRequestsFilter>((ref, filter) {
  return ref.read(requestRepositoryProvider).adminRequests(
        page: filter.page,
        status: filter.status,
        search: filter.search,
      );
});

final adminRequestDetailProvider = FutureProvider.autoDispose.family<AdminRequestDto, String>((ref, id) {
  return ref.watch(requestRepositoryProvider).adminRequest(id);
});
