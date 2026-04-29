import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/user_route_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_routes_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/user/components/appbars/user_home_appbar.dart';
import 'package:fleet_stack/modules/user/screens/route/add_landmark_screen.dart';
import 'package:fleet_stack/modules/user/screens/route/add_lat_lng_screen.dart';
import 'package:fleet_stack/modules/user/screens/route/add_map_location_screen.dart';
import 'package:fleet_stack/modules/user/screens/route/assign_driver_screen.dart';
import 'package:fleet_stack/modules/user/screens/map/widgets/glass_map_control_button.dart';
import 'package:fleet_stack/modules/user/screens/map/widgets/map_layers_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../layout/app_layout.dart';

class RouteOptimizationScreen extends StatefulWidget {
  const RouteOptimizationScreen({super.key});

  @override
  State<RouteOptimizationScreen> createState() =>
      _RouteOptimizationScreenState();
}

class Waypoint {
  final LatLng point;
  final String label;
  final IconData icon;

  Waypoint({required this.point, required this.label, required this.icon});
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

class _RouteOptimizationScreenState extends State<RouteOptimizationScreen> {
  // FleetStack-API-Reference.md + Postman confirmed:
  // - GET    /user/routes
  // - GET    /user/routes/:id
  // - POST   /user/routes
  // - PATCH  /user/routes/:id
  //
  // Missing backend APIs for this screen:
  // - No /user/routes/optimize (optimization stays local in app)
  // - No assign-driver endpoint for saved routes
  //
  // Missing UI/backend parity:
  // - Assign Driver is local-only and not persisted
  // - Route list/history UI is not exposed; only latest saved route is auto-loaded
  static const double _defaultMapZoom = 13.0;
  static const double _routeFocusZoom = 16.0;
  final MapController _mapController = MapController();
  final PopupController _popupLayerController = PopupController();

  final LatLng _initialCenter = const LatLng(28.6139, 77.2090);
  late LatLng _currentCenter;
  double _currentZoom = _defaultMapZoom;

  final List<Waypoint> _waypoints = <Waypoint>[];
  List<LatLng> _route = <LatLng>[];
  bool _isOptimized = false;
  double _totalDistanceKm = 0.0;
  bool _isOptimizing = false;
  bool _loading = false;
  bool _saving = false;
  bool _deleting = false;
  bool _loadErrorShown = false;
  bool _saveErrorShown = false;
  bool _isMoreMenuOpen = false;
  bool _isPseudo3D = false;
  String _selectedTileLayerId = 'osm';

  String? _assignedDriver;
  String? _loadedRouteId;
  String _routeName = 'Optimized Route';

  bool _isPickingFromMap = false;
  String? _pendingLabel;
  IconData _pendingIcon = Icons.location_on;
  String? _activeAddMode;

  ApiClient? _apiClient;
  UserRoutesRepository? _repo;
  CancelToken? _loadToken;
  CancelToken? _saveToken;
  CancelToken? _deleteToken;

  @override
  void initState() {
    super.initState();
    _currentCenter = _initialCenter;
    _loadLatestRoute();
  }

  @override
  void dispose() {
    _loadToken?.cancel('User route optimization disposed');
    _saveToken?.cancel('User route optimization disposed');
    _deleteToken?.cancel('User route optimization disposed');
    _mapController.dispose();
    super.dispose();
  }

  UserRoutesRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserRoutesRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  DateTime _safeParseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    final parsed = DateTime.tryParse(value);
    return parsed?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _loadLatestRoute() async {
    _loadToken?.cancel('Reload user routes');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final routesRes = await _repoOrCreate().getRoutes(cancelToken: token);
    if (!mounted || token.isCancelled) return;

    await routesRes.when(
      success: (items) async {
        if (items.isEmpty) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _loadErrorShown = false;
          });
          return;
        }

        final sorted = List<UserRouteItem>.from(items)
          ..sort(
            (a, b) => _safeParseDate(
              b.updatedAt,
            ).compareTo(_safeParseDate(a.updatedAt)),
          );

        final detailsRes = await _repoOrCreate().getRouteDetails(
          sorted.first.id,
          cancelToken: token,
        );
        if (!mounted || token.isCancelled) return;

        detailsRes.when(
          success: (route) {
            _hydrateFromRoute(route);
            if (!mounted) return;
            setState(() {
              _loading = false;
              _loadErrorShown = false;
            });
          },
          failure: (error) {
            if (!mounted) return;
            setState(() => _loading = false);
            if (_isCancelled(error) || _loadErrorShown) return;
            _loadErrorShown = true;
            final msg = error is ApiException && error.message.trim().isNotEmpty
                ? error.message
                : "Couldn't load route details.";
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(msg)));
          },
        );
      },
      failure: (error) async {
        if (!mounted) return;
        setState(() => _loading = false);
        if (_isCancelled(error) || _loadErrorShown) return;
        _loadErrorShown = true;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't load routes.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  void _hydrateFromRoute(UserRouteItem route) {
    final coords = route.coordinates;
    _loadedRouteId = route.id;
    _routeName = route.name;
    _route = List<LatLng>.from(coords);
    _waypoints
      ..clear()
      ..addAll(
        coords.asMap().entries.map(
          (entry) => Waypoint(
            point: entry.value,
            label: 'Point ${entry.key + 1}',
            icon: Icons.location_on,
          ),
        ),
      );
    _isOptimized = coords.length >= 2;
    _totalDistanceKm = _calculateTotalDistance(coords);

    if (coords.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fitRoute();
      });
    }
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

  void _fitRoute() {
    final points = _route.isNotEmpty ? _route : _waypoints.map((w) => w.point).toList();
    if (points.isEmpty) return;

    if (points.length == 1) {
      final p = points.first;
      _mapController.move(p, _routeFocusZoom);
      setState(() {
        _currentCenter = p;
        _currentZoom = _routeFocusZoom;
      });
      return;
    }

    final lats = points.map((p) => p.latitude).toList();
    final lngs = points.map((p) => p.longitude).toList();
    final bounds = LatLngBounds(
      LatLng(lats.reduce((a, b) => a < b ? a : b), lngs.reduce((a, b) => a < b ? a : b)),
      LatLng(lats.reduce((a, b) => a > b ? a : b), lngs.reduce((a, b) => a > b ? a : b)),
    );
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  Future<void> _openMapLayersSheet() async {
    final option = await showModalBottomSheet<MapTileOption>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return MapLayersSheet(
          selectedTileLayerId: _selectedTileLayerId,
          onSelected: (option) => Navigator.pop(sheetContext, option),
        );
      },
    );
    if (!mounted || option == null) return;
    setState(() => _selectedTileLayerId = option.id);
  }

  void _togglePseudo3D() {
    setState(() => _isPseudo3D = !_isPseudo3D);
  }

  MapTileOption get _selectedTileOption {
    return kMapTileOptions.firstWhere(
      (option) => option.id == _selectedTileLayerId,
      orElse: () => kMapTileOptions.first,
    );
  }

  void _toggleMoreMenu() {
    setState(() => _isMoreMenuOpen = !_isMoreMenuOpen);
  }

  void _closeMoreMenu() {
    if (!_isMoreMenuOpen) return;
    setState(() => _isMoreMenuOpen = false);
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

  Widget _buildMoreActionButton({
    required BuildContext context,
    required String tooltip,
    required Widget child,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: glassMapControlButton(
        context: context,
        width: 44,
        height: 44,
        borderRadiusValue: 9,
        child: child,
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
            tooltip: 'Optimize Route',
            child: const Icon(Icons.autorenew),
            onPressed: () {
              _closeMoreMenu();
              if (!_loading && !_saving && !_deleting && !_isOptimizing) {
                _optimizeRoute();
              }
            },
          ),
          const SizedBox(height: 12),
          _buildMoreActionButton(
            context: context,
            tooltip: 'Clear Route',
            child: const Icon(Icons.clear),
            onPressed: () {
              _closeMoreMenu();
              if (!_loading && !_saving && !_deleting && !_isOptimizing) {
                _clearWaypoints();
              }
            },
          ),
          const SizedBox(height: 12),
          _buildMoreActionButton(
            context: context,
            tooltip: 'Assign Driver',
            child: const Icon(Icons.person_add),
            onPressed: () {
              _closeMoreMenu();
              if (!_loading && !_saving && !_deleting && !_isOptimizing) {
                _assignDriver();
              }
            },
          ),
          const SizedBox(height: 12),
          _buildMoreActionButton(
            context: context,
            tooltip: 'Email Route',
            child: const Icon(Icons.email),
            onPressed: () {
              _closeMoreMenu();
              _emailRoute();
            },
          ),
          const SizedBox(height: 12),
          _buildMoreActionButton(
            context: context,
            tooltip: 'Map Layers',
            child: const Icon(Icons.layers_outlined),
            onPressed: () async {
              _closeMoreMenu();
              await _openMapLayersSheet();
            },
          ),
          const SizedBox(height: 12),
          _buildMoreActionButton(
            context: context,
            tooltip: _isPseudo3D ? 'Switch to 2D' : 'Switch to 3D',
            child: Text(_isPseudo3D ? '3D' : '2D'),
            onPressed: () {
              _closeMoreMenu();
              _togglePseudo3D();
            },
          ),
        ],
      ),
    );
  }

  void _addWaypoint(LatLng p, {required String label, IconData? icon}) {
    setState(() {
      _waypoints.add(
        Waypoint(point: p, label: label, icon: icon ?? Icons.place),
      );
      _isOptimized = false;
      _route = <LatLng>[];
      _totalDistanceKm = 0.0;
    });
  }

  void _removeWaypoint(int index) {
    setState(() {
      if (index >= 0 && index < _waypoints.length) {
        _waypoints.removeAt(index);
        _isOptimized = false;
        _route = <LatLng>[];
        _totalDistanceKm = 0.0;
      }
    });
  }

  void _showWaypointInfo(int index) {
    final waypoint = _waypoints[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(waypoint.label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${waypoint.point.latitude}'),
            Text('Longitude: ${waypoint.point.longitude}'),
            Row(children: [const Text('Icon: '), Icon(waypoint.icon)]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeWaypoint(index);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _resetRouteState() {
    _waypoints.clear();
    _route = <LatLng>[];
    _isOptimized = false;
    _totalDistanceKm = 0.0;
    _assignedDriver = null;
    _loadedRouteId = null;
    _routeName = 'Optimized Route';
  }

  Future<void> _clearWaypoints() async {
    if (_loadedRouteId == null || _loadedRouteId!.trim().isEmpty) {
      if (!mounted) return;
      setState(_resetRouteState);
      return;
    }

    _deleteToken?.cancel('Restart user route delete');
    final token = CancelToken();
    _deleteToken = token;

    if (!mounted) return;
    setState(() => _deleting = true);

    final result = await _repoOrCreate().deleteRoute(
      _loadedRouteId!,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (_) {
        setState(() {
          _deleting = false;
          _resetRouteState();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Route cleared')));
      },
      failure: (error) {
        setState(() => _deleting = false);
        if (_isCancelled(error)) return;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't clear route.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  double _calculateTotalDistance(List<LatLng> route) {
    final distance = const Distance();
    double total = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      total += distance.as(LengthUnit.Kilometer, route[i], route[i + 1]);
    }
    return total;
  }

  List<LatLng> _twoOptImprove(List<LatLng> route) {
    final distance = const Distance();
    bool improved = true;
    while (improved) {
      improved = false;
      for (int i = 1; i < route.length - 2; i++) {
        for (int j = i + 2; j < route.length - 1; j++) {
          final oldDist =
              distance.as(LengthUnit.Meter, route[i - 1], route[i]) +
              distance.as(LengthUnit.Meter, route[j], route[j + 1]);
          final newDist =
              distance.as(LengthUnit.Meter, route[i - 1], route[j]) +
              distance.as(LengthUnit.Meter, route[i], route[j + 1]);
          if (newDist < oldDist) {
            final reversed = route.sublist(i, j + 1).reversed.toList();
            route.replaceRange(i, j + 1, reversed);
            improved = true;
          }
        }
      }
    }
    return route;
  }

  Map<String, dynamic> _routePayload(List<LatLng> points) {
    return <String, dynamic>{
      'name': _routeName,
      'color': '#2196F3',
      'toleranceMeters': 100,
      'geodata': <String, dynamic>{
        'kind': 'LINE',
        'geometry': <String, dynamic>{
          'type': 'LineString',
          'coordinates': points
              .map((p) => <double>[p.longitude, p.latitude])
              .toList(),
        },
        'toleranceM': 100,
      },
    };
  }

  Future<void> _saveRoute(List<LatLng> points) async {
    if (points.length < 2) return;
    _saveToken?.cancel('Restart user route save');
    final token = CancelToken();
    _saveToken = token;

    if (!mounted) return;
    setState(() => _saving = true);

    final payload = _routePayload(points);
    final repo = _repoOrCreate();
    final result = _loadedRouteId == null || _loadedRouteId!.trim().isEmpty
        ? await repo.createRoute(payload, cancelToken: token)
        : await repo.updateRoute(_loadedRouteId!, payload, cancelToken: token);

    if (!mounted || token.isCancelled) return;

    result.when(
      success: (route) {
        setState(() {
          _loadedRouteId = route.id;
          _routeName = route.name;
          _saving = false;
          _saveErrorShown = false;
        });
      },
      failure: (error) {
        setState(() => _saving = false);
        if (_isCancelled(error) || _saveErrorShown) return;
        _saveErrorShown = true;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't save route.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Future<void> _optimizeRoute() async {
    if (_waypoints.length <= 1) {
      setState(() {
        _route = List<LatLng>.from(_waypoints.map((w) => w.point));
        _isOptimized = true;
        _totalDistanceKm = _calculateTotalDistance(_route);
      });
      await _saveRoute(_route);
      return;
    }

    setState(() => _isOptimizing = true);

    final distance = const Distance();
    final remaining = _waypoints.map((w) => w.point).toList(growable: true);
    final ordered = <LatLng>[];

    LatLng current = remaining.removeAt(0);
    ordered.add(current);

    while (remaining.isNotEmpty) {
      int nearestIndex = 0;
      double nearestDist = double.infinity;
      for (int i = 0; i < remaining.length; i++) {
        final d = distance(current, remaining[i]);
        if (d < nearestDist) {
          nearestDist = d;
          nearestIndex = i;
        }
      }
      current = remaining.removeAt(nearestIndex);
      ordered.add(current);
    }

    final optimized = _twoOptImprove(ordered);

    if (!mounted) return;
    setState(() {
      _route = List<LatLng>.from(optimized);
      _isOptimized = true;
      _totalDistanceKm = _calculateTotalDistance(_route);
      _isOptimizing = false;
    });

    if (_route.isNotEmpty) {
      _fitRoute();
    }

    await _saveRoute(_route);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Optimized route: ${_totalDistanceKm.toStringAsFixed(2)} km',
        ),
      ),
    );
  }

  Future<void> _handleAdd(String type, BuildContext ctx) async {
    Widget screen;
    if (type == 'landmark') {
      screen = const AddLandmarkScreen();
    } else if (type == 'lat_lng') {
      screen = const AddLatLngScreen();
    } else if (type == 'map_location') {
      screen = const AddMapLocationScreen();
    } else {
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>?>(
      ctx,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (!mounted || result == null) return;

    if (type == 'map_location') {
      _pendingLabel = result['label'] as String;
      _pendingIcon = result['icon'] as IconData? ?? Icons.location_on;

      setState(() => _isPickingFromMap = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tap the map to place "$_pendingLabel"'),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      final label = result['label'] as String;
      final lat = (result['lat'] as num).toDouble();
      final lng = (result['lng'] as num).toDouble();
      final icon = result['icon'] as IconData? ?? Icons.location_on;

      _addWaypoint(LatLng(lat, lng), label: label, icon: icon);
      _mapController.move(LatLng(lat, lng), _routeFocusZoom);
      setState(() => _currentZoom = _routeFocusZoom);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added: $label')));
    }
  }

  Future<void> _assignDriver() async {
    final selected = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => AssignDriverScreen(current: _assignedDriver),
      ),
    );

    if (!mounted || selected == null || selected == _assignedDriver) return;
    setState(() => _assignedDriver = selected);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Assigned: $selected')));
  }

  String _routeSummaryBody() {
    final lines = <String>[
      'Route: $_routeName',
      'Distance: ${_totalDistanceKm.toStringAsFixed(2)} km',
      'Waypoints: ${_waypoints.length}',
      if ((_assignedDriver ?? '').trim().isNotEmpty)
        'Assigned Driver: ${_assignedDriver!.trim()}',
      '',
      'Stops:',
    ];

    for (var i = 0; i < _waypoints.length; i++) {
      final waypoint = _waypoints[i];
      lines.add(
        '${i + 1}. ${waypoint.label} '
        '(${waypoint.point.latitude.toStringAsFixed(6)}, '
        '${waypoint.point.longitude.toStringAsFixed(6)})',
      );
    }

    return lines.join('\n');
  }

  Future<void> _emailRoute() async {
    if (!_isOptimized || _route.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Optimize route first')));
      return;
    }

    final subject = Uri.encodeComponent('Route Plan: $_routeName');
    final body = Uri.encodeComponent(_routeSummaryBody());
    final uri = Uri.parse('mailto:?subject=$subject&body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No mail app available on this device.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topOffset = AppUtils.appBarHeightCustom + 14;
    final rightTop = MediaQuery.of(context).size.height * 0.5 - 132;
    final bottomMargin = MediaQuery.of(context).padding.bottom + 24;

    final markers = _waypoints.map((w) {
      return Marker(
        point: w.point,
        width: 40,
        height: 40,
        child: GestureDetector(
          onLongPress: () => _showWaypointInfo(_waypoints.indexOf(w)),
          child: Icon(w.icon, size: 40, color: Colors.black),
        ),
      );
    }).toList();

    return AppLayout(
      title: 'MAP',
      subtitle: 'Route Optimization',
      actionIcons: const [],
      onActionTaps: const [],
      showAppBar: false,
      leftAvatarText: 'MP',
      showLeftAvatar: false,
      horizontalPadding: 0,
      child: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: _defaultMapZoom,
                  minZoom: 3,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onPositionChanged: (camera, hasGesture) {
                    _currentCenter = camera.center;
                    _currentZoom = camera.zoom;
                    if (mounted) setState(() {});
                  },
                  onTap: (tapPos, latlng) {
                    if (_isPickingFromMap && _pendingLabel != null) {
                      _addWaypoint(
                        latlng,
                        label: _pendingLabel!,
                        icon: _pendingIcon,
                      );
                      _mapController.move(latlng, _routeFocusZoom);
                      setState(() => _currentZoom = _routeFocusZoom);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Waypoint added from map'),
                        ),
                      );

                      setState(() {
                        _isPickingFromMap = false;
                        _pendingLabel = null;
                        _activeAddMode = null;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        _selectedTileOption.urlTemplate,
                    subdomains: _selectedTileOption.subdomains,
                    userAgentPackageName: 'com.example.fleek_stack_mobile',
                  ),
                  if (_route.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _route,
                          strokeWidth: 4.0,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  PopupMarkerLayer(
                    options: PopupMarkerLayerOptions(
                      markers: markers,
                      popupController: _popupLayerController,
                      popupDisplayOptions: PopupDisplayOptions(
                        builder: (BuildContext context, Marker marker) {
                          final waypoint = _waypoints.firstWhere(
                            (w) => w.point == marker.point,
                          );
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.onSurface.withValues(alpha: 0.12),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              waypoint.label,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        snap: PopupSnap.markerTop,
                        animation: const PopupAnimation.fade(
                          duration: Duration(milliseconds: 200),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: UserHomeAppBar(
                  title: 'Route Optimization',
                  leadingIcon: Icons.route_outlined,
                  borderRadius: 0,
                  onClose: () => context.go('/user/home'),
                ),
              ),
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
                          icon: Icons.edit,
                          label: 'Landmark',
                          selected: _activeAddMode == 'landmark',
                          onPressed:
                              (_loading || _saving || _deleting || _isOptimizing)
                              ? null
                              : () async {
                                  setState(() => _activeAddMode = 'landmark');
                                  await _handleAdd('landmark', context);
                                  if (mounted) setState(() => _activeAddMode = null);
                                },
                        ),
                        const SizedBox(width: 10),
                        _buildToolChip(
                          icon: Icons.touch_app,
                          label: 'Map location',
                          selected: _activeAddMode == 'map_location' || _isPickingFromMap,
                          onPressed:
                              (_loading || _saving || _deleting || _isOptimizing)
                              ? null
                              : () async {
                                  setState(() => _activeAddMode = 'map_location');
                                  await _handleAdd('map_location', context);
                                  if (mounted && !_isPickingFromMap) {
                                    setState(() => _activeAddMode = null);
                                  }
                                },
                        ),
                        const SizedBox(width: 10),
                        _buildToolChip(
                          icon: Icons.map,
                          label: 'Insert lat/lng',
                          selected: _activeAddMode == 'lat_lng',
                          onPressed:
                              (_loading || _saving || _deleting || _isOptimizing)
                              ? null
                              : () async {
                                  setState(() => _activeAddMode = 'lat_lng');
                                  await _handleAdd('lat_lng', context);
                                  if (mounted) setState(() => _activeAddMode = null);
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: rightTop - 84,
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
                      const SizedBox(height: 12),
                    ],
                    Tooltip(
                      message: _isMoreMenuOpen ? 'Collapse' : 'More',
                      child: glassMapControlButton(
                        context: context,
                        width: 44,
                        height: 44,
                        borderRadiusValue: _isMoreMenuOpen ? 0 : 9,
                        backgroundColor:
                            _isMoreMenuOpen ? Colors.transparent : null,
                        borderColorOverride:
                            _isMoreMenuOpen ? Colors.transparent : null,
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
              if (_isOptimized ||
                  _loading ||
                  _saving ||
                  _deleting ||
                  _isOptimizing)
                Positioned(
                  bottom: bottomMargin,
                  left: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_loading ||
                              _saving ||
                              _deleting ||
                              _isOptimizing) ...[
                            const AppShimmer(width: 180, height: 16, radius: 8),
                            const SizedBox(height: 8),
                            const AppShimmer(width: 120, height: 14, radius: 8),
                          ] else ...[
                            Text(
                              'Total Distance: ${_totalDistanceKm.toStringAsFixed(2)} km',
                            ),
                            if (_assignedDriver != null)
                              Text('Assigned Driver: $_assignedDriver'),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
