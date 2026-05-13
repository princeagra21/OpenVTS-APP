import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/di/admin_team_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_form_input.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_team_repository.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_team_list_controller.dart';

void main() {
  test('loadTeams populates list state', () async {
    final container = ProviderContainer(overrides: [
      adminTeamRepositoryProvider.overrideWithValue(_FakeAdminTeamRepository()),
    ]);
    addTearDown(container.dispose);

    await container.read(adminTeamListControllerProvider.notifier).loadTeams();

    final state = container.read(adminTeamListControllerProvider);
    expect(state.items.single.fullName, 'Ops Team');
    expect(state.isLoading, isFalse);
  });

  test('updateStatus rolls back on failure', () async {
    final repo = _FakeAdminTeamRepository(updateResult: const Result.failure(ServerError('Denied')));
    final container = ProviderContainer(overrides: [adminTeamRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    await container.read(adminTeamListControllerProvider.notifier).loadTeams();
    final item = container.read(adminTeamListControllerProvider).items.single;
    final ok = await container.read(adminTeamListControllerProvider.notifier).updateStatus(item, false);

    final state = container.read(adminTeamListControllerProvider);
    expect(ok, isFalse);
    expect(state.items.single.isActive, isTrue);
    expect(state.errorMessage, 'Denied');
  });
}

class _FakeAdminTeamRepository implements AdminTeamRepository {
  _FakeAdminTeamRepository({this.updateResult = const Result.success(null)});
  final Result<void, AppError> updateResult;

  @override
  Future<Result<List<AdminTeamListItem>, AppError>> getTeams({String? search, int? page, int? limit}) async {
    return Result.success([AdminTeamListItem.fromRaw({'id': 't1', 'name': 'Ops Team', 'isActive': true})]);
  }

  @override
  Future<Result<AdminTeamListItem, AppError>> getTeamDetail(String teamId) async => Result.success(AdminTeamListItem.fromRaw({'id': teamId}));

  @override
  Future<Result<void, AppError>> updateTeamStatus(String teamId, bool isActive) async => updateResult;

  @override
  Future<Result<void, AppError>> updateTeamPassword(String teamId, String password) async => const Result.success(null);

  @override
  Future<Result<void, AppError>> updateTeam({required String teamId, required String name, required String email, required String mobilePrefix, required String mobileNumber, required String username}) async => const Result.success(null);

  @override
  Future<Result<void, AppError>> createTeam(CreateAdminTeamInput input) async => const Result.success(null);
}
