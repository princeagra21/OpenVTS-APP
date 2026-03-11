import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/result.dart';
import 'package:fleet_stack/core/repositories/user_landmarks_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/screens/landmark/add_buffer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../layout/app_layout.dart';

enum GeofenceType { circle, polygon, rectangle, line, poi, route }

class Geofence {
  final GeofenceType type;
  final String label;
  final Color color;
  final double? radius;
  final List<LatLng> points;
  final double? width;

  Geofence({
    required this.type,
    required this.label,
    this.color = Colors.blue,
    this.radius,
    this.points = const [],
    this.width,
  });
}

@immutable
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    this.initialOpen,
    required this.distance,
    required this.children,
  });
  final bool? initialOpen;
  final double distance;
  final List<Widget> children;
  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;
  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.children.length * widget.distance + 100,
      width: 200,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    for (var i = 0; i < count; i++) {
      children.add(
        _ExpandingActionButton(
          maxDistance: (i + 1) * widget.distance,
          progress: _expandAnimation,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            onPressed: _toggle,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.maxDistance,
    required this.progress,
    required this.child,
  });
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset(0, progress.value * maxDistance);
        return Positioned(right: 4.0, bottom: 4.0 + offset.dy, child: child!);
      },
      child: FadeTransition(opacity: progress, child: child),
    );
  }
}

@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.label,
  });
  final VoidCallback? onPressed;
  final Icon icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      label: Text(label),
      icon: icon,
    );
  }
}

class TopActionButton extends StatelessWidget {
  const TopActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final Icon icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
    );
  }
}

class GeofenceScreen extends StatefulWidget {
  const GeofenceScreen({super.key});

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
  // FleetStack-API-Reference.md + Postman confirmed:
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
  double _currentZoom = 5.0;
  // ---- GEOFENCE STATE ----
  final List<Geofence> _geofences = [];
  bool _isAddingGeofence = false;
  bool _loading = false;
  bool _saving = false;
  bool _loadErrorShown = false;
  bool _saveErrorShown = false;
  GeofenceType? _pendingGeofenceType;
  final List<LatLng> _tempPoints = [];
  // ---- POI Add ----
  bool _isPickingPOIFromMap = false;
  String? _pendingPOILabel;
  ApiClient? _apiClient;
  UserLandmarksRepository? _repo;
  CancelToken? _loadToken;
  CancelToken? _saveToken;

  @override
  void initState() {
    super.initState();
    _currentCenter = _initialCenter;
    _loadLandmarks();
  }

  UserLandmarksRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserLandmarksRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  Future<void> _loadLandmarks() async {
    _loadToken?.cancel('Reload user landmarks');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final repo = _repoOrCreate();
    final geofenceRes = await repo.getGeofences(cancelToken: token);
    if (!mounted || token.isCancelled) return;
    final routeRes = await repo.getRoutes(cancelToken: token);
    if (!mounted || token.isCancelled) return;
    final poiRes = await repo.getPois(cancelToken: token);
    if (!mounted || token.isCancelled) return;

    final next = <Geofence>[];
    bool hasFailure = false;
    String? errorMessage;

    void captureFailure(Object error, String fallback) {
      if (_isCancelled(error)) return;
      hasFailure = true;
      if (errorMessage == null || errorMessage!.trim().isEmpty) {
        errorMessage = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : fallback;
      }
    }

    geofenceRes.when(
      success: (items) {
        next.addAll(items.map(_geofenceFromApi).whereType<Geofence>());
      },
      failure: (error) => captureFailure(error, "Couldn't load geofences."),
    );
    routeRes.when(
      success: (items) {
        next.addAll(items.map(_routeFromApi).whereType<Geofence>());
      },
      failure: (error) => captureFailure(error, "Couldn't load routes."),
    );
    poiRes.when(
      success: (items) {
        next.addAll(items.map(_poiFromApi).whereType<Geofence>());
      },
      failure: (error) => captureFailure(error, "Couldn't load POIs."),
    );

    if (!mounted) return;
    setState(() {
      _geofences
        ..clear()
        ..addAll(next);
      _loading = false;
      if (!hasFailure) {
        _loadErrorShown = false;
      }
    });

    if (!hasFailure || _loadErrorShown || !mounted) return;
    _loadErrorShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage ?? "Couldn't load landmarks.")),
    );
  }

  Geofence? _geofenceFromApi(Map<String, dynamic> raw) {
    final name = _text(raw['name'] ?? raw['label']);
    if (name.isEmpty) return null;

    final typeRaw = _text(
      raw['type'] ?? _mapValue(raw['geodata'])['kind'] ?? raw['shapeType'],
    ).toUpperCase();
    final geodata = _mapValue(raw['geodata']);
    final geometry = _mapValue(geodata['geometry']);
    final color = _colorFromHex(_text(raw['color']));

    if (typeRaw == 'CIRCLE') {
      final center = _mapValue(geodata['center']);
      final lat = _number(
        center['lat'] ?? raw['latitude'] ?? raw['lat'] ?? raw['centerLat'],
      );
      final lng = _number(
        center['lon'] ??
            center['lng'] ??
            raw['longitude'] ??
            raw['lng'] ??
            raw['lon'] ??
            raw['centerLon'],
      );
      if (lat == null || lng == null) return null;
      return Geofence(
        type: GeofenceType.circle,
        label: name,
        color: color,
        points: [LatLng(lat, lng)],
        radius: _number(geodata['radiusM'] ?? raw['radius'] ?? raw['radiusM']),
      );
    }

    final points = _latLngList(
      geometry['coordinates'] ?? raw['coordinates'] ?? raw['points'],
      closePolygon: typeRaw == 'POLYGON',
    );
    if (points.isEmpty) return null;

    return Geofence(
      type: points.length == 4 ? GeofenceType.rectangle : GeofenceType.polygon,
      label: name,
      color: color,
      points: points,
    );
  }

  Geofence? _routeFromApi(Map<String, dynamic> raw) {
    final name = _text(raw['name'] ?? raw['label']);
    if (name.isEmpty) return null;

    final geodata = _mapValue(raw['geodata']);
    final geometry = _mapValue(geodata['geometry']);
    final points = _latLngList(
      geometry['coordinates'] ?? raw['coordinates'] ?? raw['points'],
    );
    if (points.length < 2) return null;

    return Geofence(
      type: GeofenceType.route,
      label: name,
      color: _colorFromHex(_text(raw['color'])),
      points: points,
      width: _number(
        geodata['toleranceM'] ??
            raw['toleranceMeters'] ??
            raw['width'] ??
            raw['buffer'],
      ),
    );
  }

  Geofence? _poiFromApi(Map<String, dynamic> raw) {
    final name = _text(raw['name'] ?? raw['label']);
    if (name.isEmpty) return null;

    final coordinates = _mapValue(raw['coordinates']);
    final lat = _number(
      coordinates['lat'] ?? raw['latitude'] ?? raw['lat'] ?? raw['centerLat'],
    );
    final lng = _number(
      coordinates['lon'] ??
          coordinates['lng'] ??
          raw['longitude'] ??
          raw['lng'] ??
          raw['lon'] ??
          raw['centerLon'],
    );
    if (lat == null || lng == null) return null;

    return Geofence(
      type: GeofenceType.poi,
      label: name,
      color: _colorFromHex(_text(raw['color'])),
      points: [LatLng(lat, lng)],
      radius:
          _number(raw['toleranceMeters'] ?? raw['radius'] ?? raw['radiusM']) ??
          25,
    );
  }

  Map<String, dynamic> _mapValue(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  String _text(Object? value) => (value ?? '').toString().trim();

  double? _number(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Color _colorFromHex(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return Colors.blue;
    var hex = value.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final parsed = int.tryParse(hex, radix: 16);
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
    setState(() => _currentZoom = newZoom);
  }

  void _zoomOut() {
    final newZoom = (_currentZoom - 1).clamp(3.0, 18.0);
    _mapController.move(_currentCenter, newZoom);
    setState(() => _currentZoom = newZoom);
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

  Map<String, dynamic> _toGeofencePayload(Geofence g) {
    if (g.points.isEmpty) return const <String, dynamic>{};
    if (g.type == GeofenceType.circle || g.type == GeofenceType.poi) {
      final center = g.points.first;
      final radius = (g.radius ?? 25).round();
      return <String, dynamic>{
        'name': g.label,
        'type': g.type == GeofenceType.poi ? 'POI' : 'CIRCLE',
        'color': '#2196F3',
        'isActive': true,
        'geodata': <String, dynamic>{
          'kind': 'CIRCLE',
          'center': <String, dynamic>{
            'lat': center.latitude,
            'lon': center.longitude,
          },
          'radiusM': radius,
        },
      };
    }

    final polygonPoints = List<LatLng>.from(g.points);
    if (polygonPoints.length >= 3 &&
        (polygonPoints.first.latitude != polygonPoints.last.latitude ||
            polygonPoints.first.longitude != polygonPoints.last.longitude)) {
      polygonPoints.add(polygonPoints.first);
    }

    return <String, dynamic>{
      'name': g.label,
      'type': 'POLYGON',
      'color': '#2196F3',
      'isActive': true,
      'geodata': <String, dynamic>{
        'kind': 'POLYGON',
        'geometry': <String, dynamic>{
          'type': 'Polygon',
          'coordinates': [
            polygonPoints
                .map((p) => <double>[p.longitude, p.latitude])
                .toList(),
          ],
        },
      },
    };
  }

  Map<String, dynamic> _toRoutePayload(Geofence g) {
    final tolerance = (g.width ?? 50).round();
    return <String, dynamic>{
      'name': g.label,
      'color': '#2196F3',
      'geodata': <String, dynamic>{
        'kind': 'LINE',
        'geometry': <String, dynamic>{
          'type': 'LineString',
          'coordinates': g.points
              .map((p) => <double>[p.longitude, p.latitude])
              .toList(),
        },
        'toleranceM': tolerance,
      },
    };
  }

  Map<String, dynamic> _toPoiPayload(Geofence g) {
    final point = g.points.first;
    final tolerance = (g.radius ?? 25).round();
    return <String, dynamic>{
      'name': g.label,
      'color': '#2196F3',
      'toleranceMeters': tolerance,
      'coordinates': <String, dynamic>{
        'lat': point.latitude,
        'lon': point.longitude,
      },
    };
  }

  Future<void> _persistGeofence(Geofence g) async {
    for (var existing in _geofences) {
      if (_isTooSimilar(g, existing)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geofence too similar to an existing one'),
          ),
        );
        return;
      }
    }

    if (_saving) return;
    _saveToken?.cancel('Restart geofence save');
    final token = CancelToken();
    _saveToken = token;

    if (!mounted) return;
    setState(() => _saving = true);

    final repo = _repoOrCreate();
    final Result<void> result;
    switch (g.type) {
      case GeofenceType.circle:
      case GeofenceType.polygon:
      case GeofenceType.rectangle:
        result = await repo.createGeofence(
          _toGeofencePayload(g),
          cancelToken: token,
        );
        break;
      case GeofenceType.line:
      case GeofenceType.route:
        result = await repo.createRoute(_toRoutePayload(g), cancelToken: token);
        break;
      case GeofenceType.poi:
        result = await repo.createPoi(_toPoiPayload(g), cancelToken: token);
        break;
    }

    if (!mounted || token.isCancelled) return;

    result.when(
      success: (_) {
        setState(() {
          _geofences.add(g);
          _saving = false;
          _saveErrorShown = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Landmark saved')));
        _loadLandmarks();
      },
      failure: (error) {
        setState(() => _saving = false);
        if (_isCancelled(error) || _saveErrorShown) return;
        _saveErrorShown = true;
        final message = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't save landmark.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  // Clear all geofences
  void _clearGeofences() {
    if (_isAddingGeofence || _tempPoints.isNotEmpty) {
      setState(() {
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
    setState(() {
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
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => AddBufferScreen(isRadius: true, initialLabel: label),
      ),
    );

    if (result != null) {
      final double radius = result['value'];
      final String newLabel = result['label'];
      await _persistGeofence(
        Geofence(
          type: _pendingGeofenceType!,
          label: newLabel,
          points: [center],
          radius: radius,
        ),
      );
      setState(() => _isAddingGeofence = false);
    } else {
      setState(() => _isAddingGeofence = false);
    }
  }

  // Show screen for width
  Future<void> _showWidthScreen(
    List<LatLng> points, {
    String label = 'Geofence',
  }) async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => AddBufferScreen(isRadius: false, initialLabel: label),
      ),
    );

    if (result != null) {
      final double width = result['value'];
      final String newLabel = result['label'];
      await _persistGeofence(
        Geofence(
          type: _pendingGeofenceType!,
          label: newLabel,
          points: points,
          width: width,
        ),
      );
      setState(() => _isAddingGeofence = false);
    } else {
      setState(() => _isAddingGeofence = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomBarHeight = AdaptiveUtils.getBottomBarHeight(screenWidth);
    final fabSize = AdaptiveUtils.getButtonSize(screenWidth);
    final iconSize = AdaptiveUtils.getIconSize(screenWidth);
    final bottomMargin =
        MediaQuery.of(context).padding.bottom + bottomBarHeight + 50;

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
              // ================= MAP =================
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: _currentZoom,
                  minZoom: 3,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onPositionChanged: (camera, _) {
                    _currentCenter = camera.center;
                    _currentZoom = camera.zoom;
                    if (mounted) setState(() {});
                  },
                  onTap: (tapPos, latlng) async {
                    if (_isAddingGeofence && _pendingGeofenceType != null) {
                      _tempPoints.add(latlng);
                      switch (_pendingGeofenceType) {
                        case GeofenceType.circle:
                          await _showRadiusScreen(latlng);
                          break;
                        case GeofenceType.poi:
                          if (_isPickingPOIFromMap &&
                              _pendingPOILabel != null) {
                            await _showRadiusScreen(
                              latlng,
                              label: _pendingPOILabel!,
                            );
                            setState(() {
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
                            setState(() {
                              _isAddingGeofence = false;
                              _tempPoints.clear();
                            });
                          }
                          break;
                        case GeofenceType.polygon:
                        case GeofenceType.line:
                        case GeofenceType.route:
                          setState(() {}); // Update temp layer
                          break;
                        case null:
                          // TODO: Handle this case.
                          throw UnimplementedError();
                      }
                    }
                  },
                  onLongPress: (tapPos, latlng) async {
                    if (_isAddingGeofence && _pendingGeofenceType != null) {
                      switch (_pendingGeofenceType) {
                        case GeofenceType.polygon:
                          if (_tempPoints.length >= 3) {
                            List<LatLng> points = List.from(_tempPoints);
                            points.add(_tempPoints.first); // Close polygon
                            await _persistGeofence(
                              Geofence(
                                type: GeofenceType.polygon,
                                label: 'Polygon Geofence',
                                points: points,
                              ),
                            );
                            setState(() {
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
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'com.example.fleek_stack_mobile',
                  ),
                  // Geofence layers (safe: only include when points/radius/width exist)
                  CircleLayer(
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
                            color: g.color.withOpacity(0.3),
                            borderColor: g.color,
                            borderStrokeWidth: 2,
                          ),
                        )
                        .toList(),
                  ),

                  PolygonLayer(
                    polygons: _geofences
                        .where(
                          (g) =>
                              (g.type == GeofenceType.polygon ||
                                  g.type == GeofenceType.rectangle) &&
                              g.points.length >= 3,
                        ) // polygon needs >=3 (rectangle will be 4)
                        .map(
                          (g) => Polygon(
                            points: g.points,
                            color: g.color.withOpacity(0.3),
                            borderColor: g.color,
                            borderStrokeWidth: 2,
                          ),
                        )
                        .toList(),
                  ),

                  PolylineLayer(
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
                          ),
                        )
                        .toList(),
                  ),

                  // Temp drawing layer for adding geofence (only when _tempPoints has points)
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
              ),
              // ================= TOP ADD BUTTONS =================
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: cs.surface,
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TopActionButton(
                          onPressed: (_loading || _saving)
                              ? null
                              : () => _startAddingGeofence(GeofenceType.circle),
                          icon: const Icon(Icons.circle_outlined),
                          label: 'Circle',
                        ),
                        const SizedBox(width: 8),
                        TopActionButton(
                          onPressed: (_loading || _saving)
                              ? null
                              : () =>
                                    _startAddingGeofence(GeofenceType.polygon),
                          icon: const Icon(Icons.polyline_outlined),
                          label: 'Polygon',
                        ),
                        const SizedBox(width: 8),
                        TopActionButton(
                          onPressed: (_loading || _saving)
                              ? null
                              : () => _startAddingGeofence(
                                  GeofenceType.rectangle,
                                ),
                          icon: const Icon(Icons.rectangle_outlined),
                          label: 'Rectangle',
                        ),
                        const SizedBox(width: 8),
                        TopActionButton(
                          onPressed: (_loading || _saving)
                              ? null
                              : () => _startAddingGeofence(GeofenceType.line),
                          icon: const Icon(Icons.timeline),
                          label: 'Line',
                        ),
                        const SizedBox(width: 8),
                        TopActionButton(
                          onPressed: (_loading || _saving)
                              ? null
                              : () => _startAddingGeofence(GeofenceType.route),
                          icon: const Icon(Icons.route),
                          label: 'Route',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ================= RIGHT CONTROLS (Zoom, Clear) =================
              Positioned(
                right: 16,
                bottom: bottomMargin + 10,
                child: Column(
                  children: [
                    Tooltip(
                      message: 'Zoom In',
                      child: _fab(
                        hero: "zoom_in",
                        icon: Icons.add,
                        size: fabSize,
                        iconSize: iconSize,
                        onTap: _zoomIn,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Tooltip(
                      message: 'Zoom Out',
                      child: _fab(
                        hero: "zoom_out",
                        icon: Icons.remove,
                        size: fabSize,
                        iconSize: iconSize,
                        onTap: _zoomOut,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Tooltip(
                      message: _isAddingGeofence
                          ? 'Clear Draft'
                          : 'Refresh Geofences',
                      child: _fab(
                        hero: "clear",
                        icon: Icons.clear,
                        size: fabSize,
                        iconSize: iconSize,
                        onTap: (_loading || _saving) ? () {} : _clearGeofences,
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
  Widget _fab({
    required String hero,
    required IconData icon,
    required double size,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: FloatingActionButton(
        heroTag: hero,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        onPressed: onTap,
        child: Icon(icon, size: iconSize),
      ),
    );
  }

  @override
  void dispose() {
    _loadToken?.cancel('User geofence disposed');
    _saveToken?.cancel('User geofence disposed');
    _mapController.dispose();
    super.dispose();
  }
}
