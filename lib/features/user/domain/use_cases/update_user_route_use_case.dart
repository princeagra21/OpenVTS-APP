import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/update_user_route_input.dart';
import 'package:open_vts/features/user/domain/entities/user_route_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_route_repository.dart';

class UpdateUserRouteUseCase {
  const UpdateUserRouteUseCase(this._repository);
  final UserRouteRepository _repository;
  Future<Result<UserRouteItem, AppError>> call(UpdateUserRouteInput input) => _repository.updateRoute(input);
}
