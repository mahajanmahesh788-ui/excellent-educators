import 'package:excellent_educators_web/core/storage/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStore implements TokenStore {
  SecureTokenStore(this._storage);

  static const _key = 'ee_access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
