import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';

class CreateAdminVehicleInput {
  const CreateAdminVehicleInput({
    required this.name,
    required this.vin,
    required this.plateNumber,
    required this.deviceId,
    required this.vehicleTypeId,
    required this.primaryUserId,
    required this.planId,
  });

  final String name;
  final String vin;
  final String plateNumber;
  final String deviceId;
  final String vehicleTypeId;
  final String primaryUserId;
  final String planId;

  Result<CreateAdminVehicleInput, AppError> validate() {
    if (name.trim().isEmpty) {
      return const Result.failure(ValidationError('Vehicle name is required'));
    }
    if (plateNumber.trim().isEmpty) {
      return const Result.failure(ValidationError('Plate number is required'));
    }
    if (deviceId.trim().isEmpty) {
      return const Result.failure(ValidationError('Device IMEI is required'));
    }
    if (vehicleTypeId.trim().isEmpty || primaryUserId.trim().isEmpty || planId.trim().isEmpty) {
      return const Result.failure(ValidationError('Please fill all required vehicle fields'));
    }
    return Result.success(this);
  }
}
