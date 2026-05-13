import 'package:open_vts/core/router/route_names.dart';
import 'dart:math' as math;
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/features/user/presentation/components/appbars/user_home_appbar.dart';
import 'package:open_vts/features/user/presentation/screens/landmark/add_buffer_screen.dart';
import 'package:open_vts/features/map/presentation/open_vts_map/widgets/glass_map_control_button.dart';
import 'package:open_vts/features/map/presentation/open_vts_map/widgets/map_layers_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/user/domain/entities/create_user_landmark_input.dart';
import 'package:open_vts/features/user/domain/entities/user_landmark_item.dart';
import 'package:open_vts/features/user/presentation/controllers/user_landmark_controller.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../layout/app_layout.dart';
import 'geofence_models.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

part 'geofence_more_menu.dart';
part 'geofence_sheets.dart';

class GeofenceScreen extends ConsumerStatefulWidget {
  const GeofenceScreen({super.key});

  @override
  ConsumerState<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends ConsumerState<GeofenceScreen> {
  // API reference documentation + Postman confirmed:
  // - GET  /user/geofences
  // - POST /user/geofences
  // - GET  /user/routes
  // - POST /user/routes
  // - GET  /user/pois
  // - POST /user/pois
  final MapController _mapController = MapController();
  // ---- MAP STATE ----
  final LatLng _initialCenter = LatLng(28.6139, 77.2090);
  late LatLng _currentCenter;
  static const double _defaultMapZoom = 13.0;
  static const double _focusMapZoom = 16.0;
  double _currentZoom = _defaultMapZoom;
  // ---- GEOFENCE STATE ----
  bool _isAddingGeofence = false;
  GeofenceType? _pendingGeofenceType;
  final List<LatLng> _tempPoints = [];
  Geofence? _selectedLandmark;
  final LayerHitNotifier<Geofence> _circleHitNotifier = ValueNotifier(null);
  final LayerHitNotifier<Geofence> _polygonHitNotifier = ValueNotifier(null);
  final LayerHitNotifier<Geofence> _lineHitNotifier = ValueNotifier(null);
  // ---- POI Add ----
  bool _isPickingPOIFromMap = false;
  String? _pendingPOILabel;
  bool _isPseudo3D = false;
  bool _isMoreMenuOpen = false;
  String _selectedTileLayerId = 'osm';
  bool _hasAutoFitToLandmarks = false;
  bool _hasUserInteractedWithMap = false;

  @override
  void initState() {
    super.initState();
    _currentCenter = _initialCenter;
    _loadLandmarks();
  }


  Future<void> _loadLandmarks() async {
    await ref.read(userLandmarkControllerProvider.notifier).loadLandmarks();
  }

  List<Geofence> get _geofences => ref
      .read(userLandmarkControllerProvider)
      .landmarks
      .map(_domainLandmarkToGeofence)
      .toList(growable: false);

  bool get _loading => ref.read(userLandmarkControllerProvider).isLoading;
  bool get _saving => ref.read(userLandmarkControllerProvider).isSaving;

  Geofence _domainLandmarkToGeofence(UserLandmarkItem item) {
    return Geofence(
      type: _geofenceTypeFromDomain(item.shape),
      label: item.name,
      color: _colorFromHex(item.colorHex),
      radius: item.radiusMeters,
      width: item.widthMeters,
      points: item.points,
    );
  }

  GeofenceType _geofenceTypeFromDomain(UserLandmarkShape shape) {
    switch (shape) {
      case UserLandmarkShape.circle:
        return GeofenceType.circle;
      case UserLandmarkShape.polygon:
        return GeofenceType.polygon;
      case UserLandmarkShape.rectangle:
        return GeofenceType.rectangle;
      case UserLandmarkShape.line:
        return GeofenceType.line;
      case UserLandmarkShape.poi:
        return GeofenceType.poi;
      case UserLandmarkShape.route:
        return GeofenceType.route;
    }
  }

  UserLandmarkShape _domainShapeFromGeofence(GeofenceType type) {
    switch (type) {
      case GeofenceType.circle:
        return UserLandmarkShape.circle;
      case GeofenceType.polygon:
        return UserLandmarkShape.polygon;
      case GeofenceType.rectangle:
        return UserLandmarkShape.rectangle;
      case GeofenceType.line:
        return UserLandmarkShape.line;
      case GeofenceType.poi:
        return UserLandmarkShape.poi;
      case GeofenceType.route:
        return UserLandmarkShape.route;
    }
  }

  void _scheduleAutoFitToLandmarks() {
    if (_hasAutoFitToLandmarks || _hasUserInteractedWithMap || !mounted) return;
    final points = _allLandmarkPoints();
    if (points.isEmpty) return;
    _hasAutoFitToLandmarks = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasUserInteractedWithMap) return;
      _fitToLandmarks(points);
    });
  }

  List<LatLng> _allLandmarkPoints() {
    final points = <LatLng>[];
    for (final g in _geofences) {
      if (g.points.isNotEmpty) {
        points.addAll(g.points);
      }
    }
    return points;
  }

  void _fitToLandmarks(List<LatLng> points) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, _focusMapZoom);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  String _tileUrlTemplate() {
    final option = kMapTileOptions.firstWhere(
      (e) => e.id == _selectedTileLayerId,
      orElse: () => kMapTileOptions.first,
    );
    final template = option.urlTemplate.trim();
    if (template.isEmpty) {
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
    // Some providers include Leaflet's {r} token. FlutterMap may not expand it
    // for all configs, so normalize it to avoid 404 tile requests.
    return template.replaceAll('{r}', '');
  }

  List<String> _tileSubdomains() {
    final option = kMapTileOptions.firstWhere(
      (e) => e.id == _selectedTileLayerId,
      orElse: () => kMapTileOptions.first,
    );
    return option.subdomains;
  }

  double? _sheetDouble(Object? source, String key) {
    if (source is Map) return _number(source[key]);
    return null;
  }

  String _sheetString(Object? source, String key) {
    if (source is Map) return (source[key] ?? '').toString().trim();
    return '';
  }

  double? _number(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  Color _colorFromHex(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return Colors.blue;
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length == 6) value = 'ff$value';
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? Colors.blue : Color(parsed);
  }

  List<LatLng> _latLngList(Object? value, {bool closePolygon = false}) {
    if (value is! List) return const <LatLng>[];
    final points = <LatLng>[];
    for (final item in value) {
      if (item is List && item.length >= 2) {
        final first = _number(item[0]);
        final second = _number(item[1]);
        if (first == null || second == null) continue;

        late final double lat;
        late final double lng;
        if (first.abs() > 60 && second.abs() <= 60) {
          lng = first;
          lat = second;
        } else if (second.abs() > 60 && first.abs() <= 60) {
          lat = first;
          lng = second;
        } else {
          lat = first;
          lng = second;
        }
        points.add(LatLng(lat, lng));
      }
    }

    if (closePolygon &&
        points.length >= 3 &&
        (points.first.latitude != points.last.latitude ||
            points.first.longitude != points.last.longitude)) {
      points.add(points.first);
    }
    return points;
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

  double _directedHausdorff(List<LatLng> pointsA, List<LatLng> pointsB) {
    final distance = const Distance();
    double maxMinDist = 0.0;
    for (var p in pointsA) {
      double minDist = double.infinity;
      for (var q in pointsB) {
        final d = distance.as(LengthUnit.Meter, p, q);
        if (d < minDist) minDist = d;
      }
      if (minDist > maxMinDist) maxMinDist = minDist;
    }
    return maxMinDist;
  }

  bool _isTooSimilar(Geofence newGeofence, Geofence existing) {
    if (newGeofence.type != existing.type) return false;
    final distance = const Distance();
    switch (newGeofence.type) {
      case GeofenceType.circle:
      case GeofenceType.poi:
        if (newGeofence.points.isEmpty ||
            existing.points.isEmpty ||
            newGeofence.radius == null ||
            existing.radius == null) {
          return false;
        }
        final d = distance.as(
          LengthUnit.Meter,
          newGeofence.points[0],
          existing.points[0],
        );
        final rDiff = (newGeofence.radius! - existing.radius!).abs();
        return d < 100 && rDiff < 50;
      case GeofenceType.polygon:
      case GeofenceType.rectangle:
      case GeofenceType.line:
      case GeofenceType.route:
        if (newGeofence.points.length < 2 || existing.points.length < 2) {
          return false;
        }
        final d1 = _directedHausdorff(newGeofence.points, existing.points);
        final d2 = _directedHausdorff(existing.points, newGeofence.points);
        final hausdorff = math.max(d1, d2);
        final double nw = newGeofence.width ?? 0.0;
        final double ew = existing.width ?? 0.0;
        final wDiff = (nw - ew).abs();
        return hausdorff < 100 && wDiff < 10;
    }
  }

  Future<void> _persistGeofence(Geofence g) async {
    for (final existing in _geofences) {
      if (_isTooSimilar(g, existing)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geofence too similar to an existing one')));
        return;
      }
    }

    final saved = await ref.read(userLandmarkControllerProvider.notifier).createLandmark(
      CreateUserLandmarkInput(
        name: g.label,
        shape: _domainShapeFromGeofence(g.type),
        points: g.points,
        radiusMeters: g.radius,
        widthMeters: g.width,
      ),
    );
    if (!mounted || !saved) return;
    if (g.type == GeofenceType.circle || g.type == GeofenceType.poi) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showLandmarkInfo(g);
      });
    }
    await _loadLandmarks();
  }

  // Clear all geofences
  void _clearGeofences() {
    if (_isAddingGeofence || _tempPoints.isNotEmpty) {
      updateLocalUiState(this, () {
        _isAddingGeofence = false;
        _pendingGeofenceType = null;
        _tempPoints.clear();
        _isPickingPOIFromMap = false;
        _pendingPOILabel = null;
      });
      return;
    }
    _loadLandmarks();
  }

  // Start adding geofence
  void _startAddingGeofence(GeofenceType type) {
    updateLocalUiState(this, () {
      _isAddingGeofence = true;
      _pendingGeofenceType = type;
      _tempPoints.clear();
    });
    String message = '';
    switch (type) {
      case GeofenceType.circle:
      case GeofenceType.poi:
        message = 'Tap map to select center';
        break;
      case GeofenceType.rectangle:
        message = 'Tap map for first corner, then second corner';
        break;
      case GeofenceType.polygon:
        message =
            'Tap map to add vertices, long press to finish (min 3 points)';
        break;
      case GeofenceType.line:
      case GeofenceType.route:
        message = 'Tap map to add points, long press to finish (min 2 points)';
        break;
    }
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Show screen for radius
  Future<void> _showRadiusScreen(
    LatLng center, {
    String label = 'Geofence',
  }) async {
    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBufferScreen(isRadius: true, initialLabel: label),
    );

    if (result != null) {
      final double radius = _sheetDouble(result, 'value') ?? 25;
      final String newLabel = _sheetString(result, 'label').isEmpty ? label : _sheetString(result, 'label');
      await _persistGeofence(
        Geofence(
          type: _pendingGeofenceType!,
          label: newLabel,
          points: [center],
          radius: radius,
        ),
      );
      updateLocalUiState(this, () => _isAddingGeofence = false);
    } else {
      updateLocalUiState(this, () => _isAddingGeofence = false);
    }
  }

  // Show screen for width
  Future<void> _showWidthScreen(
    List<LatLng> points, {
    String label = 'Geofence',
  }) async {
    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBufferScreen(isRadius: false, initialLabel: label),
    );

    if (result != null) {
      final double width = _sheetDouble(result, 'value') ?? 50;
      final String newLabel = _sheetString(result, 'label').isEmpty ? label : _sheetString(result, 'label');
      await _persistGeofence(
        Geofence(
          type: _pendingGeofenceType!,
          label: newLabel,
          points: points,
          width: width,
        ),
      );
      updateLocalUiState(this, () => _isAddingGeofence = false);
    } else {
      updateLocalUiState(this, () => _isAddingGeofence = false);
    }
  }

  Widget _buildLandmarkMap(BuildContext context) {
    final map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: _currentZoom,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onPositionChanged: (camera, hasGesture) {
          _currentCenter = camera.center;
          _currentZoom = camera.zoom;
          if (hasGesture) {
            _hasUserInteractedWithMap = true;
          }
          if (mounted) updateLocalUiState(this, () {});
        },
        onTap: (tapPos, latlng) async {
          if (_isAddingGeofence && _pendingGeofenceType != null) {
            _tempPoints.add(latlng);
            switch (_pendingGeofenceType) {
              case GeofenceType.circle:
                await _showRadiusScreen(latlng);
                break;
              case GeofenceType.poi:
                if (_isPickingPOIFromMap && _pendingPOILabel != null) {
                  await _showRadiusScreen(latlng, label: _pendingPOILabel!);
                  updateLocalUiState(this, () {
                    _isPickingPOIFromMap = false;
                    _pendingPOILabel = null;
                  });
                }
                break;
              case GeofenceType.rectangle:
                if (_tempPoints.length == 2) {
                  final p1 = _tempPoints[0];
                  final p2 = _tempPoints[1];
                  final minLat = p1.latitude < p2.latitude
                      ? p1.latitude
                      : p2.latitude;
                  final maxLat = p1.latitude > p2.latitude
                      ? p1.latitude
                      : p2.latitude;
                  final minLng = p1.longitude < p2.longitude
                      ? p1.longitude
                      : p2.longitude;
                  final maxLng = p1.longitude > p2.longitude
                      ? p1.longitude
                      : p2.longitude;
                  final points = [
                    LatLng(minLat, minLng),
                    LatLng(minLat, maxLng),
                    LatLng(maxLat, maxLng),
                    LatLng(maxLat, minLng),
                  ];
                  await _persistGeofence(
                    Geofence(
                      type: GeofenceType.rectangle,
                      label: 'Rectangle Geofence',
                      points: points,
                    ),
                  );
                  updateLocalUiState(this, () {
                    _isAddingGeofence = false;
                    _tempPoints.clear();
                  });
                }
                break;
              case GeofenceType.polygon:
              case GeofenceType.line:
              case GeofenceType.route:
                updateLocalUiState(this, () {});
                break;
              case null:
                break;
            }
          }
        },
        onLongPress: (tapPos, latlng) async {
          if (_isAddingGeofence && _pendingGeofenceType != null) {
            switch (_pendingGeofenceType) {
              case GeofenceType.polygon:
                if (_tempPoints.length >= 3) {
                  final points = List<LatLng>.from(_tempPoints)
                    ..add(_tempPoints.first);
                  await _persistGeofence(
                    Geofence(
                      type: GeofenceType.polygon,
                      label: 'Polygon Geofence',
                      points: points,
                    ),
                  );
                  updateLocalUiState(this, () {
                    _isAddingGeofence = false;
                    _tempPoints.clear();
                  });
                }
                break;
              case GeofenceType.line:
                if (_tempPoints.length >= 2) {
                  _showWidthScreen(
                    List.from(_tempPoints),
                    label: 'Line Geofence',
                  );
                }
                break;
              case GeofenceType.route:
                if (_tempPoints.length >= 2) {
                  _showWidthScreen(
                    List.from(_tempPoints),
                    label: 'Route Geofence',
                  );
                }
                break;
              default:
                break;
            }
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: _tileUrlTemplate(),
          subdomains: _tileSubdomains(),
          userAgentPackageName: 'com.openvts.app',
          tileProvider: NetworkTileProvider(
            cachingProvider: const DisabledMapCachingProvider(),
          ),
        ),
        MouseRegion(
          hitTestBehavior: HitTestBehavior.deferToChild,
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _showLandmarkInfoForHits(
              _circleHitNotifier.value?.hitValues.toList() ??
                  const <Geofence>[],
            ),
            child: CircleLayer(
              hitNotifier: _circleHitNotifier,
              circles: _geofences
                  .where(
                    (g) =>
                        (g.type == GeofenceType.circle ||
                            g.type == GeofenceType.poi) &&
                        g.points.isNotEmpty &&
                        g.radius != null,
                  )
                  .map(
                    (g) => CircleMarker(
                      point: g.points[0],
                      radius: g.radius!,
                      color: _selectedLandmark == g
                          ? g.color.withValues(alpha: 0.42)
                          : g.color.withValues(alpha: 0.3),
                      borderColor: _selectedLandmark == g
                          ? Colors.orange
                          : g.color,
                      borderStrokeWidth: 2,
                      hitValue: g,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        MouseRegion(
          hitTestBehavior: HitTestBehavior.deferToChild,
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _showLandmarkInfoForHits(
              _polygonHitNotifier.value?.hitValues.toList() ??
                  const <Geofence>[],
            ),
            child: PolygonLayer(
              hitNotifier: _polygonHitNotifier,
              polygons: _geofences
                  .where(
                    (g) =>
                        (g.type == GeofenceType.polygon ||
                            g.type == GeofenceType.rectangle) &&
                        g.points.length >= 3,
                  )
                  .map(
                    (g) => Polygon(
                      points: g.points,
                      color: g.color.withValues(alpha: 0.3),
                      borderColor: g.color,
                      borderStrokeWidth: 2,
                      hitValue: g,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        MouseRegion(
          hitTestBehavior: HitTestBehavior.deferToChild,
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _showLandmarkInfoForHits(
              _lineHitNotifier.value?.hitValues.toList() ?? const <Geofence>[],
            ),
            child: PolylineLayer(
              hitNotifier: _lineHitNotifier,
              polylines: _geofences
                  .where(
                    (g) =>
                        (g.type == GeofenceType.line ||
                            g.type == GeofenceType.route) &&
                        g.points.length >= 2 &&
                        (g.width ?? 0) > 0,
                  )
                  .map(
                    (g) => Polyline(
                      points: g.points,
                      color: g.color,
                      strokeWidth: g.width ?? 5.0,
                      hitValue: g,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        if (_isAddingGeofence &&
            (_pendingGeofenceType == GeofenceType.polygon ||
                _pendingGeofenceType == GeofenceType.line ||
                _pendingGeofenceType == GeofenceType.route) &&
            _tempPoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _tempPoints,
                color: Colors.red,
                strokeWidth: 3.0,
              ),
            ],
          ),
      ],
    );

    return _isPseudo3D ? Transform.scale(scale: 1.01, child: map) : map;
  }

  Widget _buildToolChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback? onPressed,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? Colors.black
              : (isDark ? cs.surface.withValues(alpha: 0.82) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.black : cs.outline.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.18 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : cs.onSurface),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final landmarkState = ref.watch(userLandmarkControllerProvider);
    ref.listen<UserLandmarkState>(userLandmarkControllerProvider, (previous, next) {
      final effect = next.effect;
      if (effect != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(effect.message)));
        ref.read(userLandmarkControllerProvider.notifier).clearEffect();
      }
      if (previous?.landmarks != next.landmarks) {
        _scheduleAutoFitToLandmarks();
      }
    });
    final topOffset = AppUtils.appBarHeightCustom + 14;
    final isLandmarkBusy = landmarkState.isLoading || landmarkState.isSaving;

    return AppLayout(
      title: "MAP",
      subtitle: "Geofence Management",
      actionIcons: [],
      onActionTaps: [],
      showAppBar: false,
      leftAvatarText: "MP",
      showLeftAvatar: false,
      horizontalPadding: 0,
      child: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              _buildLandmarkMap(context),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: UserHomeAppBar(
                  title: 'Geofence Management',
                  leadingIcon: Icons.location_on_outlined,
                  borderRadius: 0,
                  onClose: () => context.go(AppRoutePaths.userHome),
                ),
              ),
              // ================= TOOL CHIPS =================
              Positioned(
                top: topOffset,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildToolChip(
                          icon: Icons.circle_outlined,
                          label: 'Circle',
                          selected: _pendingGeofenceType == GeofenceType.circle,
                          onPressed: isLandmarkBusy
                              ? null
                              : () => _startAddingGeofence(GeofenceType.circle),
                        ),
                        const SizedBox(width: 10),
                        _buildToolChip(
                          icon: Icons.polyline_outlined,
                          label: 'Polygon',
                          selected:
                              _pendingGeofenceType == GeofenceType.polygon,
                          onPressed: isLandmarkBusy
                              ? null
                              : () =>
                                    _startAddingGeofence(GeofenceType.polygon),
                        ),
                        const SizedBox(width: 10),
                        _buildToolChip(
                          icon: Icons.rectangle_outlined,
                          label: 'Rectangle',
                          selected:
                              _pendingGeofenceType == GeofenceType.rectangle,
                          onPressed: isLandmarkBusy
                              ? null
                              : () => _startAddingGeofence(
                                  GeofenceType.rectangle,
                                ),
                        ),
                        const SizedBox(width: 10),
                        _buildToolChip(
                          icon: Icons.timeline,
                          label: 'Line',
                          selected: _pendingGeofenceType == GeofenceType.line,
                          onPressed: isLandmarkBusy
                              ? null
                              : () => _startAddingGeofence(GeofenceType.line),
                        ),
                        const SizedBox(width: 10),
                        _buildToolChip(
                          icon: Icons.route,
                          label: 'Route',
                          selected: _pendingGeofenceType == GeofenceType.route,
                          onPressed: isLandmarkBusy
                              ? null
                              : () => _startAddingGeofence(GeofenceType.route),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ================= RIGHT CONTROLS (Zoom, Clear) =================
              Positioned(
                right: 16,
                top: MediaQuery.of(context).size.height * 0.5 - 192,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Zoom In',
                      child: glassMapControlButton(
                        context: context,
                        width: 44,
                        height: 44,
                        child: const Icon(Icons.add),
                        onPressed: _zoomIn,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Tooltip(
                      message: 'Zoom Out',
                      child: glassMapControlButton(
                        context: context,
                        width: 44,
                        height: 44,
                        child: const Icon(Icons.remove),
                        onPressed: _zoomOut,
                      ),
                    ),
                    if (_isMoreMenuOpen) ...[
                      const SizedBox(height: 12),
                      _buildExpandedMoreMenu(context),
                    ],
                    const SizedBox(height: 12),
                    Tooltip(
                      message: _isMoreMenuOpen ? 'Collapse' : 'More',
                      child: glassMapControlButton(
                        context: context,
                        width: 44,
                        height: 44,
                        borderRadiusValue: _isMoreMenuOpen ? 0 : 9,
                        backgroundColor: _isMoreMenuOpen
                            ? Colors.transparent
                            : null,
                        borderColorOverride: _isMoreMenuOpen
                            ? Colors.transparent
                            : null,
                        showShadow: !_isMoreMenuOpen,
                        showBorder: !_isMoreMenuOpen,
                        blurSigma: _isMoreMenuOpen ? 0 : 2.5,
                        child: Icon(
                          _isMoreMenuOpen
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.more_horiz_rounded,
                        ),
                        onPressed: _toggleMoreMenu,
                      ),
                    ),
                  ],
                ),
              ),
              // ================= EXPANDABLE POI FAB =================
              /*
              Positioned(
                left: 16,
                bottom: bottomMargin + 10,
                child: ExpandableFab(
                  distance: 60.0,
                  children: [
                    ActionButton(
                      label: 'POI Landmark',
                      icon: const Icon(Icons.edit),
                      onPressed: () => _handleAddPOI('landmark', context),
                    ),
                    ActionButton(
                      label: 'POI Map location',
                      icon: const Icon(Icons.touch_app),
                      onPressed: () => _handleAddPOI('map_location', context),
                    ),
                    ActionButton(
                      label: 'POI Lat/Long',
                      icon: const Icon(Icons.map),
                      onPressed: () => _handleAddPOI('lat_lng', context),
                    ),
                  ],
                ),
              ),
              */
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
