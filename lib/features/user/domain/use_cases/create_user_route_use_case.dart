import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/create_user_route_input.dart';
import 'package:open_vts/features/user/domain/entities/user_route_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_route_repository.dart';

class CreateUserRouteUseCase {
  const CreateUserRouteUseCase(this._repository);
  final UserRouteRepository _repository;
  Future<Result<UserRouteItem, AppError>> call(CreateUserRouteInput input) => _repository.createRoute(input);
}
