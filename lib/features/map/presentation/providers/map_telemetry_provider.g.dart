// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_telemetry_provider.dart';

typedef TelemetryParserRef = AutoDisposeProviderRef<TelemetryParser>;
final telemetryParserProvider = AutoDisposeProvider<TelemetryParser>(telemetryParser);

typedef TelemetryBackpressurePolicyRef = AutoDisposeProviderRef<TelemetryBackpressurePolicy>;
final telemetryBackpressurePolicyProvider = AutoDisposeProvider<TelemetryBackpressurePolicy>(telemetryBackpressurePolicy);

final mapTelemetryNotifierProvider = AutoDisposeNotifierProvider<MapTelemetryNotifier, VehicleMarkerState>(MapTelemetryNotifier.new);

typedef _$MapTelemetryNotifier = AutoDisposeNotifier<VehicleMarkerState>;

typedef SelectedVehicleTelemetryRef = AutoDisposeProviderRef<TelemetryPoint?>;
final selectedVehicleTelemetryProvider = AutoDisposeProviderFamily<TelemetryPoint?, String>(selectedVehicleTelemetry);
