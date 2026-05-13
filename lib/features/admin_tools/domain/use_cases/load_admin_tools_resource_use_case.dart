import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin_tools/domain/repositories/admin_tools_repository.dart';

class LoadAdminToolsResourceUseCase {
  const LoadAdminToolsResourceUseCase(this.repository);

  final AdminToolsRepository repository;

  Future<Result<Object?, AppError>> call(String resourceKey) {
    return repository.loadResource(resourceKey);
  }
}
