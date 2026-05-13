import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/vehicles/di/vehicles_providers.dart';
import 'package:open_vts/features/vehicles/presentation/state/vehicle_list_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vehicle_riverpod_providers.g.dart';

@riverpod
class VehicleListNotifier extends _$VehicleListNotifier {
  @override
  VehicleListUiState build() => const VehicleListUiState.initial();

  Future<void> load({int page = 1, int limit = 20, String? search, String? status}) async {
    state = const VehicleListUiState.loading();
    final result = await ref.read(getVehiclesUseCaseProvider)(
      page: page,
      limit: limit,
      search: search,
      status: status,
    );
    state = result.when(
      success: (page) {
        final vehicles = page.data;
        return vehicles.isEmpty
            ? const VehicleListUiState.empty()
            : VehicleListUiState.loaded(vehicles: vehicles, total: page.total);
      },
      failure: VehicleListUiState.error,
    );
  }
}
