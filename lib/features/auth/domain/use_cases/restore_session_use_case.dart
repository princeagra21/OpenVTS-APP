import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/auth/domain/entities/auth_user.dart';
import 'package:open_vts/features/auth/domain/repositories/auth_repository.dart';

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this.repository);
  final AuthRepository repository;

  Future<Result<AuthUser?, AppError>> call() => repository.restoreSession();
}
