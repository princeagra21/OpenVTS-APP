import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/repositories/user_landmark_repository.dart';

class DeleteUserLandmarkUseCase {
  const DeleteUserLandmarkUseCase(this._repository);
  final UserLandmarkRepository _repository;

  Future<Result<void, AppError>> call(String id) => _repository.deleteLandmark(id);
}
