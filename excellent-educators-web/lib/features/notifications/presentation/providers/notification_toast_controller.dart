import 'dart:async';

import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/notifications/data/dto/notification_dtos.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_feature_providers.dart';
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
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(_poll());
    });
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
      final items = await repo.notifications();
      final ids = items.map((item) => item.id).toSet();

      if (!_bootstrapped) {
        _knownIds
          ..clear()
          ..addAll(ids);
        _bootstrapped = true;
        _ref.invalidate(unreadNotificationCountProvider);
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
        _ref.invalidate(unreadNotificationCountProvider);
        return;
      }

      _knownIds.addAll(incoming.map((item) => item.id));
      for (final notification in incoming) {
        _enqueue(notification);
      }
      _ref.invalidate(unreadNotificationCountProvider);
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
    _autoDismiss[item.id] = Timer(const Duration(seconds: 7), () {
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
  // Kick once if already logged in.
  Future.microtask(controller.syncAuth);
  ref.onDispose(controller.stop);
  return controller;
});
