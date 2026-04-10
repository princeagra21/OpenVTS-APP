import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/user_route_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_routes_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/user/components/appbars/user_home_appbar.dart';
import 'package:fleet_stack/modules/user/screens/route/add_landmark_screen.dart';
import 'package:fleet_stack/modules/user/screens/route/add_lat_lng_screen.dart';
import 'package:fleet_stack/modules/user/screens/route/add_map_location_screen.dart';
import 'package:fleet_stack/modules/user/screens/route/assign_driver_screen.dart';
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
  final MapController _mapController = MapController();
  final PopupController _popupLayerController = PopupController();

  final LatLng _initialCenter = const LatLng(28.6139, 77.2090);
  late LatLng _currentCenter;
  double _currentZoom = 5.0;

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

  String? _assignedDriver;
  String? _loadedRouteId;
  String _routeName = 'Optimized Route';

  bool _isPickingFromMap = false;
  String? _pendingLabel;
  IconData _pendingIcon = Icons.location_on;

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
      final avgLat =
          coords.map((p) => p.latitude).reduce((a, b) => a + b) / coords.length;
      final avgLng =
          coords.map((p) => p.longitude).reduce((a, b) => a + b) /
          coords.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(LatLng(avgLat, avgLng), _currentZoom);
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
      final avgLat =
          _route.map((p) => p.latitude).reduce((a, b) => a + b) / _route.length;
      final avgLng =
          _route.map((p) => p.longitude).reduce((a, b) => a + b) /
          _route.length;
      _mapController.move(LatLng(avgLat, avgLng), _currentZoom);
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
      _mapController.move(LatLng(lat, lng), _currentZoom);

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
    final screenWidth = MediaQuery.of(context).size.width;

    final bottomBarHeight = AdaptiveUtils.getBottomBarHeight(screenWidth);
    final fabSize = AdaptiveUtils.getButtonSize(screenWidth);
    final iconSize = AdaptiveUtils.getIconSize(screenWidth);
    final topOffset = AppUtils.appBarHeightCustom;
    final bottomMargin =
        MediaQuery.of(context).padding.bottom + bottomBarHeight + 50;

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
      customTopBar: UserHomeAppBar(
        title: 'Route Optimization',
        leadingIcon: Icons.route_outlined,
        onClose: () => context.go('/user/home'),
      ),
      customTopBarPadding: EdgeInsets.zero,
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
                  onTap: (tapPos, latlng) {
                    if (_isPickingFromMap && _pendingLabel != null) {
                      _addWaypoint(
                        latlng,
                        label: _pendingLabel!,
                        icon: _pendingIcon,
                      );
                      _mapController.move(latlng, _currentZoom);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Waypoint added from map'),
                        ),
                      );

                      setState(() {
                        _isPickingFromMap = false;
                        _pendingLabel = null;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                  PopupMarkerLayerWidget(
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
                                  color: cs.onSurface.withOpacity(0.12),
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
                top: topOffset,
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
                          onPressed:
                              (_loading ||
                                  _saving ||
                                  _deleting ||
                                  _isOptimizing)
                              ? null
                              : () => _handleAdd('landmark', context),
                          icon: const Icon(Icons.edit),
                          label: 'Landmark',
                        ),
                        const SizedBox(width: 8),
                        TopActionButton(
                          onPressed:
                              (_loading ||
                                  _saving ||
                                  _deleting ||
                                  _isOptimizing)
                              ? null
                              : () => _handleAdd('map_location', context),
                          icon: const Icon(Icons.touch_app),
                          label: 'Map location',
                        ),
                        const SizedBox(width: 8),
                        TopActionButton(
                          onPressed:
                              (_loading ||
                                  _saving ||
                                  _deleting ||
                                  _isOptimizing)
                              ? null
                              : () => _handleAdd('lat_lng', context),
                          icon: const Icon(Icons.map),
                          label: 'Insert lat/long',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: bottomMargin + 10,
                child: Column(
                  children: [
                    Tooltip(
                      message: 'Zoom In',
                      child: _fab(
                        hero: 'zoom_in',
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
                        hero: 'zoom_out',
                        icon: Icons.remove,
                        size: fabSize,
                        iconSize: iconSize,
                        onTap: _zoomOut,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Tooltip(
                      message: 'Optimize Route',
                      child: _fab(
                        hero: 'optimize',
                        icon: Icons.autorenew,
                        size: fabSize,
                        iconSize: iconSize,
                        onTap:
                            (_loading || _saving || _deleting || _isOptimizing)
                            ? () {}
                            : () async => _optimizeRoute(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Tooltip(
                      message: 'Clear Route',
                      child: _fab(
                        hero: 'clear',
                        icon: Icons.clear,
                        size: fabSize,
                        iconSize: iconSize,
                        onTap:
                            (_loading || _saving || _deleting || _isOptimizing)
                            ? () {}
                            : () async => _clearWaypoints(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Tooltip(
                      message: 'Assign Driver',
                      child: _fab(
                        hero: 'assign_driver',
                        icon: Icons.person_add,
                        size: fabSize,
                        iconSize: iconSize,
                        // Backend does not expose a route-to-driver assignment API yet.
                        // This FAB currently stores the selected driver in local UI state only.
                        onTap:
                            (_loading || _saving || _deleting || _isOptimizing)
                            ? () {}
                            : _assignDriver,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Tooltip(
                      message: 'Email Route',
                      child: _fab(
                        hero: 'email_route',
                        icon: Icons.email,
                        size: fabSize,
                        iconSize: iconSize,
                        onTap: _emailRoute,
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
}
