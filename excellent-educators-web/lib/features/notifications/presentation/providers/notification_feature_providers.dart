import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/notifications/data/dto/notification_dtos.dart';
import 'package:excellent_educators_web/features/notifications/data/notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(apiClientProvider));
});

final notificationsProvider = FutureProvider.autoDispose<List<UserNotificationDto>>((ref) {
  ref.watch(authControllerProvider.select((state) => state.user?.id));
  return ref.watch(notificationRepositoryProvider).notifications();
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) {
  ref.watch(authControllerProvider.select((state) => state.user?.id));
  return ref.watch(notificationRepositoryProvider).unreadCount();
});
