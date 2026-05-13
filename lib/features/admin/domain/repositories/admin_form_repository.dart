import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/add_vehicle_form_data.dart';
import 'package:open_vts/features/admin/domain/entities/admin_form_options.dart';
import 'package:open_vts/features/admin/domain/entities/create_admin_user_input.dart';
import 'package:open_vts/features/admin/domain/entities/create_admin_vehicle_input.dart';

abstract interface class AdminFormRepository {
  Future<Result<AddVehicleFormData, AppError>> loadAddVehicleFormData();
  Future<Result<AdminCreatedVehicle, AppError>> createVehicle(CreateAdminVehicleInput input);
  Future<Result<AdminCreatedUser, AppError>> createUser(CreateAdminUserInput input);
}
