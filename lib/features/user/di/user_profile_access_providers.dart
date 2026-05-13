import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/repository_providers.dart' as legacy_repositories;
import 'package:open_vts/core/utils/app_cancellation.dart';
import 'package:open_vts/features/user/data/repositories/user_profile_repository.dart';

class UserProfileAccess {
  const UserProfileAccess(this._repository);

  final UserProfileRepository _repository;

  Future<dynamic> getMyProfile({AppCancellationHandle? cancelToken}) {
    return _repository.getMyProfile(cancelToken: cancelToken);
  }
}

final userProfileAccessProvider = Provider<UserProfileAccess>((ref) {
  return UserProfileAccess(
    ref.read(legacy_repositories.userProfileRepositoryProvider),
  );
});
