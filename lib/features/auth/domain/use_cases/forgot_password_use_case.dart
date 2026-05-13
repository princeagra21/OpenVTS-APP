import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/auth/domain/repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  const ForgotPasswordUseCase(this.repository);
  final AuthRepository repository;

  Future<Result<String, AppError>> call(String identifier) {
    return repository.forgotPassword(identifier: identifier);
  }
}
