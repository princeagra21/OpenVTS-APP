import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_driver_repository.dart';

class GetUserDriversUseCase {
  const GetUserDriversUseCase(this._repository);
  final UserDriverRepository _repository;
  Future<Result<List<AdminDriverListItem>, AppError>> call() => _repository.getDrivers();
}
