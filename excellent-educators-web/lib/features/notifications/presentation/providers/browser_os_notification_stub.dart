/// Stub: no browser Notification API outside web.
bool browserOsNotificationsSupported() => false;

String browserOsNotificationPermission() => 'denied';

Future<String> ensureBrowserOsNotificationPermission() async => 'denied';

bool showBrowserOsNotification({
  required String title,
  required String body,
  String? tag,
  String? icon,
}) =>
    false;
