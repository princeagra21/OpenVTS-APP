import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/user/domain/repositories/user_vehicle_form_repository.dart';

class GetUserVehicleTypesUseCase {
  const GetUserVehicleTypesUseCase(this._repository);

  final UserVehicleFormRepository _repository;

  Future<Result<List<ReferenceOption>, AppError>> call() => _repository.getVehicleTypes();
}
