// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_telemetry_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$telemetryParserHash() => r'54cd0ce9bf0cc1639840b1197ca70bf00626ace9';

/// See also [telemetryParser].
@ProviderFor(telemetryParser)
final telemetryParserProvider = AutoDisposeProvider<TelemetryParser>.internal(
  telemetryParser,
  name: r'telemetryParserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$telemetryParserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TelemetryParserRef = AutoDisposeProviderRef<TelemetryParser>;
String _$telemetryBackpressurePolicyHash() =>
    r'5f9a8610a2893a3fc57d6697385115ce0d392fbc';

/// See also [telemetryBackpressurePolicy].
@ProviderFor(telemetryBackpressurePolicy)
final telemetryBackpressurePolicyProvider =
    AutoDisposeProvider<TelemetryBackpressurePolicy>.internal(
  telemetryBackpressurePolicy,
  name: r'telemetryBackpressurePolicyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$telemetryBackpressurePolicyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TelemetryBackpressurePolicyRef
    = AutoDisposeProviderRef<TelemetryBackpressurePolicy>;
String _$selectedVehicleTelemetryHash() =>
    r'a8b43a8dc6922dfe4307fb0b7c19834e08084950';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [selectedVehicleTelemetry].
@ProviderFor(selectedVehicleTelemetry)
const selectedVehicleTelemetryProvider = SelectedVehicleTelemetryFamily();

/// See also [selectedVehicleTelemetry].
class SelectedVehicleTelemetryFamily extends Family<TelemetryPoint?> {
  /// See also [selectedVehicleTelemetry].
  const SelectedVehicleTelemetryFamily();

  /// See also [selectedVehicleTelemetry].
  SelectedVehicleTelemetryProvider call(
    String imei,
  ) {
    return SelectedVehicleTelemetryProvider(
      imei,
    );
  }

  @override
  SelectedVehicleTelemetryProvider getProviderOverride(
    covariant SelectedVehicleTelemetryProvider provider,
  ) {
    return call(
      provider.imei,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'selectedVehicleTelemetryProvider';
}

/// See also [selectedVehicleTelemetry].
class SelectedVehicleTelemetryProvider
    extends AutoDisposeProvider<TelemetryPoint?> {
  /// See also [selectedVehicleTelemetry].
  SelectedVehicleTelemetryProvider(
    String imei,
  ) : this._internal(
          (ref) => selectedVehicleTelemetry(
            ref as SelectedVehicleTelemetryRef,
            imei,
          ),
          from: selectedVehicleTelemetryProvider,
          name: r'selectedVehicleTelemetryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$selectedVehicleTelemetryHash,
          dependencies: SelectedVehicleTelemetryFamily._dependencies,
          allTransitiveDependencies:
              SelectedVehicleTelemetryFamily._allTransitiveDependencies,
          imei: imei,
        );

  SelectedVehicleTelemetryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.imei,
  }) : super.internal();

  final String imei;

  @override
  Override overrideWith(
    TelemetryPoint? Function(SelectedVehicleTelemetryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SelectedVehicleTelemetryProvider._internal(
        (ref) => create(ref as SelectedVehicleTelemetryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        imei: imei,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<TelemetryPoint?> createElement() {
    return _SelectedVehicleTelemetryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SelectedVehicleTelemetryProvider && other.imei == imei;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, imei.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SelectedVehicleTelemetryRef on AutoDisposeProviderRef<TelemetryPoint?> {
  /// The parameter `imei` of this provider.
  String get imei;
}

class _SelectedVehicleTelemetryProviderElement
    extends AutoDisposeProviderElement<TelemetryPoint?>
    with SelectedVehicleTelemetryRef {
  _SelectedVehicleTelemetryProviderElement(super.provider);

  @override
  String get imei => (origin as SelectedVehicleTelemetryProvider).imei;
}

String _$mapTelemetryNotifierHash() =>
    r'd5953a766a9fe5bfb9aaa4380bc6a209bbddb1d2';

/// See also [MapTelemetryNotifier].
@ProviderFor(MapTelemetryNotifier)
final mapTelemetryNotifierProvider = AutoDisposeNotifierProvider<
    MapTelemetryNotifier, VehicleMarkerState>.internal(
  MapTelemetryNotifier.new,
  name: r'mapTelemetryNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mapTelemetryNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MapTelemetryNotifier = AutoDisposeNotifier<VehicleMarkerState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
