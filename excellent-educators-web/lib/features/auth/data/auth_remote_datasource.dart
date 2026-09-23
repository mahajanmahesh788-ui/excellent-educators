import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/api_exception.dart';
import 'package:excellent_educators_web/features/auth/data/dto/user_dto.dart';
import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AppUser user;
}

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._client);

  final ApiClient _client;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
        'device_name': 'web',
      },
    );
    if (data == null || data['token'] is! String || data['user'] is! Map) {
      throw ApiException(message: AppStrings.invalidLoginResponse, code: 'SERVER_ERROR');
    }
    return AuthSession(
      token: data['token'] as String,
      user: UserDto.fromJson(Map<String, dynamic>.from(data['user'] as Map)).toEntity(),
    );
  }

  Future<AppUser> me() async {
    final data = await _client.get(ApiEndpoints.me);
    if (data == null) {
      throw ApiException(message: AppStrings.invalidProfileResponse, code: 'SERVER_ERROR');
    }
    return UserDto.fromJson(data).toEntity();
  }

  Future<void> logout() async {
    await _client.post(ApiEndpoints.logout);
  }

  Future<void> forgotPassword({required String email}) async {
    await _client.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _client.post(
      ApiEndpoints.resetPassword,
      data: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _client.put(
      ApiEndpoints.changePassword,
      data: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }
}
