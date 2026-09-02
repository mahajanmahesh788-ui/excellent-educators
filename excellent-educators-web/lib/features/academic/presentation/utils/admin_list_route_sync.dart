import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _attentionQueryKey = 'attention';

String studentsRouteWithAttention(String attentionKey) {
  return '${RoutePaths.adminStudents}?$_attentionQueryKey=$attentionKey';
}

String batchesRouteWithAttention(String attentionKey) {
  return '${RoutePaths.adminBatches}?$_attentionQueryKey=$attentionKey';
}

void scheduleStudentsFilterFromRoute(
  WidgetRef ref,
  GoRouterState state, {
  required bool Function() isMounted,
}) {
  final attention = state.uri.queryParameters[_attentionQueryKey];
  if (attention == null || attention.isEmpty) {
    return;
  }

  final next = AdminListFilter(status: 'active', attentionKey: attention);
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
  if (attention == null || attention.isEmpty) {
    return;
  }

  final next = AdminListFilter(status: 'active', attentionKey: attention);
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
