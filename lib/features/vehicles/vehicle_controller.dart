import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/features/vehicles/vehicle_models.dart';
import 'package:open_vts/features/vehicles/vehicle_repository.dart';
import 'package:open_vts/features/vehicles/vehicle_role_config.dart';

/// Controller for vehicle list operations
class VehicleController extends ChangeNotifier {
  VehicleController({
    required this.config,
    required this.repository,
  });

  final VehicleRoleConfig config;
  final VehicleRepository repository;

  VehicleListState _state = const VehicleListState();
  VehicleListState get state => _state;

  final TextEditingController searchController = TextEditingController();
  Timer? _searchDebounce;
  CancelToken? _loadToken;

  @override
  void dispose() {
    _loadToken?.cancel('Controller disposed');
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void initialize() {
    searchController.addListener(_onSearchChanged);
    loadVehicles();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      loadVehicles();
    });
  }

  Future<void> loadVehicles() async {
    _loadToken?.cancel('Reload vehicles');
    final token = CancelToken();
    _loadToken = token;

    _updateState(_state.copyWith(loading: true, errorMessage: null));

    try {
      final request = VehicleListRequest(
        search: searchController.text.trim().isEmpty ? null : searchController.text.trim(),
        status: _getStatusForTab(_state.selectedTab),
      );

      final result = await repository.getVehicles(request, token);
      if (token.isCancelled) return;

      await result.when(
        success: (items) async {
          var vehicles = items;

          // Merge telemetry if available and permitted
          if (config.permissions.canViewTelemetry && config.telemetryEndpoint != null) {
            final telemetryResult = await repository.getTelemetry(token);
            if (!token.isCancelled) {
              vehicles = telemetryResult.when(
                success: (telemetry) => _mergeTelemetry(items, telemetry),
                failure: (_) => items,
              );
            }
          }

          _updateState(_state.copyWith(
            items: vehicles,
            loading: false,
          ));
        },
        failure: (error) {
          _updateState(_state.copyWith(
            loading: false,
            errorMessage: _getErrorMessage(error),
          ));
        },
      );
    } catch (error) {
      if (!token.isCancelled) {
        _updateState(_state.copyWith(
          loading: false,
          errorMessage: 'Failed to load vehicles',
        ));
      }
    }
  }

  void setSelectedTab(String tab) {
    if (_state.selectedTab != tab) {
      _updateState(_state.copyWith(selectedTab: tab));
      loadVehicles();
    }
  }

  Future<void> refresh() async {
    await loadVehicles();
  }

  void _updateState(VehicleListState newState) {
    _state = newState;
    notifyListeners();
  }

  String? _getStatusForTab(String tab) {
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

  List<VehicleItem> _mergeTelemetry(List<VehicleItem> vehicles, List<Map<String, dynamic>> telemetry) {
    final telemetryMap = {for (final t in telemetry) t['vehicleId']?.toString() ?? '': t};

    return vehicles.map((vehicle) {
      final telemetryData = telemetryMap[vehicle.id];
      if (telemetryData != null) {
        // Merge telemetry data into vehicle raw data
        final mergedRaw = Map<String, dynamic>.from(vehicle.raw)..addAll(telemetryData);
        return VehicleItem(mergedRaw);
      }
      return vehicle;
    }).toList();
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception && error.toString().contains('401')) {
      return 'Not authorized to view vehicles';
    }
    if (error is Exception && error.toString().contains('403')) {
      return 'Access denied to vehicles';
    }
    return 'Failed to load vehicles';
  }
}