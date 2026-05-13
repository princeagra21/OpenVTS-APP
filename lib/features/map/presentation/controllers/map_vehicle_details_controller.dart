import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/map/application/open_vts_map_repository.dart';
import 'package:open_vts/features/map/domain/entities/map_vehicle_point.dart';
import 'package:open_vts/features/map/presentation/providers/open_vts_map_repository_provider.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_details.dart';

class MapVehicleDetailsSheetState {
  const MapVehicleDetailsSheetState({
    required this.loadingDetails,
    required this.resolvingAddress,
    required this.address,
    this.error,
    this.details,
  });

  final bool loadingDetails;
  final bool resolvingAddress;
  final String address;
  final String? error;
  final VehicleDetails? details;

  const MapVehicleDetailsSheetState.loading()
      : loadingDetails = true,
        resolvingAddress = false,
        address = '–',
        error = null,
        details = null;

  MapVehicleDetailsSheetState copyWith({
    bool? loadingDetails,
    bool? resolvingAddress,
    String? address,
    String? error,
    VehicleDetails? details,
    bool clearError = false,
    bool clearDetails = false,
  }) {
    return MapVehicleDetailsSheetState(
      loadingDetails: loadingDetails ?? this.loadingDetails,
      resolvingAddress: resolvingAddress ?? this.resolvingAddress,
      address: address ?? this.address,
      error: clearError ? null : error ?? this.error,
      details: clearDetails ? null : details ?? this.details,
    );
  }
}

class MapVehicleDetailsController
    extends StateNotifier<MapVehicleDetailsSheetState> {
  MapVehicleDetailsController({
    required this.vehicle,
    required this.repository,
  }) : super(const MapVehicleDetailsSheetState.loading()) {
    unawaited(load());
  }

  final MapVehiclePoint vehicle;
  final OpenVtsMapRepository repository;
  int _loadGeneration = 0;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    state = const MapVehicleDetailsSheetState.loading();

    final imei = vehicle.imei.trim();
    if (imei.isEmpty) {
      if (!mounted || generation != _loadGeneration) return;
      state = state.copyWith(
        loadingDetails: false,
        error: 'Unable to load vehicle details',
      );
      return;
    }

    final detailsRes = await repository.getVehicleDetailsByImei(imei);
    if (!mounted || generation != _loadGeneration) return;

    if (detailsRes.isFailure || detailsRes.data == null) {
      state = state.copyWith(
        loadingDetails: false,
        error: 'Unable to load vehicle details',
      );
      return;
    }

    final details = detailsRes.data!;
    final coordinate = _coordinateFromDetails(details);
    final lat = coordinate.$1;
    final lng = coordinate.$2;
    final shouldResolveAddress = _isValidCoordinate(lat, lng);

    state = MapVehicleDetailsSheetState(
      loadingDetails: false,
      resolvingAddress: shouldResolveAddress,
      address: '–',
      details: details,
    );

    if (!shouldResolveAddress) return;

    final addressRes = await repository.reverseGeocode(lat!, lng!);
    if (!mounted || generation != _loadGeneration) return;

    state = state.copyWith(
      resolvingAddress: false,
      address: addressRes.data?.trim().isNotEmpty == true
          ? addressRes.data!.trim()
          : 'Address unavailable',
    );
  }

  (double?, double?) _coordinateFromDetails(VehicleDetails details) {
    final telemetry = details.telemetry;
    final lat = _readDouble(telemetry.latitude);
    final lng = _readDouble(telemetry.longitude);
    return (lat, lng);
  }

  static double? _readDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  static bool _isValidCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat.abs() <= 90 && lng.abs() <= 180 && (lat != 0 || lng != 0);
  }
}

final mapVehicleDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<MapVehicleDetailsController, MapVehicleDetailsSheetState,
        MapVehiclePoint>((ref, vehicle) {
  return MapVehicleDetailsController(
    vehicle: vehicle,
    repository: ref.read(openVtsMapRepositoryProvider),
  );
});
