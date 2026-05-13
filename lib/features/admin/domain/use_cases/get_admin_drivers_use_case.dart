import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_driver_repository.dart';

class GetAdminDriversUseCase {
  const GetAdminDriversUseCase(this._repository);
  final AdminDriverRepository _repository;
  Future<Result<List<AdminDriverListItem>, AppError>> call({String? search, String? status, int? page, int? limit}) {
    return _repository.getDrivers(search: search, status: status, page: page, limit: limit);
  }
}
