import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/add_vehicle_form_data.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_form_repository.dart';

class LoadAddVehicleFormDataUseCase {
  const LoadAddVehicleFormDataUseCase(this._repository);

  final AdminFormRepository _repository;

  Future<Result<AddVehicleFormData, AppError>> call() {
    return _repository.loadAddVehicleFormData();
  }
}
