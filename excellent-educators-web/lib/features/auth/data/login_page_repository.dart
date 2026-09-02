import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/errors/api_error_message.dart';
import 'package:excellent_educators_web/core/errors/failure.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/api_exception.dart';
import 'package:excellent_educators_web/features/auth/data/dto/login_page_dtos.dart';

class LoginPageRepository {
  LoginPageRepository(this._client);

  final ApiClient _client;

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      throw Failure(formatApiErrorMessage(error), code: error.code);
    }
  }

  Future<LoginPageContentDto> fetchPublic() {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.loginPageContent);
      return LoginPageContentDto.fromJson(json!);
    });
  }

  Future<LoginPageContentDto> fetchAdmin() {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.adminLoginPageContent);
      return LoginPageContentDto.fromJson(json!);
    });
  }

  Future<LoginPageContentDto> updateAdmin(LoginPageContentDto content) {
    return _run(() async {
      final json = await _client.put(ApiEndpoints.adminLoginPageContent, data: content.toAdminUpdateJson());
      return LoginPageContentDto.fromJson(json!);
    });
  }
}
