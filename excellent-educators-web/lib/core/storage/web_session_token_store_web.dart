import 'package:excellent_educators_web/core/storage/token_store.dart';
import 'package:web/web.dart' as web;

/// Browser sessionStorage — cleared when the tab closes; not written to
/// persistent localStorage (reduces token lifetime after XSS / shared PCs).
class WebSessionTokenStore implements TokenStore {
  static const _key = 'ee_access_token';

  @override
  Future<String?> read() async {
    final value = web.window.sessionStorage.getItem(_key);
    return (value == null || value.isEmpty) ? null : value;
  }

  @override
  Future<void> write(String token) async {
    web.window.sessionStorage.setItem(_key, token);
  }

  @override
  Future<void> clear() async {
    web.window.sessionStorage.removeItem(_key);
  }
}

TokenStore createWebSessionTokenStore() => WebSessionTokenStore();
