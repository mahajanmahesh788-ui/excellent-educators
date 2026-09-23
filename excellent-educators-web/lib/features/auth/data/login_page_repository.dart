import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/maps_api_failures.dart';
import 'package:excellent_educators_web/features/auth/data/dto/login_page_dtos.dart';

class LoginPageRepository with MapsApiFailures {
  LoginPageRepository(this._client);

  final ApiClient _client;

  Future<LoginPageContentDto> fetchPublic() {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.loginPageContent);
      return LoginPageContentDto.fromJson(json!);
    });
  }

  Future<LoginPageContentDto> fetchAdmin() {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.adminLoginPageContent);
      return LoginPageContentDto.fromJson(json!);
    });
  }

  Future<LoginPageContentDto> updateAdmin(LoginPageContentDto content) {
    return runApi(() async {
      final json = await _client.put(ApiEndpoints.adminLoginPageContent, data: content.toAdminUpdateJson());
      return LoginPageContentDto.fromJson(json!);
    });
  }
}
