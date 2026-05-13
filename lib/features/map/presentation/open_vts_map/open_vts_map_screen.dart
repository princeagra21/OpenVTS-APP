import 'dart:async';
import 'dart:ui';
import 'package:open_vts/features/map/domain/entities/map_vehicle_point.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_vts/features/map/presentation/open_vts_map/open_vts_map_controller.dart';
import 'package:open_vts/features/map/presentation/providers/map_telemetry_provider.dart';
import 'models/map_vehicle_status_filter.dart';
import 'widgets/glass_map_control_button.dart';
import 'widgets/map_layers_sheet.dart';
import 'widgets/map_vehicle_search_results.dart';
import 'widgets/map_status_filter_bar.dart';
import 'widgets/map_settings_sheet.dart';
import 'widgets/map_visual_effects_sheet.dart';
import 'widgets/status_vehicle_bottom_sheet.dart';
import 'widgets/vehicle_details_bottom_sheet.dart';
import 'widgets/vehicle_map_marker.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

part 'open_vts_map_vehicle_helpers.dart';
part 'open_vts_map_animation.dart';
part 'widgets/live_vehicle_marker_layer.dart';

class OpenVtsMapScreen extends ConsumerStatefulWidget {
  const OpenVtsMapScreen({
    super.key,
    this.appBarBuilder,
  });

  final WidgetBuilder? appBarBuilder;

  @override
  ConsumerState<OpenVtsMapScreen> createState() => _OpenVtsMapScreenState();
}

class _OpenVtsMapScreenState extends ConsumerState<OpenVtsMapScreen>
    with TickerProviderStateMixin {
  static const double _defaultMapZoom = OpenVtsMapController.defaultMapZoom;
  static const double _vehicleFocusZoom = OpenVtsMapController.vehicleFocusZoom;
  static const double _followVehicleMinZoom =
      OpenVtsMapController.followVehicleMinZoom;
  final OpenVtsMapController _openVtsMapController = OpenVtsMapController();

  MapController get _mapController => _openVtsMapController.mapController;

  bool _showSearch = false;
  final TextEditingController _vehicleSearchController =
      TextEditingController();
  String _vehicleSearchQuery = '';
  // Adjust based on your CustomBottomBar height

  final LatLng _initialCenter = LatLng(28.6139, 77.2090);

  double _currentZoom = _defaultMapZoom;
  late LatLng _currentCenter;
  List<MapVehiclePoint> _latestLivePoints = const <MapVehiclePoint>[];
  bool _showVehicleLabels = false;
  bool _enableCluster =
      false; // Clustering stays off until a package is integrated.
  bool _enableRippleEffect = true;
  bool _showGeofence = false;
  bool _showPoi = false;
  bool _showRoutes = false;
  bool _isPseudo3D = false;
  bool _showAdvancedMapControls = false;
  MapVisualEffect _visualEffect = MapVisualEffect.none;
  String _selectedTileLayerId = 'osm';
  MapVehicleStatusFilter _selectedStatusFilter = MapVehicleStatusFilter.all;
  String? _selectedVehicleId;
  bool _followSelectedVehicle = false;
  String? _followVehicleImei;
  LatLng? _lastFollowedVehicleLatLng;
  bool _hasAutoFitToMarkers = false;
  bool _hasUserInteractedWithMap = false;

  @override
  void initState() {
    super.initState();
    _currentCenter = _initialCenter;
    _vehicleSearchController.addListener(() {
      if (!mounted) return;
      final next = _vehicleSearchController.text;
      if (next == _vehicleSearchQuery) return;
      updateLocalUiState(this, () => _vehicleSearchQuery = next);
    });
  }

  @override
  void dispose() {
    _vehicleSearchController.dispose();
    super.dispose();
  }

  void _handleLivePointsChanged(List<MapVehiclePoint> points) {
    _latestLivePoints = points;
    _maybeFollowSelectedVehicle();
    _scheduleAutoFitToMarkers();
  }


  double _getCorrectedVehicleHeading(double rawBearing) {
    return _openVtsMapController.correctedVehicleHeading(rawBearing);
  }

  void _zoomIn() {
    final newZoom = (_currentZoom + 1).clamp(3.0, 18.0);
    _mapController.move(_currentCenter, newZoom);
    updateLocalUiState(this, () => _currentZoom = newZoom);
  }

  void _zoomOut() {
    final newZoom = (_currentZoom - 1).clamp(3.0, 18.0);
    _mapController.move(_currentCenter, newZoom);
    updateLocalUiState(this, () => _currentZoom = newZoom);
  }

  void _openSearch() => updateLocalUiState(this, () => _showSearch = true);
  void _closeSearch() {
    updateLocalUiState(this, () {
      _showSearch = false;
      _vehicleSearchQuery = '';
    });
    _vehicleSearchController.clear();
  }

  void _clearVehicleSearch() {
    if (_vehicleSearchController.text.isEmpty && _vehicleSearchQuery.isEmpty) {
      return;
    }
    _vehicleSearchController.clear();
    if (!mounted) return;
    updateLocalUiState(this, () => _vehicleSearchQuery = '');
  }

  void _togglePseudo3D() {
    updateLocalUiState(this, () => _isPseudo3D = !_isPseudo3D);
  }

  void _toggleAdvancedMapControls() {
    updateLocalUiState(this, () => _showAdvancedMapControls = !_showAdvancedMapControls);
  }

  void _stopFollowingVehicle() {
    updateLocalUiState(this, () {
      _followSelectedVehicle = false;
      _followVehicleImei = null;
      _lastFollowedVehicleLatLng = null;
    });
  }

  MapVehiclePoint? _followedVehiclePoint({List<MapVehiclePoint>? points}) {
    final imei = _followVehicleImei?.trim();
    if (imei == null || imei.isEmpty) return null;
    for (final point in points ?? _latestLivePoints) {
      if (point.imei.trim() == imei) return point;
    }
    return null;
  }

  void _maybeFollowSelectedVehicle() {
    if (!_followSelectedVehicle) return;

    final vehicle = _followedVehiclePoint();
    final latLng = vehicle == null ? null : _getVehicleLatLng(vehicle);
    if (latLng == null) return;

    final last = _lastFollowedVehicleLatLng;
    if (last != null && _isSameLatLngCloseEnough(last, latLng)) {
      return;
    }

    final targetZoom = _currentZoom < _followVehicleMinZoom
        ? _vehicleFocusZoom
        : _currentZoom;
    _lastFollowedVehicleLatLng = latLng;

    if (_currentCenter.latitude != latLng.latitude ||
        _currentCenter.longitude != latLng.longitude ||
        _currentZoom != targetZoom) {
      _mapController.move(latLng, targetZoom);
      _currentCenter = latLng;
      _currentZoom = targetZoom;
    }
  }

  bool _isSameLatLngCloseEnough(LatLng a, LatLng b) {
    return _openVtsMapController.isSameLatLngCloseEnough(a, b);
  }

  void _scheduleAutoFitToMarkers() {
    if (_hasAutoFitToMarkers ||
        _hasUserInteractedWithMap ||
        _followSelectedVehicle ||
        _vehicleSearchQuery.trim().isNotEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _hasAutoFitToMarkers ||
          _hasUserInteractedWithMap ||
          _followSelectedVehicle ||
          _vehicleSearchQuery.trim().isNotEmpty) {
        return;
      }

      final validPoints = _latestLivePoints
          .where((point) => _isValidVehicleLocation(point))
          .toList();
      if (validPoints.isEmpty) return;

      if (validPoints.length == 1) {
        final single = validPoints.first;
        final latLng = _getVehicleLatLng(single);
        if (latLng == null) return;
        final targetZoom = _currentZoom < _followVehicleMinZoom
            ? _vehicleFocusZoom
            : _currentZoom;
        _mapController.move(latLng, targetZoom);
        _currentCenter = latLng;
        _currentZoom = targetZoom;
      } else {
        final bounds = LatLngBounds.fromPoints(
          validPoints.map((point) => LatLng(point.lat, point.lng)).toList(),
        );
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(56)),
        );
      }

      _hasAutoFitToMarkers = true;
    });
  }

  Future<void> _onStatusChipTapped(MapVehicleStatusFilter filter) async {
    if (!mounted) return;
    updateLocalUiState(this, () => _selectedStatusFilter = filter);

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
          onVehicleLabelsChanged: (value) =>
              updateLocalUiState(this, () => _showVehicleLabels = value),
          onClusterChanged: (value) => updateLocalUiState(this, () => _enableCluster = value),
          onRippleEffectChanged: (value) =>
              updateLocalUiState(this, () => _enableRippleEffect = value),
          onGeofenceChanged: (value) => updateLocalUiState(this, () => _showGeofence = value),
          onPoiChanged: (value) => updateLocalUiState(this, () => _showPoi = value),
          onRoutesChanged: (value) => updateLocalUiState(this, () => _showRoutes = value),
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
    updateLocalUiState(this, () => _visualEffect = effect);
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
    updateLocalUiState(this, () => _selectedTileLayerId = option.id);
  }

  ColorFilter? _mapColorFilter() {
    if (_isPseudo3D) {
      return mapVisualEffectFilter(MapVisualEffect.none, pseudo3d: true);
    }
    return mapVisualEffectFilter(_visualEffect);
  }

  String _tileUrlTemplate() => _selectedTileOption.urlTemplate;

  List<String> _tileSubdomains() => _selectedTileOption.subdomains;


  List<MapVehiclePoint> _searchedVehicles({List<MapVehiclePoint>? points}) {
    final query = _vehicleSearchQuery.trim();
    if (query.isEmpty) return const [];
    return _getVehiclesForFilter(
      _selectedStatusFilter,
      includeInvalid: true,
      searchQuery: query,
      points: points,
    );
  }


  List<MapVehiclePoint> _getVehiclesForFilter(
    MapVehicleStatusFilter filter, {
    required bool includeInvalid,
    String? searchQuery,
    List<MapVehiclePoint>? points,
  }) {
    final q = (searchQuery ?? _vehicleSearchQuery).trim().toLowerCase();
    final source = points ?? _latestLivePoints;
    return source.where((point) {
      if (!includeInvalid && !point.hasValidPoint) return false;
      if (filter != MapVehicleStatusFilter.all &&
          normalizeMapVehicleStatus(point) != filter) {
        return false;
      }
      if (q.isEmpty) return true;

      return _matchesVehicleSearch(point, q);
    }).toList();
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
    final hasValidLocation = _isValidVehicleLocation(vehicle);
    final position = _getVehicleLatLng(vehicle);
    final id = vehicle.vehicleId.trim();
    final imei = vehicle.imei.trim();

    updateLocalUiState(this, () {
      _selectedVehicleId = id.isEmpty ? null : id;
      _followSelectedVehicle = true;
      _followVehicleImei = imei.isEmpty ? null : imei;
      _lastFollowedVehicleLatLng = hasValidLocation ? position : null;
      _vehicleSearchQuery = '';
      if (hasValidLocation && position != null) {
        _currentCenter = position;
        _currentZoom = _currentZoom < _followVehicleMinZoom
            ? _vehicleFocusZoom
            : _currentZoom;
      }
    });

    _vehicleSearchController.clear();
    FocusScope.of(context).unfocus();

    if (!hasValidLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid location for this vehicle')),
      );
      return;
    }

    if (position != null) {
      final targetZoom = _currentZoom < _followVehicleMinZoom
          ? _vehicleFocusZoom
          : _currentZoom;
      _mapController.move(position, targetZoom);
      _currentCenter = position;
      _currentZoom = targetZoom;
    }
  }

  Future<void> _openVehicleDetailsOnMap(MapVehiclePoint vehicle) async {
    final hasValidLocation = _isValidVehicleLocation(vehicle);
    final position = _getVehicleLatLng(vehicle);
    final id = vehicle.vehicleId.trim();
    final imei = vehicle.imei.trim();

    updateLocalUiState(this, () {
      _selectedVehicleId = id.isEmpty ? null : id;
      _followSelectedVehicle = true;
      _followVehicleImei = imei.isEmpty ? null : imei;
      _lastFollowedVehicleLatLng = hasValidLocation ? position : null;
      if (hasValidLocation && position != null) {
        _currentCenter = position;
        _currentZoom = _currentZoom < _followVehicleMinZoom
            ? _vehicleFocusZoom
            : _currentZoom;
      }
    });

    if (!hasValidLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid location for this vehicle')),
      );
    } else if (position != null) {
      final targetZoom = _currentZoom < _followVehicleMinZoom
          ? _vehicleFocusZoom
          : _currentZoom;
      _mapController.move(position, targetZoom);
      _currentCenter = position;
      _currentZoom = targetZoom;
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
              scrollController: scrollController,
              onClose: () => Navigator.of(sheetContext).pop(),
            );
          },
        );
      },
    );
  }

  void _handleSearchVehicleTap(MapVehiclePoint vehicle) {
    _focusVehicleOnMap(vehicle);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme; // <--- color scheme shortcut
    final mapColorFilter = _mapColorFilter();

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // ---------------- MAP ----------------
          Positioned.fill(
            child: Builder(
              builder: (context) {
                final tileLayer = TileLayer(
                  urlTemplate: _tileUrlTemplate(),
                  subdomains: _tileSubdomains(),
                  userAgentPackageName: 'com.openvts.app',
                  tileProvider: NetworkTileProvider(
                    cachingProvider: const DisabledMapCachingProvider(),
                  ),
                );

                Widget map = RepaintBoundary(
                  child: FlutterMap(
                    mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: _defaultMapZoom,
                    minZoom: 3,
                    maxZoom: 18,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                    onTap: (tapPos, latlng) {
                      AppLogger.debug('Tapped: $latlng');
                    },
                    onPositionChanged: (camera, hasGesture) {
                      _currentCenter = camera.center;
                      _currentZoom = camera.zoom;
                      if (hasGesture) {
                        _hasUserInteractedWithMap = true;
                      }
                      if (hasGesture && _followSelectedVehicle) {
                        _stopFollowingVehicle();
                      }
                      if (mounted) updateLocalUiState(this, () {});
                    },
                  ),
                  children: [
                    mapColorFilter != null
                        ? ColorFiltered(
                            colorFilter: mapColorFilter,
                            child: tileLayer,
                          )
                        : tileLayer,
                    if (_showGeofence) const SizedBox.shrink(),
                    if (_showPoi) const SizedBox.shrink(),
                    if (_showRoutes) const SizedBox.shrink(),
                    Consumer(
                      builder: (context, ref, _) {
                        final livePoints = ref.watch(liveMapVehiclePointsProvider);
                        final pointsToRender = _getVehiclesForFilter(
                          _selectedStatusFilter,
                          includeInvalid: false,
                          points: livePoints,
                        );
                        return LiveVehicleMarkerLayer(
                          points: pointsToRender,
                          allPoints: livePoints,
                          showVehicleLabels: _showVehicleLabels,
                          enableRippleEffect: _enableRippleEffect,
                          selectedVehicleId: _selectedVehicleId,
                          correctedHeading: _getCorrectedVehicleHeading,
                          markerColor: _vehicleMarkerColor,
                          markerAssetPath: _vehicleMarkerAssetPath,
                          markerBaseAssetPath: _vehicleBaseAssetPath,
                          shouldAnimateRipple: _shouldAnimateRipple,
                          onTap: _openVehicleDetailsOnMap,
                          onPointsChanged: _handleLivePointsChanged,
                        );
                      },
                    ),
                  ],
                  ),
                );

                if (_isPseudo3D) {
                  map = Transform.scale(scale: 1.01, child: map);
                }
                return map;
              },
            ),
          ),

          if (widget.appBarBuilder != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: widget.appBarBuilder!(context),
            ),

          if (_vehicleSearchQuery.trim().isEmpty)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              left: 12,
              right: 12,
              top: _showSearch
                  ? AppUtils.appBarHeightCustom + 78
                  : AppUtils.appBarHeightCustom + 14,
              child: Consumer(
                builder: (context, ref, _) {
                  final statusCounts = ref.watch(mapStatusCountsProvider);
                  return MapStatusFilterBar(
                    selectedFilter: _selectedStatusFilter,
                    counts: statusCounts,
                    onChanged: (filter) {
                      unawaited(_onStatusChipTapped(filter));
                    },
                  );
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
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      if (_showAdvancedMapControls) ...[
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
                      const SizedBox(height: 12),
                      glassMapControlButton(
                        context: context,
                        child: Icon(
                          _showAdvancedMapControls
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.more_horiz_rounded,
                        ),
                        borderRadiusValue: _showAdvancedMapControls ? 0 : 9,
                        backgroundColor: _showAdvancedMapControls
                            ? Colors.transparent
                            : null,
                        borderColorOverride: _showAdvancedMapControls
                            ? Colors.transparent
                            : null,
                        showShadow: !_showAdvancedMapControls,
                        showBorder: !_showAdvancedMapControls,
                        blurSigma: _showAdvancedMapControls ? 0 : 2.5,
                        onPressed: _toggleAdvancedMapControls,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ---------------- SEARCH OVERLAY ----------------
          if (_showSearch)
            Positioned(
              left: 12,
              right: 12,
              top:
                  MediaQuery.of(context).padding.top +
                  AppUtils.appBarHeightCustom +
                  12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 55,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: cs.onSurface.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _vehicleSearchController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: "Search vehicles...",
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: TextStyle(color: cs.onSurface),
                                onSubmitted: (q) {
                                  final results = _searchedVehicles();
                                  if (results.length == 1) {
                                    _handleSearchVehicleTap(results.first);
                                  }
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: _vehicleSearchQuery.trim().isEmpty
                                  ? _closeSearch
                                  : _clearVehicleSearch,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cs.onSurface.withValues(alpha: 0.1),
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
                  if (_vehicleSearchQuery.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Consumer(
                      builder: (context, ref, _) {
                        final livePoints = ref.watch(liveMapVehiclePointsProvider);
                        return MapVehicleSearchResultsPanel(
                          vehicles: _searchedVehicles(points: livePoints),
                          onVehicleTap: _handleSearchVehicleTap,
                          titleBuilder: _vehicleDisplayName,
                          statusTextBuilder: (vehicle) =>
                              normalizeMapVehicleStatus(vehicle).label,
                          identifierBuilder: (vehicle) {
                            final plate = vehicle.plateNumber.trim();
                            if (plate.isNotEmpty) return plate;
                            final imei = vehicle.imei.trim();
                            if (imei.isNotEmpty) return imei;
                            return '–';
                          },
                          speedBuilder: _formatSpeed,
                          statusColorBuilder: (vehicle) =>
                              _vehicleMarkerColor(vehicle, isSelected: false),
                          hasLocationBuilder: _isValidVehicleLocation,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

          if (_followSelectedVehicle)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Consumer(
                builder: (context, ref, _) {
                  final livePoints = ref.watch(liveMapVehiclePointsProvider);
                  return _buildFollowingChip(
                    vehicle: _followedVehiclePoint(points: livePoints),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFollowingChip({MapVehiclePoint? vehicle}) {
    final cs = Theme.of(context).colorScheme;
    final title = vehicle != null
        ? _vehicleDisplayName(vehicle)
        : (_followVehicleImei?.isNotEmpty == true
              ? 'Waiting for vehicle update...'
              : 'Following vehicle');
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.gps_fixed_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.96),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Following $title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _stopFollowingVehicle,
                borderRadius: BorderRadius.circular(999),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: cs.onInverseSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
