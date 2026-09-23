import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/maps_api_failures.dart';
import 'package:excellent_educators_web/features/notifications/data/dto/notification_dtos.dart';

class NotificationRepository with MapsApiFailures {
  NotificationRepository(this._client);

  final ApiClient _client;

  Future<List<UserNotificationDto>> notifications() {
    return runApiSimple(() async {
      final items = await _client.getList(ApiEndpoints.notifications);
      return items
          .whereType<Map>()
          .map((item) => UserNotificationDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<int> unreadCount() {
    return runApiSimple(() async {
      final json = await _client.get(ApiEndpoints.notificationsUnreadCount);
      return (json?['unread_count'] as num?)?.toInt() ?? 0;
    });
  }

  Future<UserNotificationDto> markRead(String id) {
    return runApiSimple(() async {
      final json = await _client.patch(ApiEndpoints.notificationRead(id));
      return UserNotificationDto.fromJson(json!);
    });
  }

  Future<void> markAllRead() {
    return runApiSimple(() async {
      await _client.post(ApiEndpoints.notificationsReadAll);
    });
  }
}
