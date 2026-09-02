import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/errors/failure.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/api_exception.dart';
import 'package:excellent_educators_web/features/notifications/data/dto/notification_dtos.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final ApiClient _client;

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      throw Failure(error.message, code: error.code);
    }
  }

  Future<List<UserNotificationDto>> notifications() {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.notifications);
      return items
          .whereType<Map>()
          .map((item) => UserNotificationDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<int> unreadCount() {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.notificationsUnreadCount);
      return (json?['unread_count'] as num?)?.toInt() ?? 0;
    });
  }

  Future<UserNotificationDto> markRead(String id) {
    return _run(() async {
      final json = await _client.patch(ApiEndpoints.notificationRead(id));
      return UserNotificationDto.fromJson(json!);
    });
  }

  Future<void> markAllRead() {
    return _run(() async {
      await _client.post(ApiEndpoints.notificationsReadAll);
    });
  }
}
