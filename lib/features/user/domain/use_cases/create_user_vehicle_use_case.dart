import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/create_user_vehicle_input.dart';
import 'package:open_vts/features/user/domain/repositories/user_vehicle_form_repository.dart';

class CreateUserVehicleUseCase {
  const CreateUserVehicleUseCase(this._repository);

  final UserVehicleFormRepository _repository;

  Future<Result<void, AppError>> call(CreateUserVehicleInput input) => _repository.createVehicle(input);
}
