import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_form_data.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_form_input.dart';

abstract interface class AdminDeviceFormRepository {
  Future<Result<AdminDeviceFormData, AppError>> loadFormData();
  Future<Result<void, AppError>> createDevice(CreateAdminDeviceInput input);
}
