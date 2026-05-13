import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_repository.dart';

class LoadAdminResourceUseCase {
  const LoadAdminResourceUseCase(this.repository);

  final AdminRepository repository;

  Future<Result<Object?, AppError>> call(String resourceKey) {
    return repository.loadResource(resourceKey);
  }
}
