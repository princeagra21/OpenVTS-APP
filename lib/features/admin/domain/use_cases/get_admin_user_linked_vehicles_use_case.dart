import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_account_repository.dart';

class GetAdminUserLinkedVehiclesUseCase {
  const GetAdminUserLinkedVehiclesUseCase(this._repository);

  final AdminAccountRepository _repository;

  Future<Result<List<AdminVehicleListItem>, AppError>> call(String userId) {
    return _repository.getUserLinkedVehicles(userId);
  }
}
