import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_device_repository.dart';

class GetAdminDeviceDetailUseCase {
  const GetAdminDeviceDetailUseCase(this._repository);
  final AdminDeviceRepository _repository;
  Future<Result<AdminDeviceListItem, AppError>> call(String deviceId) => _repository.getDeviceDetail(deviceId);
}
