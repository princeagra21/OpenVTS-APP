import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/superadmin/di/superadmin_providers.dart';
import 'package:open_vts/features/superadmin/presentation/state/superadmin_dashboard_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'superadmin_riverpod_providers.g.dart';

@riverpod
class SuperadminDashboardNotifier extends _$SuperadminDashboardNotifier {
  @override
  SuperadminDashboardState build() => const SuperadminDashboardState.initial();

  Future<void> load() async {
    state = const SuperadminDashboardState.loading();
    final result = await ref.read(getSuperadminDashboardUseCaseProvider)();
    state = result.when(
      success: (dashboard) => SuperadminDashboardState.loaded(dashboard: dashboard),
      failure: SuperadminDashboardState.error,
    );
  }
}
