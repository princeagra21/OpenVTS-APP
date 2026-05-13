import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/user_route_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_route_repository.dart';

class GetUserRoutesUseCase {
  const GetUserRoutesUseCase(this._repository);
  final UserRouteRepository _repository;
  Future<Result<List<UserRouteItem>, AppError>> call() => _repository.getRoutes();
}
