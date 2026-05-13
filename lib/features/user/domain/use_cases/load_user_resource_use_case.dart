import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/repositories/user_repository.dart';

class LoadUserResourceUseCase {
  const LoadUserResourceUseCase(this.repository);

  final UserRepository repository;

  Future<Result<Object?, AppError>> call(String resourceKey) {
    return repository.loadResource(resourceKey);
  }
}
