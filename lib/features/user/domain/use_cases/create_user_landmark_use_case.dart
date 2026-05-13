import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/create_user_landmark_input.dart';
import 'package:open_vts/features/user/domain/entities/user_landmark_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_landmark_repository.dart';

class CreateUserLandmarkUseCase {
  const CreateUserLandmarkUseCase(this._repository);
  final UserLandmarkRepository _repository;

  Future<Result<UserLandmarkItem, AppError>> call(CreateUserLandmarkInput input) {
    return _repository.createLandmark(input);
  }
}
