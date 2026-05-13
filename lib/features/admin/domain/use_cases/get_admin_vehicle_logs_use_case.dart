import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_log_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_vehicle_repository.dart';

class GetAdminVehicleLogsUseCase {
  const GetAdminVehicleLogsUseCase(this._repository);

  final AdminVehicleRepository _repository;

  Future<Result<List<AdminVehicleLogItem>, AppError>> call(
    String imei, {
    Map<String, Object?>? query,
  }) {
    return _repository.getVehicleLogsByImei(imei, query: query);
  }
}
