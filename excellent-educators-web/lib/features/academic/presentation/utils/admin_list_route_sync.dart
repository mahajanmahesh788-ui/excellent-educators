import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _attentionQueryKey = 'attention';

String studentsRouteWithAttention(String attentionKey, {String? levelId, String? status}) {
  return studentsRouteWithFilters(attentionKey: attentionKey, levelId: levelId, status: status);
}

String batchesRouteWithAttention(String attentionKey, {String? levelId, String? status}) {
  return batchesRouteWithFilters(attentionKey: attentionKey, levelId: levelId, status: status);
}

String studentsRouteWithFilters({
  String? attentionKey,
  String? status,
  String? levelId,
  String? batchId,
}) {
  final params = <String, String>{
    if (attentionKey != null && attentionKey.isNotEmpty) _attentionQueryKey: attentionKey,
    if (status != null && status.isNotEmpty) 'status': status,
    if (levelId != null && levelId.isNotEmpty) 'level_id': levelId,
    if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
  };
  if (params.isEmpty) {
    return RoutePaths.adminStudents;
  }
  return Uri(path: RoutePaths.adminStudents, queryParameters: params).toString();
}

String batchesRouteWithFilters({
  String? attentionKey,
  String? status,
  String? levelId,
}) {
  final params = <String, String>{
    if (attentionKey != null && attentionKey.isNotEmpty) _attentionQueryKey: attentionKey,
    if (status != null && status.isNotEmpty) 'status': status,
    if (levelId != null && levelId.isNotEmpty) 'level_id': levelId,
  };
  if (params.isEmpty) {
    return RoutePaths.adminBatches;
  }
  return Uri(path: RoutePaths.adminBatches, queryParameters: params).toString();
}

void scheduleStudentsFilterFromRoute(
  WidgetRef ref,
  GoRouterState state, {
  required bool Function() isMounted,
}) {
  final attention = state.uri.queryParameters[_attentionQueryKey];
  final status = state.uri.queryParameters['status'];
  final levelId = state.uri.queryParameters['level_id'];
  final batchId = state.uri.queryParameters['batch_id'];

  if ((attention == null || attention.isEmpty) &&
      (status == null || status.isEmpty) &&
      (levelId == null || levelId.isEmpty) &&
      (batchId == null || batchId.isEmpty)) {
    return;
  }

  final next = AdminListFilter(
    status: status ?? 'active',
    attentionKey: attention,
    levelId: levelId,
    batchId: batchId,
  );
  if (ref.read(adminStudentsFilterProvider) == next) {
    return;
  }

  Future.microtask(() {
    if (!isMounted()) {
      return;
    }
    if (ref.read(adminStudentsFilterProvider) == next) {
      return;
    }
    ref.read(adminStudentsFilterProvider.notifier).state = next;
  });
}

void scheduleBatchesFilterFromRoute(
  WidgetRef ref,
  GoRouterState state, {
  required bool Function() isMounted,
}) {
  final attention = state.uri.queryParameters[_attentionQueryKey];
  final status = state.uri.queryParameters['status'];
  final levelId = state.uri.queryParameters['level_id'];

  if ((attention == null || attention.isEmpty) &&
      (status == null || status.isEmpty) &&
      (levelId == null || levelId.isEmpty)) {
    return;
  }

  final next = AdminListFilter(
    status: status ?? 'active',
    attentionKey: attention,
    levelId: levelId,
  );
  if (ref.read(adminBatchesFilterProvider) == next) {
    return;
  }

  Future.microtask(() {
    if (!isMounted()) {
      return;
    }
    if (ref.read(adminBatchesFilterProvider) == next) {
      return;
    }
    ref.read(adminBatchesFilterProvider.notifier).state = next;
  });
}

void clearStudentsAttentionRoute(BuildContext context, WidgetRef ref, AdminListFilter filter) {
  ref.read(adminStudentsFilterProvider.notifier).state = filter.copyWith(clearAttention: true, page: 1);
  if (GoRouterState.of(context).uri.queryParameters.containsKey(_attentionQueryKey)) {
    context.go(RoutePaths.adminStudents);
  }
}

void clearBatchesAttentionRoute(BuildContext context, WidgetRef ref, AdminListFilter filter) {
  ref.read(adminBatchesFilterProvider.notifier).state = filter.copyWith(clearAttention: true, page: 1);
  if (GoRouterState.of(context).uri.queryParameters.containsKey(_attentionQueryKey)) {
    context.go(RoutePaths.adminBatches);
  }
}
