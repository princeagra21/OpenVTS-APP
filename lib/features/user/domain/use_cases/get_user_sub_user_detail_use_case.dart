import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/user_subuser_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_sub_user_repository.dart';

class GetUserSubUserDetailUseCase {
  const GetUserSubUserDetailUseCase(this._repository);
  final UserSubUserRepository _repository;
  Future<Result<UserSubUserItem, AppError>> call(String id) => _repository.getSubUserDetail(id);
}
