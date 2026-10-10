import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/core/storage/secure_token_store.dart';
import 'package:excellent_educators_web/core/storage/token_store.dart';
import 'package:excellent_educators_web/core/storage/web_session_token_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<List<Override>> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final TokenStore tokenStore;
  if (kIsWeb) {
    // Web: keep the bearer token in sessionStorage (tab-scoped), not
    // localStorage. Also wipe any legacy flutter_secure_storage copy.
    const legacy = FlutterSecureStorage();
    await legacy.delete(key: SecureTokenStore.key);
    tokenStore = createWebSessionTokenStore();
  } else {
    tokenStore = SecureTokenStore(const FlutterSecureStorage());
  }

  return [
    tokenStoreProvider.overrideWithValue(tokenStore),
  ];
}
