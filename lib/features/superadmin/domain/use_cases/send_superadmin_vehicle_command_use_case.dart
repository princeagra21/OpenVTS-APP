import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_vehicle_repository.dart';

class SendSuperadminVehicleCommandUseCase {
  const SendSuperadminVehicleCommandUseCase(this._repository);
  final SuperadminVehicleRepository _repository;
  Future<Result<void, AppError>> call(String imei, String commandCode, Map<String, Object?>? payload, bool confirm) {
    return _repository.sendCommand(imei, commandCode, payload, confirm);
  }
}
