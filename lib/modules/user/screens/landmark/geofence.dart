import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/result.dart';
import 'package:fleet_stack/core/repositories/user_landmarks_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/user/components/appbars/user_home_appbar.dart';
import 'package:fleet_stack/modules/user/screens/landmark/add_buffer_screen.dart';
import 'package:fleet_stack/modules/user/screens/map/widgets/glass_map_control_button.dart';
import 'package:fleet_stack/modules/user/screens/map/widgets/map_layers_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
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
  static const double _defaultMapZoom = 13.0;
  static const double _focusMapZoom = 16.0;
  double _currentZoom = _defaultMapZoom;
  // ---- GEOFENCE STATE ----
  final List<Geofence> _geofences = [];
  bool _isAddingGeofence = false;
  bool _loading = false;
  bool _saving = false;
  bool _loadErrorShown = false;
  bool _saveErrorShown = false;
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

    _scheduleAutoFitToLandmarks();

    if (!hasFailure || _loadErrorShown || !mounted) return;
    _loadErrorShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage ?? "Couldn't load landmarks.")),
    );
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
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
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

    if (typeRaw == 'LINE' || typeRaw == 'ROUTE' || geometry['type'] == 'LineString') {
      return Geofence(
        type: typeRaw == 'ROUTE' ? GeofenceType.route : GeofenceType.line,
        label: name,
        color: color,
        points: points,
        width: _number(
          geodata['toleranceM'] ??
              geodata['toleranceMeters'] ??
              raw['toleranceMeters'] ??
              raw['width'] ??
              raw['buffer'],
        ),
      );
    }

    return Geofence(
      type: typeRaw == 'RECTANGLE' || points.length == 4
          ? GeofenceType.rectangle
          : GeofenceType.polygon,
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

  String _landmarkMeasureLabel(Geofence g) {
    switch (g.type) {
      case GeofenceType.circle:
      case GeofenceType.poi:
        return 'Radius';
      case GeofenceType.line:
      case GeofenceType.route:
        return 'Tolerance';
      case GeofenceType.polygon:
      case GeofenceType.rectangle:
        return 'Vertices';
    }
  }

  String _landmarkMeasureValue(Geofence g) {
    switch (g.type) {
      case GeofenceType.circle:
      case GeofenceType.poi:
        return '${(g.radius ?? 25).round()} m';
      case GeofenceType.line:
      case GeofenceType.route:
        return '${(g.width ?? 50).round()} m';
      case GeofenceType.polygon:
      case GeofenceType.rectangle:
        return '${g.points.length}';
    }
  }

  String _landmarkTypeLabel(Geofence g) {
    switch (g.type) {
      case GeofenceType.circle:
      case GeofenceType.poi:
        return 'Circle';
      case GeofenceType.polygon:
        return 'Polygon';
      case GeofenceType.rectangle:
        return 'Rectangle';
      case GeofenceType.line:
        return 'Line';
      case GeofenceType.route:
        return 'Route';
    }
  }

  Future<void> _showLandmarkInfo(Geofence g) async {
    await _showLandmarkInfoForHits([g]);
  }

  void _focusLandmarkOnMap(Geofence g) {
    if (g.points.isEmpty) return;
    if (g.type == GeofenceType.circle || g.type == GeofenceType.poi) {
      _mapController.move(g.points.first, _focusMapZoom);
      return;
    }

    if (g.points.length == 1) {
      _mapController.move(g.points.first, _focusMapZoom);
      return;
    }

    final bounds = LatLngBounds.fromPoints(g.points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(56),
      ),
    );
  }

  IconData _landmarkIcon(Geofence g) {
    switch (g.type) {
      case GeofenceType.line:
      case GeofenceType.route:
        return Icons.alt_route_outlined;
      case GeofenceType.polygon:
      case GeofenceType.rectangle:
        return Icons.crop_square_outlined;
      case GeofenceType.circle:
      case GeofenceType.poi:
        return Icons.radio_button_checked_outlined;
    }
  }

  String _landmarkSummary(Geofence g) {
    return '${_landmarkTypeLabel(g)} · ${_landmarkMeasureLabel(g)} ${_landmarkMeasureValue(g)}';
  }

  String _tileUrlTemplate() {
    final option = kMapTileOptions.firstWhere(
      (e) => e.id == _selectedTileLayerId,
      orElse: () => kMapTileOptions.first,
    );
    return option.urlTemplate;
  }

  List<String> _tileSubdomains() {
    final option = kMapTileOptions.firstWhere(
      (e) => e.id == _selectedTileLayerId,
      orElse: () => kMapTileOptions.first,
    );
    return option.subdomains;
  }

  Future<void> _openLayersSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return MapLayersSheet(
          selectedTileLayerId: _selectedTileLayerId,
          onSelected: (option) {
            setState(() => _selectedTileLayerId = option.id);
            Navigator.pop(sheetContext);
          },
        );
      },
    );
  }

  void _togglePseudo3D() {
    setState(() => _isPseudo3D = !_isPseudo3D);
  }

  void _toggleMoreMenu() {
    setState(() => _isMoreMenuOpen = !_isMoreMenuOpen);
  }

  void _closeMoreMenu() {
    if (!_isMoreMenuOpen) return;
    setState(() => _isMoreMenuOpen = false);
  }

  Widget _buildMoreActionButton({
    required BuildContext context,
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: glassMapControlButton(
        context: context,
        width: 44,
        height: 44,
        borderRadiusValue: 9,
        backgroundColor:
            active ? Theme.of(context).colorScheme.primary : null,
        borderColorOverride:
            active ? Theme.of(context).colorScheme.primary : null,
        child: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildMoreTextButton({
    required BuildContext context,
    required String tooltip,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: glassMapControlButton(
        context: context,
        width: 44,
        height: 44,
        borderRadiusValue: 9,
        child: Text(label),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildExpandedMoreMenu(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          _buildMoreActionButton(
            context: context,
            tooltip: 'Landmark List',
            icon: Icons.list_alt_rounded,
            onPressed: () {
              _closeMoreMenu();
              _showLandmarkListSheet();
            },
          ),
          const SizedBox(height: 12),
          _buildMoreActionButton(
            context: context,
            tooltip: 'Map Layers',
            icon: Icons.layers_outlined,
            onPressed: () async {
              _closeMoreMenu();
              await _openLayersSheet();
            },
          ),
          const SizedBox(height: 12),
          _buildMoreTextButton(
            context: context,
            tooltip: _isPseudo3D ? 'Switch to 2D' : 'Switch to 3D',
            label: _isPseudo3D ? '3D' : '2D',
            onPressed: () {
              _closeMoreMenu();
              _togglePseudo3D();
            },
          ),
          const SizedBox(height: 12),
          _buildMoreActionButton(
            context: context,
            tooltip: 'Fit All Landmarks',
            icon: Icons.fit_screen_outlined,
            onPressed: () {
              _closeMoreMenu();
              _fitToLandmarks(_allLandmarkPoints());
            },
          ),
          const SizedBox(height: 12),
          _buildMoreActionButton(
            context: context,
            tooltip: 'Refresh Landmarks',
            icon: Icons.refresh,
            onPressed: () {
              _closeMoreMenu();
              _loadLandmarks();
            },
          ),
          const SizedBox(height: 12),
          _buildMoreActionButton(
            context: context,
            tooltip: 'Clear Drawing',
            icon: Icons.clear_all,
            onPressed: () {
              _closeMoreMenu();
              _clearGeofences();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showLandmarkListSheet() async {
    await _loadLandmarks();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: FractionallySizedBox(
              heightFactor: 0.8,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Landmarks',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_geofences.length} landmarks',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            await _showLandmarkListSheet();
                          },
                          icon: const Icon(Icons.refresh),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _loading
                            ? ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                itemCount: 4,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (_, __) => _landmarkListShimmerCard(),
                              )
                        : _geofences.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_off_outlined,
                                        size: 42,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No landmarks found',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Create a geofence, route, or POI to see it here.',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                itemCount: _geofences.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (_, index) {
                                  final g = _geofences[index];
                                  final selected = _selectedLandmark == g;
                                  return InkWell(
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      _focusLandmarkOnMap(g);
                                      setState(() => _selectedLandmark = g);
                                    },
                                    borderRadius: BorderRadius.circular(18),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? theme.colorScheme.primary.withValues(alpha: 0.08)
                                            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.50),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: selected
                                              ? theme.colorScheme.primary.withValues(alpha: 0.22)
                                              : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _landmarkIcon(g),
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  g.label,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _landmarkSummary(g),
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.chevron_right,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLandmarkInfoForHits(List<Geofence> hits) async {
    if (hits.isEmpty || !mounted) return;
    setState(() => _selectedLandmark = hits.first);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: FractionallySizedBox(
              heightFactor: 0.68,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Landmark Info',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: hits.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        if (index == hits.length) {
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Close'),
                            ),
                          );
                        }
                        final g = hits[index];
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.52),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(_landmarkIcon(g), color: theme.colorScheme.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          g.label,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _landmarkSummary(g),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _landmarkInfoRow(
                                icon: Icons.label_outline,
                                title: 'Name',
                                value: g.label,
                              ),
                              const SizedBox(height: 12),
                              _landmarkInfoRow(
                                icon: _landmarkIcon(g),
                                title: _landmarkMeasureLabel(g),
                                value: _landmarkMeasureValue(g),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (mounted) setState(() => _selectedLandmark = null);
  }

  Widget _landmarkInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _landmarkListShimmerCard() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const AppShimmer(width: 42, height: 42, radius: 12),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(width: 160, height: 14, radius: 7),
                SizedBox(height: 8),
                AppShimmer(width: 200, height: 12, radius: 6),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppShimmer(width: 18, height: 18, radius: 9),
        ],
      ),
    );
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

    if (g.type == GeofenceType.line || g.type == GeofenceType.route) {
      final tolerance = (g.width ?? 50).round();
      return <String, dynamic>{
        'name': g.label,
        'description': '',
        'type': g.type == GeofenceType.route ? 'ROUTE' : 'LINE',
        'color': '#3b82f6',
        'isActive': true,
        'geodata': <String, dynamic>{
          'kind': g.type == GeofenceType.route ? 'ROUTE' : 'LINE',
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
      case GeofenceType.line:
      case GeofenceType.route:
        result = await repo.createGeofence(
          _toGeofencePayload(g),
          cancelToken: token,
        );
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
        if (g.type == GeofenceType.circle || g.type == GeofenceType.poi) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showLandmarkInfo(g);
          });
        }
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
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBufferScreen(isRadius: true, initialLabel: label),
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
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBufferScreen(isRadius: false, initialLabel: label),
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
                if (_isPickingPOIFromMap && _pendingPOILabel != null) {
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
                setState(() {});
                break;
              case null:
                throw UnimplementedError();
            }
          }
        },
        onLongPress: (tapPos, latlng) async {
          if (_isAddingGeofence && _pendingGeofenceType != null) {
            switch (_pendingGeofenceType) {
              case GeofenceType.polygon:
                if (_tempPoints.length >= 3) {
                  final points = List<LatLng>.from(_tempPoints)..add(_tempPoints.first);
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
                  _showWidthScreen(List.from(_tempPoints), label: 'Line Geofence');
                }
                break;
              case GeofenceType.route:
                if (_tempPoints.length >= 2) {
                  _showWidthScreen(List.from(_tempPoints), label: 'Route Geofence');
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
          userAgentPackageName: 'com.example.fleek_stack_mobile',
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
              _lineHitNotifier.value?.hitValues.toList() ??
                  const <Geofence>[],
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
            color: selected
                ? Colors.black
                : cs.outline.withValues(alpha: 0.12),
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
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : cs.onSurface,
            ),
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
    final topOffset = AppUtils.appBarHeightCustom + 14;

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
                  onClose: () => context.go('/user/home'),
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
                          onPressed: (_loading || _saving)
                              ? null
                              : () => _startAddingGeofence(GeofenceType.circle),
                        ),
                        const SizedBox(width: 10),
                        _buildToolChip(
                          icon: Icons.polyline_outlined,
                          label: 'Polygon',
                          selected: _pendingGeofenceType == GeofenceType.polygon,
                          onPressed: (_loading || _saving)
                              ? null
                              : () => _startAddingGeofence(GeofenceType.polygon),
                        ),
                        const SizedBox(width: 10),
                        _buildToolChip(
                          icon: Icons.rectangle_outlined,
                          label: 'Rectangle',
                          selected:
                              _pendingGeofenceType == GeofenceType.rectangle,
                          onPressed: (_loading || _saving)
                              ? null
                              : () => _startAddingGeofence(GeofenceType.rectangle),
                        ),
                        const SizedBox(width: 10),
                        _buildToolChip(
                          icon: Icons.timeline,
                          label: 'Line',
                          selected: _pendingGeofenceType == GeofenceType.line,
                          onPressed: (_loading || _saving)
                              ? null
                              : () => _startAddingGeofence(GeofenceType.line),
                        ),
                        const SizedBox(width: 10),
                        _buildToolChip(
                          icon: Icons.route,
                          label: 'Route',
                          selected: _pendingGeofenceType == GeofenceType.route,
                          onPressed: (_loading || _saving)
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
    _loadToken?.cancel('User geofence disposed');
    _saveToken?.cancel('User geofence disposed');
    _mapController.dispose();
    super.dispose();
  }
}
