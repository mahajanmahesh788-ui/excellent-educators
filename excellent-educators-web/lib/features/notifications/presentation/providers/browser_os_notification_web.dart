import 'dart:js_interop';

@JS('eeNotifySupported')
external bool _eeNotifySupported();

@JS('eeNotifyPermission')
external String _eeNotifyPermission();

@JS('eeNotifyRequestPermission')
external JSPromise<JSAny?> _eeNotifyRequestPermission();

@JS('eeNotifyShow')
external bool _eeNotifyShow(
  String title,
  String body,
  String? tag,
  String? icon,
);

bool browserOsNotificationsSupported() {
  try {
    return _eeNotifySupported();
  } catch (_) {
    return false;
  }
}

String browserOsNotificationPermission() {
  try {
    return _eeNotifyPermission();
  } catch (_) {
    return 'denied';
  }
}

/// Ask for Notification permission (must run after a user gesture).
Future<String> ensureBrowserOsNotificationPermission() async {
  try {
    if (!browserOsNotificationsSupported()) {
      return 'denied';
    }
    final current = browserOsNotificationPermission();
    if (current == 'granted' || current == 'denied') {
      return current;
    }
    final result = await _eeNotifyRequestPermission().toDart;
    if (result == null) {
      return browserOsNotificationPermission();
    }
    return result.dartify()?.toString() ?? browserOsNotificationPermission();
  } catch (_) {
    return 'denied';
  }
}

/// Shows an OS / browser banner. Sound is controlled by the OS when
/// `silent: false` (set in the JS bridge). Returns false if blocked.
bool showBrowserOsNotification({
  required String title,
  required String body,
  String? tag,
  String? icon,
}) {
  try {
    if (browserOsNotificationPermission() != 'granted') {
      return false;
    }
    return _eeNotifyShow(
      title,
      body,
      tag,
      icon ?? 'icons/Icon-192.png',
    );
  } catch (_) {
    return false;
  }
}
