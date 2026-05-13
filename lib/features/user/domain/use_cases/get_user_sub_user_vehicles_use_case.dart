import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/repositories/user_sub_user_repository.dart';

class GetUserSubUserVehiclesUseCase {
  const GetUserSubUserVehiclesUseCase(this._repository);
  final UserSubUserRepository _repository;

  Future<Result<List<Map<String, Object?>>, AppError>> call(String id) {
    return _repository.getSubUserVehicles(id);
  }
}
