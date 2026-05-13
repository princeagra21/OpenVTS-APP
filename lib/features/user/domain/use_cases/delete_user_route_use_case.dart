import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/repositories/user_route_repository.dart';

class DeleteUserRouteUseCase {
  const DeleteUserRouteUseCase(this._repository);
  final UserRouteRepository _repository;
  Future<Result<void, AppError>> call(String routeId) => _repository.deleteRoute(routeId);
}
