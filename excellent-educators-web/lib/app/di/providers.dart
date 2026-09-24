import 'package:excellent_educators_web/core/network/account_inactive_signal.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/storage/token_store.dart';
import 'package:excellent_educators_web/features/auth/data/auth_remote_datasource.dart';
import 'package:excellent_educators_web/features/auth/data/auth_repository_impl.dart';
import 'package:excellent_educators_web/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) {
  throw UnimplementedError(AppStrings.tokenstoreproviderMustBeOverriddenInBootstrap);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final store = ref.watch(tokenStoreProvider);
  final client = ApiClient(
    tokenStore: store,
    onAccountInactive: () {
      Future.microtask(() async {
        await store.clear();
        ref.read(accountInactiveSignalProvider.notifier).state = true;
      });
    },
  );
  ref.onDispose(client.close);
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    AuthRemoteDatasource(ref.watch(apiClientProvider)),
    ref.watch(tokenStoreProvider),
  );
});
