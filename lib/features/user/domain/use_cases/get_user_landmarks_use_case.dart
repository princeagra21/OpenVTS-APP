import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/user_landmark_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_landmark_repository.dart';

class GetUserLandmarksUseCase {
  const GetUserLandmarksUseCase(this._repository);
  final UserLandmarkRepository _repository;

  Future<Result<List<UserLandmarkItem>, AppError>> call() async {
    final all = <UserLandmarkItem>[];
    final geofences = await _repository.getGeofences();
    if (geofences.isFailure) return Result.failure(geofences.errorOrNull!);
    all.addAll(geofences.valueOrNull ?? const <UserLandmarkItem>[]);

    final routes = await _repository.getRoutes();
    if (routes.isFailure) return Result.failure(routes.errorOrNull!);
    all.addAll(routes.valueOrNull ?? const <UserLandmarkItem>[]);

    final pois = await _repository.getPois();
    if (pois.isFailure) return Result.failure(pois.errorOrNull!);
    all.addAll(pois.valueOrNull ?? const <UserLandmarkItem>[]);
    return Result.success(all);
  }

  Future<Result<List<UserLandmarkItem>, AppError>> geofences() => _repository.getGeofences();
  Future<Result<List<UserLandmarkItem>, AppError>> routes() => _repository.getRoutes();
  Future<Result<List<UserLandmarkItem>, AppError>> pois() => _repository.getPois();
}
