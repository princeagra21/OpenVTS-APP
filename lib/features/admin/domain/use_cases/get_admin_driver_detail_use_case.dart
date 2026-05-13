import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_details.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_driver_repository.dart';

class GetAdminDriverDetailUseCase {
  const GetAdminDriverDetailUseCase(this._repository);
  final AdminDriverRepository _repository;
  Future<Result<AdminDriverDetails, AppError>> call(String driverId) => _repository.getDriverDetail(driverId);
}
