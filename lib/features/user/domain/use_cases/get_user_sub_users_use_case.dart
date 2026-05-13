import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/user_subuser_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_sub_user_repository.dart';

class GetUserSubUsersUseCase {
  const GetUserSubUsersUseCase(this._repository);
  final UserSubUserRepository _repository;
  Future<Result<List<UserSubUserItem>, AppError>> call({int page = 1, int limit = 10}) => _repository.getSubUsers(page: page, limit: limit);
}
