import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/errors/api_error_message.dart';
import 'package:excellent_educators_web/core/errors/failure.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/api_exception.dart';
import 'package:excellent_educators_web/features/settings/data/dto/app_settings_dto.dart';

class SettingsRepository {
  SettingsRepository(this._client);

  final ApiClient _client;

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      throw Failure(formatApiErrorMessage(error), code: error.code);
    }
  }

  Future<AppSettingsDto> fetch() {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.adminSettings);
      return AppSettingsDto.fromJson(json!);
    });
  }

  Future<AppSettingsDto> save(Map<String, Object?> values) {
    return _run(() async {
      final json = await _client.put(ApiEndpoints.adminSettings, data: {'values': values});
      return AppSettingsDto.fromJson(json!);
    });
  }
}
