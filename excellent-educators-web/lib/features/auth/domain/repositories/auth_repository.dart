import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser> login({required String email, required String password});

  Future<AppUser> me();

  Future<void> logout();

  Future<String?> readToken();

  Future<void> forgotPassword({required String email});

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  });
}
