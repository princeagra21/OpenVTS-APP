import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/auth/domain/entities/login_response.dart';
import 'package:open_vts/features/auth/domain/repositories/auth_repository.dart';

class LoginParams {
  const LoginParams({required this.identifier, required this.password});
  final String identifier;
  final String password;
}

class LoginUseCase {
  const LoginUseCase(this.repository);
  final AuthRepository repository;

  Future<Result<LoginResponse, AppError>> call(LoginParams params) {
    return repository.login(
      identifier: params.identifier,
      password: params.password,
    );
  }
}
