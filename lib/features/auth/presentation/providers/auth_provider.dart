import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/auth/di/auth_providers.dart';
import 'package:open_vts/features/auth/domain/entities/auth_user.dart';
import 'package:open_vts/features/auth/domain/entities/user_role.dart';
import 'package:open_vts/features/auth/domain/use_cases/login_use_case.dart';
import 'package:open_vts/features/auth/domain/use_cases/logout_use_case.dart';
import 'package:open_vts/features/auth/domain/use_cases/restore_session_use_case.dart';

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthUser?>>((ref) {
  return AuthNotifier(
    loginUseCase: ref.read(loginUseCaseProvider),
    logoutUseCase: ref.read(logoutUseCaseProvider),
    restoreSessionUseCase: ref.read(restoreSessionUseCaseProvider),
    onLogoutCleanup: ref.read(authSessionCleanupProvider),
  )..restoreSession();
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthNotifier({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required RestoreSessionUseCase restoreSessionUseCase,
    required Future<void> Function() onLogoutCleanup,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _restoreSessionUseCase = restoreSessionUseCase,
        _onLogoutCleanup = onLogoutCleanup,
        super(const AsyncLoading());

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final RestoreSessionUseCase _restoreSessionUseCase;
  final Future<void> Function() _onLogoutCleanup;

  Future<void> restoreSession() async {
    final result = await _restoreSessionUseCase();
    state = result.when(
      success: AsyncData.new,
      failure: (error) => AsyncError(error, StackTrace.current),
    );
  }

  Future<void> login(String identifier, String password) async {
    state = const AsyncLoading();
    final result = await _loginUseCase(
      LoginParams(identifier: identifier, password: password),
    );
    state = result.when(
      success: (value) => AsyncData(value.user),
      failure: (AppError error) => AsyncError(error, StackTrace.current),
    );
  }

  Future<void> logout() async {
    final result = await _logoutUseCase();
    if (result.isSuccess) {
      await _onLogoutCleanup();
      state = const AsyncData(null);
      return;
    }
    state = AsyncError(result.errorOrNull!, StackTrace.current);
  }
}

final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull;
});

final currentRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentUserProvider)?.role;
});
