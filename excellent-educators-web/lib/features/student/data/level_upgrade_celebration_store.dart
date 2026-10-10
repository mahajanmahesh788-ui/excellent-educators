import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists which promotion celebrations the student has already seen.
class LevelUpgradeCelebrationStore {
  LevelUpgradeCelebrationStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'ee_level_celeb_';

  final FlutterSecureStorage _storage;

  Future<bool> hasSeen(String notificationId) async {
    if (notificationId.isEmpty) {
      return true;
    }
    final value = await _storage.read(key: '$_prefix$notificationId');
    return value == '1';
  }

  Future<void> markSeen(String notificationId) async {
    if (notificationId.isEmpty) {
      return;
    }
    await _storage.write(key: '$_prefix$notificationId', value: '1');
  }
}
