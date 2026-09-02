import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/core/storage/secure_token_store.dart';
import 'package:excellent_educators_web/core/storage/token_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<List<Override>> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage();
  final TokenStore tokenStore = SecureTokenStore(storage);

  return [
    tokenStoreProvider.overrideWithValue(tokenStore),
  ];
}
