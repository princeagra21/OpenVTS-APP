import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_form_data.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_device_form_repository.dart';

class LoadAdminDeviceFormDataUseCase {
  const LoadAdminDeviceFormDataUseCase(this._repository);

  final AdminDeviceFormRepository _repository;

  Future<Result<AdminDeviceFormData, AppError>> call() {
    return _repository.loadFormData();
  }
}
