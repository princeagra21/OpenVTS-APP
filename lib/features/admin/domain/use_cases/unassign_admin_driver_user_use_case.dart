import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_driver_repository.dart';

class UnassignAdminDriverUserUseCase {
  const UnassignAdminDriverUserUseCase(this._repository);
  final AdminDriverRepository _repository;
  Future<Result<void, AppError>> call(String driverId, {required int userId}) => _repository.unassignUserFromDriver(driverId, userId: userId);
}
