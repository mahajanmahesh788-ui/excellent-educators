import 'dart:async';

import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/notifications/data/dto/notification_dtos.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/browser_os_notification.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_feature_providers.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_sound.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationToastItem {
  NotificationToastItem({
    required this.notification,
    required this.queuedAt,
  });

  final UserNotificationDto notification;
  final DateTime queuedAt;

  String get id => notification.id;
}

class NotificationToastController extends ChangeNotifier {
  NotificationToastController(this._ref);

  final Ref _ref;
  final List<NotificationToastItem> _toasts = [];
  final Set<String> _knownIds = {};
  final Map<String, Timer> _autoDismiss = {};

  Timer? _pollTimer;
  String? _activeUserId;
  var _bootstrapped = false;
  var _polling = false;
  int? _lastUnreadCount;

  List<NotificationToastItem> get toasts => List.unmodifiable(_toasts);

  void syncAuth() {
    final userId = _ref.read(authControllerProvider).user?.id;
    if (userId == null) {
      stop();
      return;
    }
    if (_activeUserId != userId) {
      stop();
      _activeUserId = userId;
      _bootstrapped = false;
      _knownIds.clear();
      _lastUnreadCount = null;
      start();
      return;
    }
    if (_pollTimer == null) {
      start();
    }
  }

  void start() {
    _activeUserId ??= _ref.read(authControllerProvider).user?.id;
    if (_activeUserId == null) {
      return;
    }
    _pollTimer?.cancel();
    unawaited(_poll());
    // Count + toast poll — keep snappy so slide cards appear soon after create.
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_poll());
    });
  }

  /// Immediate poll (e.g. mobile tab / PWA becomes visible again).
  void pollNow() {
    if (_activeUserId == null) {
      syncAuth();
      return;
    }
    unawaited(_poll());
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    for (final timer in _autoDismiss.values) {
      timer.cancel();
    }
    _autoDismiss.clear();
    _toasts.clear();
    _knownIds.clear();
    _bootstrapped = false;
    _activeUserId = null;
    _lastUnreadCount = null;
    notifyListeners();
  }

  void dismiss(String id) {
    _autoDismiss.remove(id)?.cancel();
    _toasts.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void dismissAll() {
    for (final timer in _autoDismiss.values) {
      timer.cancel();
    }
    _autoDismiss.clear();
    _toasts.clear();
    notifyListeners();
  }

  Future<void> _poll() async {
    if (_polling) {
      return;
    }
    final userId = _ref.read(authControllerProvider).user?.id;
    if (userId == null) {
      stop();
      return;
    }

    _polling = true;
    try {
      final repo = _ref.read(notificationRepositoryProvider);
      final unread = await repo.unreadCount();
      final unreadGrew =
          _lastUnreadCount != null && unread > _lastUnreadCount!;
      _lastUnreadCount = unread;
      _ref.invalidate(unreadNotificationCountProvider);

      // Skip full list fetch when nothing new (after bootstrap).
      if (_bootstrapped && !unreadGrew && unread == 0) {
        return;
      }
      if (_bootstrapped && !unreadGrew) {
        // Still refresh list occasionally so read/unread stay in sync, but
        // only when we might have new toasts (unread grew) we must fetch.
        // When unread is stable and >0 (old unread), no new toast needed.
        return;
      }

      final items = await repo.notifications();
      final ids = items.map((item) => item.id).toSet();

      if (!_bootstrapped) {
        _knownIds
          ..clear()
          ..addAll(ids);
        _bootstrapped = true;
        return;
      }

      final incoming = items
          .where((item) => !_knownIds.contains(item.id))
          .toList()
        ..sort((a, b) {
          final aAt = a.createdAt ?? '';
          final bAt = b.createdAt ?? '';
          return aAt.compareTo(bAt);
        });

      if (incoming.isEmpty) {
        return;
      }

      _knownIds.addAll(incoming.map((item) => item.id));
      for (final notification in incoming) {
        _enqueue(notification);
        showBrowserOsNotification(
          title: notification.title,
          body: notification.body,
          tag: 'ee-notif-${notification.id}',
        );
      }
      playNotificationSound();
      _ref.invalidate(notificationsProvider);
    } catch (_) {
      // Polling must stay quiet on network errors.
    } finally {
      _polling = false;
    }
  }

  void _enqueue(UserNotificationDto notification) {
    dismiss(notification.id);
    final item = NotificationToastItem(
      notification: notification,
      queuedAt: DateTime.now(),
    );
    _toasts.insert(0, item);
    while (_toasts.length > 3) {
      final dropped = _toasts.removeLast();
      _autoDismiss.remove(dropped.id)?.cancel();
    }
    _autoDismiss[item.id]?.cancel();
    _autoDismiss[item.id] = Timer(const Duration(seconds: 8), () {
      dismiss(item.id);
    });
    notifyListeners();
  }
}

final notificationToastControllerProvider =
    ChangeNotifierProvider<NotificationToastController>((ref) {
  final controller = NotificationToastController(ref);
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    controller.syncAuth();
  });
  Future.microtask(controller.syncAuth);
  ref.onDispose(controller.stop);
  return controller;
});
