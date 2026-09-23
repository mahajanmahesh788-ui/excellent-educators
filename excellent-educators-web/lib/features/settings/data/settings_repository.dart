import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/maps_api_failures.dart';
import 'package:excellent_educators_web/features/settings/data/dto/app_settings_dto.dart';

class SettingsRepository with MapsApiFailures {
  SettingsRepository(this._client);

  final ApiClient _client;

  Future<AppSettingsDto> fetch() {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.adminSettings);
      return AppSettingsDto.fromJson(json!);
    });
  }

  Future<AppSettingsDto> save(Map<String, Object?> values) {
    return runApi(() async {
      final json = await _client.put(ApiEndpoints.adminSettings, data: {'values': values});
      return AppSettingsDto.fromJson(json!);
    });
  }
}
