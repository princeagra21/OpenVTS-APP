import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/user_driver_details.dart';
import 'package:open_vts/features/user/domain/repositories/user_driver_repository.dart';

class GetUserDriverDetailUseCase {
  const GetUserDriverDetailUseCase(this._repository);
  final UserDriverRepository _repository;
  Future<Result<UserDriverDetails, AppError>> call(String id) => _repository.getDriverDetail(id);
}
