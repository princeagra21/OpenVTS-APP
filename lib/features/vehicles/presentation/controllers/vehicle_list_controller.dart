import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/vehicles/di/vehicles_providers.dart';
import 'package:open_vts/features/vehicles/domain/config/vehicle_role_config.dart';
import 'package:open_vts/features/vehicles/domain/permissions/vehicle_permissions.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_list_state.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_models.dart';
import 'package:open_vts/features/vehicles/domain/use_cases/get_vehicles_use_case.dart';

final selectedVehicleRoleProvider = StateProvider<VehicleRole?>((ref) => null);

final vehicleListControllerProvider = StateNotifierProvider.autoDispose
    .family<VehicleListController, VehicleListState, VehicleRoleConfig>((ref, config) {
  return VehicleListController(
    config: config,
    getVehiclesUseCase: ref.watch(getVehiclesUseCaseProvider),
  )..loadVehicles();
});

class VehicleListController extends StateNotifier<VehicleListState> {
  VehicleListController({
    required this.config,
    required GetVehiclesUseCase getVehiclesUseCase,
  }) : _getVehiclesUseCase = getVehiclesUseCase,
       super(const VehicleListState());

  final VehicleRoleConfig config;
  final GetVehiclesUseCase _getVehiclesUseCase;
  Timer? _searchDebounce;
  int _requestVersion = 0;

  Future<void> loadVehicles() async {
    final version = ++_requestVersion;
    state = state.copyWith(
      isLoading: state.vehicles.isEmpty,
      isRefreshing: state.vehicles.isNotEmpty,
      errorMessage: null,
      statusFilter: _statusForTab(state.selectedTab),
    );

    final result = await _getVehiclesUseCase(
      search: state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim(),
      status: state.statusFilter,
    );
    if (!mounted || version != _requestVersion) return;

    result.when(
      success: (page) {
        final vehicles = page.data
            .map((vehicle) => VehicleItem(vehicle.raw))
            .toList(growable: false);
        state = state.copyWith(
          vehicles: vehicles,
          isLoading: false,
          isRefreshing: false,
          errorMessage: null,
        );
      },
      failure: (error) {
        final message = _errorMessage(error);
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: message,
          effect: VehicleListEffect.error(message),
        );
      },
    );
  }

  Future<void> refresh() => loadVehicles();

  void setSearchQuery(String value) {
    if (state.searchQuery == value) return;
    state = state.copyWith(searchQuery: value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), loadVehicles);
  }

  void setSelectedTab(String tab) {
    if (state.selectedTab == tab) return;
    state = state.copyWith(selectedTab: tab, statusFilter: _statusForTab(tab));
    unawaited(loadVehicles());
  }

  void setStatusFilter(String? value) {
    if (state.statusFilter == value) return;
    state = state.copyWith(statusFilter: value);
    unawaited(loadVehicles());
  }

  void clearError() => state = state.copyWith(errorMessage: null);
  void clearEffect() => state = state.copyWith(effect: null);

  String? _statusForTab(String tab) {
    switch (tab) {
      case 'Running':
        return 'running';
      case 'Stopped':
        return 'stopped';
      case 'Active':
        return 'active';
      case 'Inactive':
        return 'inactive';
      default:
        return null;
    }
  }

  String _errorMessage(Object error) {
    final text = error.toString();
    if (text.contains('401')) return 'Not authorized to view vehicles';
    if (text.contains('403')) return 'Access denied to vehicles';
    return 'Failed to load vehicles';
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
