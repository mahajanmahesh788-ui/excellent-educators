import 'package:excellent_educators_web/core/errors/failure.dart';
import 'package:excellent_educators_web/core/network/api_exception.dart';
import 'package:excellent_educators_web/core/storage/token_store.dart';
import 'package:excellent_educators_web/features/auth/data/auth_remote_datasource.dart';
import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';
import 'package:excellent_educators_web/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._tokenStore);

  final AuthRemoteDatasource _remote;
  final TokenStore _tokenStore;

  @override
  Future<AppUser> login({required String email, required String password}) async {
    try {
      final session = await _remote.login(email: email, password: password);
      await _tokenStore.write(session.token);
      return session.user;
    } on ApiException catch (error) {
      throw Failure(error.message, code: error.code);
    }
  }

  @override
  Future<AppUser> me() async {
    try {
      return await _remote.me();
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _tokenStore.clear();
      }
      throw Failure(error.message, code: error.code);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } on ApiException {
      // Token is cleared locally either way.
    } finally {
      await _tokenStore.clear();
    }
  }

  @override
  Future<String?> readToken() => _tokenStore.read();

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await _remote.forgotPassword(email: email);
    } on ApiException catch (error) {
      throw Failure(error.message, code: error.code);
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _remote.resetPassword(
        email: email,
        token: token,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
    } on ApiException catch (error) {
      throw Failure(error.message, code: error.code);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _remote.changePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
    } on ApiException catch (error) {
      throw Failure(error.message, code: error.code);
    } finally {
      await _tokenStore.clear();
    }
  }
}
