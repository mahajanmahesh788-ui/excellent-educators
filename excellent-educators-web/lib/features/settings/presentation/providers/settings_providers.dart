import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/features/settings/data/dto/app_settings_dto.dart';
import 'package:excellent_educators_web/features/settings/data/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(apiClientProvider));
});

final adminSettingsProvider = FutureProvider.autoDispose<AppSettingsDto>((ref) {
  return ref.watch(settingsRepositoryProvider).fetch();
});
