import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this.repository);
  final AuthRepository repository;

  Future<Result<void, AppError>> call() => repository.logout();
}
