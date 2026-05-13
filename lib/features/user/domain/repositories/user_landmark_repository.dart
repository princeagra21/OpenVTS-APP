import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/create_user_landmark_input.dart';
import 'package:open_vts/features/user/domain/entities/update_user_landmark_input.dart';
import 'package:open_vts/features/user/domain/entities/user_landmark_item.dart';

abstract interface class UserLandmarkRepository {
  Future<Result<List<UserLandmarkItem>, AppError>> getGeofences();
  Future<Result<List<UserLandmarkItem>, AppError>> getRoutes();
  Future<Result<List<UserLandmarkItem>, AppError>> getPois();
  Future<Result<UserLandmarkItem, AppError>> createLandmark(CreateUserLandmarkInput input);
  Future<Result<UserLandmarkItem, AppError>> updateLandmark(UpdateUserLandmarkInput input);
  Future<Result<void, AppError>> deleteLandmark(String id);
}
