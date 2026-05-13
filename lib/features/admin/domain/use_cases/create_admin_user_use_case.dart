import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_form_options.dart';
import 'package:open_vts/features/admin/domain/entities/create_admin_user_input.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_form_repository.dart';

class CreateAdminUserUseCase {
  const CreateAdminUserUseCase(this._repository);

  final AdminFormRepository _repository;

  Future<Result<AdminCreatedUser, AppError>> call(CreateAdminUserInput input) {
    return _repository.createUser(input);
  }
}
