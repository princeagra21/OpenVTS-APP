import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_repository.dart';

class LoadSuperadminResourceUseCase {
  const LoadSuperadminResourceUseCase(this.repository);

  final SuperadminRepository repository;

  Future<Result<Object?, AppError>> call(String resourceKey) {
    return repository.loadResource(resourceKey);
  }
}
