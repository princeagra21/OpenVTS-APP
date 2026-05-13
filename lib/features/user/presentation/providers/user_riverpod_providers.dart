import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/user/di/user_providers.dart';
import 'package:open_vts/features/user/presentation/state/user_dashboard_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_riverpod_providers.g.dart';

@riverpod
class UserDashboardNotifier extends _$UserDashboardNotifier {
  @override
  UserDashboardState build() => const UserDashboardState.initial();

  Future<void> load() async {
    state = const UserDashboardState.loading();
    final result = await ref.read(getUserDashboardUseCaseProvider)();
    state = result.when(
      success: (dashboard) => UserDashboardState.loaded(dashboard: dashboard),
      failure: UserDashboardState.error,
    );
  }
}
