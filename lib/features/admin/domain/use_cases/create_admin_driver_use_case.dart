import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_form_input.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_driver_form_repository.dart';

class CreateAdminDriverUseCase {
  const CreateAdminDriverUseCase(this._repository);

  final AdminDriverFormRepository _repository;

  Future<Result<AdminDriverListItem, AppError>> call(CreateAdminDriverInput input) {
    return _repository.createDriver(input);
  }
}
