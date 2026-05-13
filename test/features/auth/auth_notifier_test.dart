import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/auth/di/auth_providers.dart';
import 'package:open_vts/features/auth/domain/entities/auth_user.dart';
import 'package:open_vts/features/auth/domain/entities/login_response.dart';
import 'package:open_vts/features/auth/domain/entities/user_role.dart';
import 'package:open_vts/features/auth/domain/repositories/auth_repository.dart';
import 'package:open_vts/features/auth/domain/use_cases/login_use_case.dart';
import 'package:open_vts/features/auth/domain/use_cases/logout_use_case.dart';
import 'package:open_vts/features/auth/domain/use_cases/restore_session_use_case.dart';
import 'package:open_vts/features/auth/presentation/providers/auth_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  Result<LoginResponse, AppError> loginResult = Result.success(
    LoginResponse(user: _user),
  );
  Result<AuthUser?, AppError> restoreResult = const Result.success(null);
  Result<void, AppError> logoutResult = const Result.success(null);
  int logoutCount = 0;

  static const _user = AuthUser(
    id: '1',
    name: 'Admin',
    email: 'admin@example.com',
    role: UserRole.admin,
  );

  @override
  Future<Result<LoginResponse, AppError>> login({required String identifier, required String password}) async => loginResult;

  @override
  Future<Result<AuthUser?, AppError>> restoreSession() async => restoreResult;

  @override
  Future<Result<AuthUser?, AppError>> refreshSession() async => const Result.success(null);

  @override
  Future<Result<String, AppError>> forgotPassword({required String identifier}) async => const Result.success('sent');

  @override
  Future<Result<void, AppError>> logout() async {
    logoutCount += 1;
    return logoutResult;
  }
}

void main() {
  test('AuthNotifier restores session on startup', () async {
    final repo = _FakeAuthRepository()
      ..restoreResult = const Result.success(_FakeAuthRepository._user);
    final container = _container(repo);
    addTearDown(container.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(container.read(authNotifierProvider).valueOrNull?.role, UserRole.admin);
  });

  test('AuthNotifier restore with no token becomes unauthenticated', () async {
    final repo = _FakeAuthRepository()..restoreResult = const Result.success(null);
    final container = _container(repo);
    addTearDown(container.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(container.read(authNotifierProvider).valueOrNull, isNull);
  });

  test('AuthNotifier login success owns authenticated state', () async {
    final repo = _FakeAuthRepository();
    final container = _container(repo);
    addTearDown(container.dispose);
    await Future<void>.delayed(Duration.zero);

    await container.read(authNotifierProvider.notifier).login('admin', 'secret');

    expect(container.read(authNotifierProvider).valueOrNull?.email, 'admin@example.com');
  });

  test('AuthNotifier logout clears authenticated state and runs session cleanup hook', () async {
    final repo = _FakeAuthRepository()
      ..restoreResult = const Result.success(_FakeAuthRepository._user);
    var cleanupCount = 0;
    final container = _container(
      repo,
      cleanup: () async => cleanupCount += 1,
    );
    addTearDown(container.dispose);
    await Future<void>.delayed(Duration.zero);

    await container.read(authNotifierProvider.notifier).logout();

    expect(repo.logoutCount, 1);
    expect(cleanupCount, 1);
    expect(container.read(authNotifierProvider).valueOrNull, isNull);
  });
}

ProviderContainer _container(
  _FakeAuthRepository repo, {
  Future<void> Function()? cleanup,
}) {
  return ProviderContainer(
    overrides: [
      loginUseCaseProvider.overrideWithValue(LoginUseCase(repo)),
      logoutUseCaseProvider.overrideWithValue(LogoutUseCase(repo)),
      restoreSessionUseCaseProvider.overrideWithValue(RestoreSessionUseCase(repo)),
      authSessionCleanupProvider.overrideWithValue(cleanup ?? () async {}),
    ],
  );
}
