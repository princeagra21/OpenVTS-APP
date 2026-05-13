import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/create_user_route_input.dart';
import 'package:open_vts/features/user/domain/entities/update_user_route_input.dart';
import 'package:open_vts/features/user/domain/entities/user_route_item.dart';

abstract interface class UserRouteRepository {
  Future<Result<List<UserRouteItem>, AppError>> getRoutes();
  Future<Result<UserRouteItem, AppError>> createRoute(CreateUserRouteInput input);
  Future<Result<UserRouteItem, AppError>> assignRouteDriver(String routeId, String? driver);
  Future<Result<UserRouteItem, AppError>> updateRoute(UpdateUserRouteInput input);
  Future<Result<void, AppError>> deleteRoute(String routeId);
}
