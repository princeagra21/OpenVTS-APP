import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/map_vehicle_point.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../../layout/app_layout.dart';
import 'models/map_vehicle_status_filter.dart';
import 'widgets/glass_map_control_button.dart';
import 'widgets/map_layers_sheet.dart';
import 'widgets/map_status_filter_bar.dart';
import 'widgets/map_settings_sheet.dart';
import 'widgets/map_visual_effects_sheet.dart';
import 'widgets/status_vehicle_bottom_sheet.dart';
import 'widgets/vehicle_details_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {
  static const double vehicleAssetHeadingOffset = 180;
  final MapController _mapController = MapController();

  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  // Adjust based on your CustomBottomBar height

  final LatLng _initialCenter = LatLng(28.6139, 77.2090);

  double _currentZoom = 13.0;
  late LatLng _currentCenter;
  List<MapVehiclePoint> _points = const [];
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;
  ApiClient? _api;
  SuperadminRepository? _repo;
  Timer? _refreshTimer;
  static const bool _liveRefreshEnabled = true;
  final Map<String, _AnimatedVehicleMarker> _vehicleMarkers = {};
  bool _showVehicleLabels = false;
  bool _enableCluster = false; // TODO: integrate a clustering package when available.
  bool _enableRippleEffect = true;
  bool _showGeofence = false;
  bool _showPoi = false;
  bool _showRoutes = false;
  bool _isPseudo3D = false;
  MapVisualEffect _visualEffect = MapVisualEffect.none;
  String _selectedTileLayerId = 'osm';
  MapVehicleStatusFilter _selectedStatusFilter = MapVehicleStatusFilter.all;
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _currentCenter = _initialCenter;
    _searchController.addListener(() {
      if (!mounted) return;
      final next = _searchController.text;
      if (next == _query) return;
      setState(() => _query = next);
    });
    _loadTelemetry();
    if (_liveRefreshEnabled) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        if (!mounted) return;
        _loadTelemetry();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _token?.cancel('MapScreen disposed');
    for (final marker in _vehicleMarkers.values) {
      marker.stopAndDisposeController();
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTelemetry() async {
    if (_loading) return;
    _token?.cancel('Reload map telemetry');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getMapTelemetry(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (items) {
          if (!mounted) return;
          setState(() {
            _points = items;
            _loading = false;
            _errorShown = false;
          });
          _updateTelemetry(_points.where((e) => e.hasValidPoint).toList());
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load map telemetry.'
              : "Couldn't load map data.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't load map data.")));
    }
  }

  void _updateTelemetry(List<MapVehiclePoint> points) {
    final nextIds = points.map((e) => e.vehicleId.trim()).where((e) => e.isNotEmpty).toSet();
    final existingIds = _vehicleMarkers.keys.toSet();

    for (final id in existingIds.difference(nextIds)) {
      _disposeVehicleMarker(id);
    }

    for (final point in points) {
      final id = point.vehicleId.trim();
      if (id.isEmpty) continue;

      final nextPosition = LatLng(point.lat, point.lng);
      final marker = _vehicleMarkers[id];

      if (marker == null) {
        _vehicleMarkers[id] = _AnimatedVehicleMarker(
          position: nextPosition,
          bearing: _getCorrectedVehicleHeading(point.heading ?? 0),
        );
        continue;
      }

      final currentPosition = marker.currentPosition;
      final rawBearing = _calculateBearing(currentPosition, nextPosition);
      final correctedBearing = _getCorrectedVehicleHeading(rawBearing);
      final needsMove = currentPosition.latitude != nextPosition.latitude ||
          currentPosition.longitude != nextPosition.longitude;

      if (!needsMove) {
        marker.bearing = correctedBearing;
        continue;
      }

      final token = marker.bumpToken();
      marker.stopAndDisposeController();
      marker.bearing = correctedBearing;

      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );
      final animation = LatLngTween(
        begin: currentPosition,
        end: nextPosition,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
      marker.controller = controller;
      marker.animation = animation;

      controller.addListener(() {
        if (!mounted || _vehicleMarkers[id]?.token != token) return;
        setState(() {
          marker.position = animation.value;
        });
      });

      controller.addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        if (!mounted || _vehicleMarkers[id]?.token != token) return;
        setState(() {
          marker.position = nextPosition;
          marker.bearing = correctedBearing;
          marker.stopAndDisposeController();
        });
      });

      controller.forward();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _disposeVehicleMarker(String id) {
    final marker = _vehicleMarkers.remove(id);
    marker?.stopAndDisposeController();
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180.0;
    final lon1 = from.longitude * math.pi / 180.0;
    final lat2 = to.latitude * math.pi / 180.0;
    final lon2 = to.longitude * math.pi / 180.0;

    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x) * 180.0 / math.pi;
    return _normalizeDegrees(bearing);
  }

  double _normalizeDegrees(double degrees) {
    final value = degrees % 360;
    return value < 0 ? value + 360 : value;
  }

  double _getCorrectedVehicleHeading(double rawBearing) {
    return _normalizeDegrees(rawBearing + vehicleAssetHeadingOffset);
  }

  void _zoomIn() {
    final newZoom = (_currentZoom + 1).clamp(3.0, 18.0);
    _mapController.move(_currentCenter, newZoom);
    setState(() => _currentZoom = newZoom);
  }

  void _zoomOut() {
    final newZoom = (_currentZoom - 1).clamp(3.0, 18.0);
    _mapController.move(_currentCenter, newZoom);
    setState(() => _currentZoom = newZoom);
  }

  void _openSearch() => setState(() => _showSearch = true);
  void _closeSearch() {
    setState(() => _showSearch = false);
    _searchController.clear();
  }

  void _togglePseudo3D() {
    setState(() => _isPseudo3D = !_isPseudo3D);
  }

  Future<void> _onStatusChipTapped(MapVehicleStatusFilter filter) async {
    if (!mounted) return;
    setState(() => _selectedStatusFilter = filter);

    final selectedVehicle = await _showStatusVehiclesBottomSheet(filter);
    if (!mounted || selectedVehicle == null) return;
    _focusVehicleOnMap(selectedVehicle);
  }

  MapTileOption get _selectedTileOption {
    return kMapTileOptions.firstWhere(
      (option) => option.id == _selectedTileLayerId,
      orElse: () => kMapTileOptions.first,
    );
  }

  Future<void> _openMapSettingsSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return MapSettingsSheet(
          showVehicleLabels: _showVehicleLabels,
          enableCluster: _enableCluster,
          enableRippleEffect: _enableRippleEffect,
          showGeofence: _showGeofence,
          showPoi: _showPoi,
          showRoutes: _showRoutes,
          onVehicleLabelsChanged: (value) => setState(() => _showVehicleLabels = value),
          onClusterChanged: (value) => setState(() => _enableCluster = value),
          onRippleEffectChanged: (value) => setState(() => _enableRippleEffect = value),
          onGeofenceChanged: (value) => setState(() => _showGeofence = value),
          onPoiChanged: (value) => setState(() => _showPoi = value),
          onRoutesChanged: (value) => setState(() => _showRoutes = value),
        );
      },
    );
  }

  Future<void> _openVisualEffectsSheet() async {
    if (!mounted) return;
    final effect = await showModalBottomSheet<MapVisualEffect>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return MapVisualEffectsSheet(
          selectedEffect: _visualEffect,
          onSelected: (value) => Navigator.pop(ctx, value),
        );
      },
    );
    if (effect == null || !mounted) return;
    setState(() => _visualEffect = effect);
  }

  Future<void> _openMapLayersSheet() async {
    if (!mounted) return;
    final option = await showModalBottomSheet<MapTileOption>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return MapLayersSheet(
          selectedTileLayerId: _selectedTileLayerId,
          onSelected: (value) => Navigator.pop(ctx, value),
        );
      },
    );
    if (option == null || !mounted) return;
    setState(() => _selectedTileLayerId = option.id);
  }

  ColorFilter? _mapColorFilter() {
    if (_isPseudo3D) {
      return mapVisualEffectFilter(MapVisualEffect.none, pseudo3d: true);
    }
    return mapVisualEffectFilter(_visualEffect);
  }

  String _tileUrlTemplate() => _selectedTileOption.urlTemplate;

  List<String> _tileSubdomains() => _selectedTileOption.subdomains;

  List<MapVehiclePoint> get _filteredPoints {
    return _getVehiclesForFilter(
      _selectedStatusFilter,
      includeInvalid: false,
    );
  }

  MapVehicleStatusCounts get _statusCounts =>
      buildMapVehicleStatusCounts(_points);

  List<MapVehiclePoint> _getVehiclesForFilter(
    MapVehicleStatusFilter filter, {
    required bool includeInvalid,
  }) {
    final q = _query.trim().toLowerCase();
    return _points.where((point) {
      if (!includeInvalid && !point.hasValidPoint) return false;
      if (filter != MapVehicleStatusFilter.all &&
          normalizeMapVehicleStatus(point) != filter) {
        return false;
      }
      if (q.isEmpty) return true;

      final plate = point.plateNumber.toLowerCase();
      final imei = point.imei.toLowerCase();
      final status = point.status.toLowerCase();
      final address = _vehicleAddressText(point).toLowerCase();
      return plate.contains(q) ||
          imei.contains(q) ||
          status.contains(q) ||
          address.contains(q);
    }).toList();
  }

  bool _isValidVehicleLocation(MapVehiclePoint vehicle) {
    return vehicle.hasValidPoint &&
        vehicle.lat.isFinite &&
        vehicle.lng.isFinite &&
        !(vehicle.lat == 0 && vehicle.lng == 0);
  }

  String _getStatusTitle(MapVehicleStatusFilter filter) => filter.label;

  Color _getStatusColor(MapVehicleStatusFilter filter) {
    switch (filter) {
      case MapVehicleStatusFilter.running:
        return Colors.green;
      case MapVehicleStatusFilter.stop:
        return Colors.redAccent;
      case MapVehicleStatusFilter.idle:
        return Colors.orange;
      case MapVehicleStatusFilter.inactive:
        return Colors.grey;
      case MapVehicleStatusFilter.noData:
        return Colors.black87;
      case MapVehicleStatusFilter.all:
        return Colors.black;
    }
  }

  String _vehicleAddressText(MapVehiclePoint point) {
    final raw = point.raw;
    final values = <Object?>[
      raw['fullAddress'],
      raw['address'],
      raw['addressLine'],
      raw['location'],
    ];
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _formatLastSeen(MapVehiclePoint point) {
    final updated = DateTime.tryParse(point.updatedAt);
    if (updated == null) return 'Last update: --';
    final local = updated.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return 'Last update: $day/$month $hh:$mm';
  }

  String _formatSpeed(MapVehiclePoint point) {
    final speed = point.speed;
    if (speed == null) return '-- km/h';
    final rounded = speed % 1 == 0
        ? speed.toStringAsFixed(0)
        : speed.toStringAsFixed(1);
    return '$rounded km/h';
  }

  String? _formatDistance(MapVehiclePoint point) {
    final raw = point.raw;
    final distance = raw['distance'] ?? raw['distanceKm'] ?? raw['drivenKm'];
    if (distance == null) return null;
    final parsed = double.tryParse(distance.toString());
    if (parsed == null) return distance.toString();
    final formatted = parsed % 1 == 0
        ? parsed.toStringAsFixed(0)
        : parsed.toStringAsFixed(1);
    return '$formatted km';
  }

  String _vehicleTitle(MapVehiclePoint point) {
    final title = point.plateNumber.trim();
    if (title.isNotEmpty) return title;
    final imei = point.imei.trim();
    if (imei.isNotEmpty) return imei;
    final id = point.vehicleId.trim();
    if (id.isNotEmpty) return id;
    return 'Vehicle';
  }

  Future<MapVehiclePoint?> _showStatusVehiclesBottomSheet(
    MapVehicleStatusFilter filter,
  ) async {
    if (!mounted) return null;
    final vehicles = _getVehiclesForFilter(filter, includeInvalid: true);

    return showModalBottomSheet<MapVehiclePoint>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatusVehicleBottomSheet(
          filter: filter,
          vehicles: vehicles,
          count: vehicles.length,
          statusColor: _getStatusColor(filter),
          title: _getStatusTitle(filter),
          onVehicleTap: (vehicle) {
            Navigator.of(sheetContext).pop(vehicle);
          },
          titleBuilder: _vehicleTitle,
          lastSeenBuilder: _formatLastSeen,
          speedBuilder: _formatSpeed,
          distanceBuilder: _formatDistance,
          addressBuilder: _vehicleAddressText,
        );
      },
    );
  }

  void _focusVehicleOnMap(MapVehiclePoint vehicle) {
    _openVehicleDetailsOnMap(vehicle);
  }

  Future<void> _openVehicleDetailsOnMap(MapVehiclePoint vehicle) async {
    final hasValidLocation = _isValidVehicleLocation(vehicle);
    final position = _getVehicleLatLng(vehicle);
    final id = vehicle.vehicleId.trim();

    setState(() {
      _selectedVehicleId = id.isEmpty ? null : id;
      if (hasValidLocation && position != null) {
        _currentCenter = position;
        _currentZoom = 16;
      }
    });

    if (!hasValidLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid location for this vehicle')),
      );
    } else if (position != null) {
      _mapController.move(position, 16);
    }

    if (!mounted) return;
    await _showVehicleDetailsSheet(vehicle);
  }

  LatLng? _getVehicleLatLng(MapVehiclePoint vehicle) {
    if (!_isValidVehicleLocation(vehicle)) return null;
    return LatLng(vehicle.lat, vehicle.lng);
  }

  Future<void> _showVehicleDetailsSheet(MapVehiclePoint vehicle) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.58,
          minChildSize: 0.35,
          maxChildSize: 0.80,
          expand: false,
          builder: (context, scrollController) {
            return VehicleDetailsBottomSheet(
              vehicle: vehicle,
              repository: _repo!,
              scrollController: scrollController,
              onClose: () => Navigator.of(sheetContext).pop(),
            );
          },
        );
      },
    );
  }

  bool _isRunningVehicle(MapVehiclePoint point) {
    final status = point.status.toLowerCase();
    final ignition = point.ignition.toLowerCase();
    return (point.speed ?? 0) > 0 ||
        status.contains('run') ||
        status.contains('move') ||
        status.contains('active') ||
        ignition == 'true' ||
        ignition == 'on' ||
        ignition == '1';
  }

  Color _vehicleMarkerColor(MapVehiclePoint point, {required bool isSelected}) {
    if (isSelected) {
      return const Color(0xFF111827);
    }

    switch (normalizeMapVehicleStatus(point)) {
      case MapVehicleStatusFilter.running:
        return const Color(0xFF6B7280);
      case MapVehicleStatusFilter.stop:
        return const Color(0xFFEF4444);
      case MapVehicleStatusFilter.idle:
        return const Color(0xFFF59E0B);
      case MapVehicleStatusFilter.inactive:
        return const Color(0xFF9CA3AF);
      case MapVehicleStatusFilter.noData:
        return const Color(0xFF475569);
      case MapVehicleStatusFilter.all:
        return const Color(0xFF6B7280);
    }
  }

  String _vehicleMarkerAssetPath(MapVehiclePoint point) {
    final type = point.vehicleTypeName.toLowerCase().trim();
    if (type.isEmpty) return 'assets/images/vehicle_icons_named/pickup_truck.png';

    if (type.contains('sedan') || type.contains('saloon')) {
      return 'assets/images/vehicle_icons_named/sedan_car.png';
    }
    if (type.contains('suv') || type.contains('jeep')) {
      return 'assets/images/vehicle_icons_named/suv_car.png';
    }
    if (type.contains('pickup')) {
      return 'assets/images/vehicle_icons_named/pickup_truck.png';
    }
    if (type.contains('fullback')) {
      return 'assets/images/vehicle_icons_named/pickup_truck.png';
    }
    if (type.contains('tank')) {
      return 'assets/images/vehicle_icons_named/tanker_truck.png';
    }
    if (type.contains('box')) {
      return 'assets/images/vehicle_icons_named/box_truck.png';
    }
    if (type.contains('cargo') || type.contains('van')) {
      return 'assets/images/vehicle_icons_named/cargo_van.png';
    }
    if (type.contains('car')) {
      return 'assets/images/vehicle_icons_named/sedan_car.png';
    }
    if (type.contains('truck')) {
      return 'assets/images/vehicle_icons_named/pickup_truck.png';
    }
    return 'assets/images/vehicle_icons_named/pickup_truck.png';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme; // <--- color scheme shortcut
    final pointsToRender = _filteredPoints;
    final mapColorFilter = _mapColorFilter();
    final statusCounts = _statusCounts;
    final markers = pointsToRender.map((p) {
      final id = p.vehicleId.trim();
      if (id.isEmpty) return null;

      final marker = _vehicleMarkers[id] ??
          (_vehicleMarkers[id] = _AnimatedVehicleMarker(
            position: LatLng(p.lat, p.lng),
            bearing: _getCorrectedVehicleHeading(p.heading ?? 0),
          ));
      final isSelected = id == _selectedVehicleId;

      if (!marker.position.latitude.isFinite || !marker.position.longitude.isFinite) {
        marker.position = LatLng(p.lat, p.lng);
      }

      return Marker(
        point: marker.position,
        width: _showVehicleLabels ? 168 : 84,
        height: 84,
        child: VehicleMapMarker(
          key: ValueKey(id),
          vehicleName: p.plateNumber,
          bearing: marker.bearing ?? 0,
          markerColor: _vehicleMarkerColor(p, isSelected: isSelected),
          markerAssetPath: _vehicleMarkerAssetPath(p),
          showLabel: _showVehicleLabels,
          showRipple: _enableRippleEffect && (_isRunningVehicle(p) || isSelected),
          isSelected: isSelected,
          onTap: () {
            _openVehicleDetailsOnMap(p);
          },
        ),
      );
    }).whereType<Marker>().toList();

    return AppLayout(
      title: "MAP",
      subtitle: "Vehicle Locations",
      actionIcons: const [],
      leftAvatarText: "MP",
      showAppBar: false,
      horizontalPadding: 0.0,
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // ---------------- MAP ----------------
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  Widget map = FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _initialCenter,
                      initialZoom: _currentZoom,
                      minZoom: 3,
                      maxZoom: 18,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                      onTap: (tapPos, latlng) {
                        debugPrint("Tapped: $latlng");
                      },
                      onPositionChanged: (camera, hasGesture) {
                        _currentCenter = camera.center;
                        _currentZoom = camera.zoom;
                        if (mounted) setState(() {});
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _tileUrlTemplate(),
                        subdomains: _tileSubdomains(),
                        userAgentPackageName: 'com.example.fleek_stack_mobile',
                        tileProvider: NetworkTileProvider(
                          cachingProvider: const DisabledMapCachingProvider(),
                        ),
                      ),
                      if (_showGeofence) const SizedBox.shrink(),
                      if (_showPoi) const SizedBox.shrink(),
                      if (_showRoutes) const SizedBox.shrink(),
                      MarkerLayer(markers: markers),
                    ],
                  );

                  if (mapColorFilter != null) {
                    map = ColorFiltered(colorFilter: mapColorFilter, child: map);
                  }
                  if (_isPseudo3D) {
                    map = Transform.scale(scale: 1.01, child: map);
                  }
                  return map;
                },
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SuperAdminHomeAppBar(
                title: 'Map',
                leadingIcon: Symbols.map,
                borderRadius: 0,
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              left: 12,
              right: 12,
              top: _showSearch
                  ? AppUtils.appBarHeightCustom + 78
                  : AppUtils.appBarHeightCustom + 14,
              child: MapStatusFilterBar(
                selectedFilter: _selectedStatusFilter,
                counts: statusCounts,
                onChanged: (filter) {
                  unawaited(_onStatusChipTapped(filter));
                },
              ),
            ),

            // ---------------- ACTION BUTTONS ----------------
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height * 0.5 - 132,
              child: Column(
                children: [
                  glassMapControlButton(
                    context: context,
                    child: const Icon(Icons.search),
                    onPressed: _openSearch,
                  ),
                  const SizedBox(height: 12),

                  glassMapControlButton(
                    context: context,
                    child: const Icon(Icons.add),
                    onPressed: _zoomIn,
                  ),
                  const SizedBox(height: 12),

                  glassMapControlButton(
                    context: context,
                    child: const Icon(Icons.remove),
                    onPressed: _zoomOut,
                  ),
                  const SizedBox(height: 12),

                  glassMapControlButton(
                    context: context,
                    child: const Icon(Icons.tune),
                    onPressed: _openMapSettingsSheet,
                  ),
                  const SizedBox(height: 12),

                  glassMapControlButton(
                    context: context,
                    child: const Icon(Icons.auto_fix_high),
                    onPressed: _openVisualEffectsSheet,
                  ),
                  const SizedBox(height: 12),

                  glassMapControlButton(
                    context: context,
                    child: const Icon(Icons.layers_outlined),
                    onPressed: _openMapLayersSheet,
                  ),
                  const SizedBox(height: 12),

                  glassMapControlButton(
                    context: context,
                    width: 44,
                    height: 44,
                    child: Text(_isPseudo3D ? '3D' : '2D'),
                    onPressed: _togglePseudo3D,
                  ),
                ],
              ),
            ),

            // ---------------- SEARCH BAR ----------------
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              top: _showSearch ? AppUtils.appBarHeightCustom + 12 : -120,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      height: 55,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: cs.primary.withOpacity(0.3),
                        ), // active brand border
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: "Search location",
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: cs.onSurface.withOpacity(0.5),
                                ),
                                isDense: true, // optional – reduces padding
                                contentPadding:
                                    EdgeInsets.zero, // optional – tight layout
                              ),
                              style: TextStyle(color: cs.onSurface),
                              onSubmitted: (q) {
                                debugPrint("Searching: $q");
                                _closeSearch();
                              },
                            ),
                          ),

                          GestureDetector(
                            onTap: _closeSearch,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.onSurface.withOpacity(0.1),
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class _AnimatedVehicleMarker {
  _AnimatedVehicleMarker({
    required this.position,
    required this.bearing,
  });

  LatLng position;
  double? bearing;
  int token = 0;
  AnimationController? controller;
  Animation<LatLng>? animation;

  LatLng get currentPosition => animation?.value ?? position;

  int bumpToken() => ++token;

  void stopAndDisposeController() {
    controller?.stop();
    controller?.dispose();
    controller = null;
    animation = null;
  }
}

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required super.begin, required super.end});

  @override
  LatLng lerp(double t) {
    final start = begin ?? end!;
    final finish = end ?? begin!;
    return LatLng(
      start.latitude + (finish.latitude - start.latitude) * t,
      start.longitude + (finish.longitude - start.longitude) * t,
    );
  }
}

class VehicleMapMarker extends StatelessWidget {
  final String vehicleName;
  final double bearing;
  final Color markerColor;
  final String markerAssetPath;
  final bool showLabel;
  final bool showRipple;
  final bool isSelected;
  final VoidCallback onTap;

  const VehicleMapMarker({
    super.key,
    required this.vehicleName,
    required this.bearing,
    required this.markerColor,
    required this.markerAssetPath,
    required this.showLabel,
    required this.showRipple,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelBg = isDark
        ? Colors.black.withValues(alpha: 0.70)
        : Colors.white.withValues(alpha: 0.88);
    final labelText = isDark ? Colors.white : Colors.black;
    final showRipple = this.showRipple;
    final vehicle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: (bearing * math.pi) / 180,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              markerAssetPath,
              width: isSelected ? 60 : 56,
              height: isSelected ? 60 : 56,
              fit: BoxFit.contain,
              color: markerColor,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 88),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: labelBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              vehicleName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: labelText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: showLabel ? 168 : 84,
        height: 84,
        child: VehicleRippleMarker(
          showRipple: showRipple,
          isSelected: isSelected,
          child: vehicle,
        ),
      ),
    );
  }
}

class VehicleRippleMarker extends StatelessWidget {
  final Widget child;
  final bool showRipple;
  final bool isSelected;

  const VehicleRippleMarker({
    super.key,
    required this.child,
    required this.showRipple,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showRipple) {
      return child;
    }
    return _AnimatedVehicleRipple(
      isSelected: isSelected,
      child: child,
    );
  }
}

class _AnimatedVehicleRipple extends StatefulWidget {
  final Widget child;
  final bool isSelected;

  const _AnimatedVehicleRipple({
    required this.child,
    required this.isSelected,
  });

  @override
  State<_AnimatedVehicleRipple> createState() => _AnimatedVehicleRippleState();
}

class _AnimatedVehicleRippleState extends State<_AnimatedVehicleRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildRipple(double progress, Color color) {
    final size = lerpDouble(26, 58, progress)!;
    final opacity = lerpDouble(0.28, 0.0, progress)!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        border: Border.all(
          color: color.withValues(alpha: opacity * 0.75),
          width: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const rippleColor = Color(0xFF4DA3FF);
    final coreSize = widget.isSelected ? 32.0 : 26.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final p1 = _controller.value;
        final p2 = (_controller.value + 0.5) % 1.0;

        return SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _buildRipple(p1, rippleColor),
              _buildRipple(p2, rippleColor),
              Container(
                width: coreSize,
                height: coreSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rippleColor.withValues(alpha: 0.10),
                ),
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}
