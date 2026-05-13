import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/user_route_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_route_repository.dart';

class AssignRouteDriverUseCase {
  const AssignRouteDriverUseCase(this._repository);
  final UserRouteRepository _repository;
  Future<Result<UserRouteItem, AppError>> call(String routeId, String? driver) => _repository.assignRouteDriver(routeId, driver);
}
