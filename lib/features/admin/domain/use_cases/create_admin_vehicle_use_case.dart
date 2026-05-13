import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_form_options.dart';
import 'package:open_vts/features/admin/domain/entities/create_admin_vehicle_input.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_form_repository.dart';

class CreateAdminVehicleUseCase {
  const CreateAdminVehicleUseCase(this._repository);

  final AdminFormRepository _repository;

  Future<Result<AdminCreatedVehicle, AppError>> call(CreateAdminVehicleInput input) {
    return _repository.createVehicle(input);
  }
}
