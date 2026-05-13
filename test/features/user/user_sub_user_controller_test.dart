import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/di/user_sub_user_providers.dart';
import 'package:open_vts/features/user/domain/entities/user_subuser_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_sub_user_repository.dart';
import 'package:open_vts/features/user/presentation/controllers/user_sub_user_list_controller.dart';

void main() {
  test('loads sub-users into controller state', () async {
    final container = ProviderContainer(overrides: [
      userSubUserRepositoryProvider.overrideWithValue(_FakeUserSubUserRepository()),
    ]);
    addTearDown(container.dispose);

    await container.read(userSubUserListControllerProvider.notifier).load();

    final state = container.read(userSubUserListControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.items.single.email, 'qa@example.com');
  });

  test('exposes repository error message', () async {
    final container = ProviderContainer(overrides: [
      userSubUserRepositoryProvider.overrideWithValue(_FakeUserSubUserRepository(fail: true)),
    ]);
    addTearDown(container.dispose);

    await container.read(userSubUserListControllerProvider.notifier).load();

    expect(container.read(userSubUserListControllerProvider).errorMessage, 'Denied');
  });
}

class _FakeUserSubUserRepository implements UserSubUserRepository {
  _FakeUserSubUserRepository({this.fail = false});
  final bool fail;

  @override
  Future<Result<List<UserSubUserItem>, AppError>> getSubUsers({int page = 1, int limit = 10}) async => fail
      ? const Result.failure(ServerError('Denied'))
      : const Result.success(<UserSubUserItem>[UserSubUserItem(<String, dynamic>{'id': 'sub-1', 'email': 'qa@example.com'})]);

  @override
  Future<Result<UserSubUserItem, AppError>> getSubUserDetail(String id) async => Result.success(UserSubUserItem(<String, dynamic>{'id': id}));

  @override
  Future<Result<UserSubUserItem, AppError>> createSubUser(Map<String, Object?> payload) async => Result.success(UserSubUserItem(<String, dynamic>{'id': 'new'}));

  @override
  Future<Result<UserSubUserItem, AppError>> updateSubUser(String id, Map<String, Object?> payload) async => Result.success(UserSubUserItem(<String, dynamic>{'id': id}));

  @override
  Future<Result<void, AppError>> deleteSubUser(String id) async => const Result.success(null);

  @override
  Future<Result<List<Map<String, Object?>>, AppError>> getSubUserVehicles(String id) async => const Result.success(<Map<String, Object?>>[]);

  @override
  Future<Result<void, AppError>> assignVehicle(String id, List<int> vehicleIds) async => const Result.success(null);

  @override
  Future<Result<void, AppError>> unassignVehicle(String id, List<int> vehicleIds) async => const Result.success(null);
}
