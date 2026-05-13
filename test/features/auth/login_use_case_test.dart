import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/auth/domain/entities/auth_user.dart';
import 'package:open_vts/features/auth/domain/entities/login_response.dart';
import 'package:open_vts/features/auth/domain/entities/user_role.dart';
import 'package:open_vts/features/auth/domain/repositories/auth_repository.dart';
import 'package:open_vts/features/auth/domain/use_cases/login_use_case.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.result);
  final Result<LoginResponse, AppError> result;

  @override
  Future<Result<LoginResponse, AppError>> login({
    required String identifier,
    required String password,
  }) async => result;

  @override
  Future<Result<AuthUser?, AppError>> restoreSession() async => const Result.success(null);

  @override
  Future<Result<AuthUser?, AppError>> refreshSession() async => const Result.success(null);

  @override
  Future<Result<String, AppError>> forgotPassword({required String identifier}) async => const Result.success('sent');

  @override
  Future<Result<void, AppError>> logout() async => const Result.success(null);
}

void main() {
  test('LoginUseCase returns LoginResponse on success without exposing tokens', () async {
    final useCase = LoginUseCase(
      _FakeAuthRepository(
        const Result.success(
          LoginResponse(
            user: AuthUser(id: '1', name: 'Admin', email: 'a@b.com', role: UserRole.admin),
          ),
        ),
      ),
    );

    final result = await useCase(const LoginParams(identifier: 'admin', password: 'secret'));

    expect(result.isSuccess, true);
    expect(result.valueOrNull?.user.role, UserRole.admin);
  });

  test('LoginUseCase propagates AppError on failure', () async {
    final useCase = LoginUseCase(
      _FakeAuthRepository(const Result.failure(AuthError('denied'))),
    );

    final result = await useCase(const LoginParams(identifier: 'admin', password: 'bad'));

    expect(result.isFailure, true);
    expect(result.errorOrNull, isA<AuthError>());
  });
}
