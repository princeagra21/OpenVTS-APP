import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_device_repository.dart';

class GetAdminDevicesUseCase {
  const GetAdminDevicesUseCase(this._repository);
  final AdminDeviceRepository _repository;
  Future<Result<List<AdminDeviceListItem>, AppError>> call({String? search, String? status, int? page, int? limit}) {
    return _repository.getDevices(search: search, status: status, page: page, limit: limit);
  }
}
