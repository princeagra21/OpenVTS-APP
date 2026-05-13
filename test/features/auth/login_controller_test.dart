import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/router/route_names.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/auth/di/auth_providers.dart';
import 'package:open_vts/features/auth/domain/entities/auth_user.dart';
import 'package:open_vts/features/auth/domain/entities/login_response.dart';
import 'package:open_vts/features/auth/domain/entities/user_role.dart';
import 'package:open_vts/features/auth/domain/repositories/auth_repository.dart';
import 'package:open_vts/features/auth/domain/use_cases/forgot_password_use_case.dart';
import 'package:open_vts/features/auth/domain/use_cases/login_use_case.dart';
import 'package:open_vts/features/auth/domain/use_cases/logout_use_case.dart';
import 'package:open_vts/features/auth/domain/use_cases/restore_session_use_case.dart';
import 'package:open_vts/features/auth/presentation/providers/login_controller.dart';

class _FakeAuthRepository implements AuthRepository {
  Result<LoginResponse, AppError>? loginResult;
  Completer<Result<LoginResponse, AppError>>? loginCompleter;
  Result<String, AppError> forgotPasswordResult = const Result.success('sent');
  int logoutCount = 0;

  @override
  Future<Result<LoginResponse, AppError>> login({required String identifier, required String password}) async {
    final completer = loginCompleter;
    if (completer != null) return completer.future;
    return loginResult ?? Result.success(LoginResponse(user: _user(UserRole.admin)));
  }

  @override
  Future<Result<AuthUser?, AppError>> restoreSession() async => const Result.success(null);

  @override
  Future<Result<AuthUser?, AppError>> refreshSession() async => const Result.success(null);

  @override
  Future<Result<String, AppError>> forgotPassword({required String identifier}) async => forgotPasswordResult;

  @override
  Future<Result<void, AppError>> logout() async {
    logoutCount += 1;
    return const Result.success(null);
  }
}

void main() {
  test('login success exposes role target path', () async {
    final repo = _FakeAuthRepository()
      ..loginResult = Result.success(LoginResponse(user: _user(UserRole.admin)));
    final container = _container(repo);
    addTearDown(container.dispose);

    final result = await container.read(loginControllerProvider.notifier).submitLogin(
          identifier: 'admin',
          password: 'secret',
        );

    expect(result.isSuccess, true);
    expect(result.valueOrNull, AppRoutePaths.adminHome);
    expect(container.read(loginControllerProvider).successTargetPath, AppRoutePaths.adminHome);
  });

  test('invalid credentials maps to user-safe AppError', () async {
    final repo = _FakeAuthRepository()
      ..loginResult = const Result.failure(AuthError('backend denied'));
    final container = _container(repo);
    addTearDown(container.dispose);

    final result = await container.read(loginControllerProvider.notifier).submitLogin(
          identifier: 'admin',
          password: 'bad',
        );

    expect(result.isFailure, true);
    expect(result.errorOrNull?.message, 'Invalid credentials.');
    expect(container.read(loginControllerProvider).errorMessage, 'Invalid credentials.');
  });

  test('unsupported role calls logout use case', () async {
    final repo = _FakeAuthRepository()
      ..loginResult = Result.success(LoginResponse(user: _user(UserRole.unknown)));
    final container = _container(repo);
    addTearDown(container.dispose);

    final result = await container.read(loginControllerProvider.notifier).submitLogin(
          identifier: 'admin',
          password: 'secret',
        );

    expect(result.isFailure, true);
    expect(result.errorOrNull, isA<PermissionAppError>());
    expect(repo.logoutCount, 1);
  });

  test('double submit is blocked', () async {
    final repo = _FakeAuthRepository()
      ..loginCompleter = Completer<Result<LoginResponse, AppError>>();
    final container = _container(repo);
    addTearDown(container.dispose);

    final first = container.read(loginControllerProvider.notifier).submitLogin(
          identifier: 'admin',
          password: 'secret',
        );
    await Future<void>.delayed(Duration.zero);

    final second = await container.read(loginControllerProvider.notifier).submitLogin(
          identifier: 'admin',
          password: 'secret',
        );

    expect(second.isFailure, true);
    expect(second.errorOrNull, isA<ValidationError>());

    repo.loginCompleter!.complete(Result.success(LoginResponse(user: _user(UserRole.admin))));
    await first;
  });
}

AuthUser _user(UserRole role) {
  return AuthUser(
    id: '1',
    name: 'User',
    email: 'user@example.com',
    role: role,
  );
}

ProviderContainer _container(_FakeAuthRepository repo) {
  return ProviderContainer(
    overrides: [
      loginUseCaseProvider.overrideWithValue(LoginUseCase(repo)),
      logoutUseCaseProvider.overrideWithValue(LogoutUseCase(repo)),
      restoreSessionUseCaseProvider.overrideWithValue(RestoreSessionUseCase(repo)),
      forgotPasswordUseCaseProvider.overrideWithValue(ForgotPasswordUseCase(repo)),
    ],
  );
}
