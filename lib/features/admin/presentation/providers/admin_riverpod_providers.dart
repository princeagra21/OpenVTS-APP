import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/di/admin_providers.dart';
import 'package:open_vts/features/admin/presentation/state/admin_dashboard_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'admin_riverpod_providers.g.dart';

@riverpod
class AdminDashboardNotifier extends _$AdminDashboardNotifier {
  @override
  AdminDashboardState build() => const AdminDashboardState.initial();

  Future<void> load() async {
    state = const AdminDashboardState.loading();
    final result = await ref.read(getAdminDashboardUseCaseProvider)();
    state = result.when(
      success: (dashboard) => AdminDashboardState.loaded(dashboard: dashboard),
      failure: AdminDashboardState.error,
    );
  }
}
