import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/core/errors/failure.dart';
import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';
import 'package:excellent_educators_web/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isReady = false,
    this.isLoading = false,
    this.error,
    this.errorCode,
    this.accountDisabled = false,
  });

  final AppUser? user;
  final bool isReady;
  final bool isLoading;
  final String? error;
  final String? errorCode;
  final bool accountDisabled;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isReady,
    bool? isLoading,
    String? error,
    String? errorCode,
    bool? accountDisabled,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isReady: isReady ?? this.isReady,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      accountDisabled: accountDisabled ?? this.accountDisabled,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState()) {
    restore();
  }

  final AuthRepository _repository;

  Future<void> restore() async {
    final token = await _repository.readToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(isReady: true, clearUser: true);
      return;
    }
    try {
      final user = await _repository.me();
      if (!user.isActive) {
        await _repository.logout();
        state = const AuthState(isReady: true, accountDisabled: true);
        return;
      }
      state = AuthState(user: user, isReady: true);
    } on Failure catch (error) {
      if (error.code == 'ACCOUNT_INACTIVE') {
        await _repository.logout();
        state = const AuthState(isReady: true, accountDisabled: true);
        return;
      }
      state = const AuthState(isReady: true);
    } catch (_) {
      state = const AuthState(isReady: true);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true, accountDisabled: false);
    try {
      final user = await _repository.login(email: email, password: password);
      if (!user.isActive) {
        await _repository.logout();
        state = const AuthState(
          isReady: true,
          accountDisabled: true,
          error: AppStrings.accountDisabledByAdmin,
          errorCode: 'ACCOUNT_INACTIVE',
        );
        return false;
      }
      state = AuthState(user: user, isReady: true);
      return true;
    } on Failure catch (error) {
      final disabled = error.code == 'ACCOUNT_INACTIVE';
      state = state.copyWith(
        isReady: true,
        isLoading: false,
        error: disabled ? AppStrings.accountDisabledByAdmin : error.message,
        errorCode: error.code,
        accountDisabled: disabled,
        clearUser: true,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isReady: true,
        isLoading: false,
        error: AppStrings.unableToSignInPleaseTryAgain,
        clearUser: true,
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(isReady: true);
  }

  void handleAccountDisabled() {
    state = const AuthState(isReady: true, accountDisabled: true);
  }

  void clearAccountDisabled() {
    state = state.copyWith(accountDisabled: false);
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _repository.forgotPassword(email: email);
    } on Failure catch (error) {
      throw error.message;
    }
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _repository.resetPassword(
        email: email,
        token: token,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
    } on Failure catch (error) {
      throw error.message;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      state = const AuthState(isReady: true);
    } on Failure catch (error) {
      throw error.message;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
