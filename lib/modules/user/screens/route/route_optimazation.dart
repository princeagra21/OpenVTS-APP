import 'dart:ui';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/screens/route/add_landmark_screen.dart';
import 'package:fleet_stack/modules/user/screens/route/add_lat_lng_screen.dart';
import 'package:fleet_stack/modules/user/screens/route/add_map_location_screen.dart';
import 'package:fleet_stack/modules/user/screens/route/assign_driver_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_route_service/open_route_service.dart';
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
  Waypoint({
    required this.point,
    required this.label,
    required this.icon,
  });
}

class TopActionButton extends StatelessWidget {
  const TopActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
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
  final MapController _mapController = MapController();
  final PopupController _popupLayerController = PopupController();

  late final OpenRouteService client;

  // ---- MAP STATE ----
  final LatLng _initialCenter = LatLng(28.6139, 77.2090);
  late LatLng _currentCenter;
  double _currentZoom = 5.0;

  // ---- ROUTE STATE ----
  final List<Waypoint> _waypoints = []; // holds waypoints with metadata
  List<LatLng> _route = []; // optimized route order (polyline)
  bool _isOptimized = false;
  double _totalDistanceKm = 0.0; // Total route distance in km
  bool _isOptimizing = false; // Loading state

  // ---- Driver Assignment ----
  String? _assignedDriver;

  // ---- UI / Add dialog ----
  bool _isPickingFromMap = false; // when true, next map tap will add waypoint
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  String? _pendingLabel;
  IconData _pendingIcon = Icons.location_on;

  @override
  void initState() {
    super.initState();
    client = OpenRouteService(
        apiKey:
            'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImY2NTk4MGZlZjBmMTRjOTY5M2YxMDE1YzgzMGU2ZTA1IiwiaCI6Im11cm11cjY0In0=');
    _currentCenter = _initialCenter;
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

  // Add waypoint programmatically (always adds a Waypoint instance)
  void _addWaypoint(LatLng p, {required String label, IconData? icon}) {
    setState(() {
      _waypoints.add(Waypoint(point: p, label: label, icon: icon ?? Icons.place));
      _isOptimized = false;
      _route.clear();
      _totalDistanceKm = 0.0;
    });
  }

  void _removeWaypoint(int index) {
    setState(() {
      if (index >= 0 && index < _waypoints.length) {
        _waypoints.removeAt(index);
        _isOptimized = false;
        _route.clear();
        _totalDistanceKm = 0.0;
      }
    });
  }

  // Show waypoint info and option to remove
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
            Row(
              children: [
                const Text('Icon: '),
                Icon(waypoint.icon, ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
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

  // Clear everything
  void _clearWaypoints() {
    setState(() {
      _waypoints.clear();
      _route.clear();
      _isOptimized = false;
      _totalDistanceKm = 0.0;
      _assignedDriver = null;
    });
  }

  // Calculate total distance in km using Haversine
  double _calculateTotalDistance(List<LatLng> route) {
    final Distance distance = const Distance();
    double total = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      total += distance.as(LengthUnit.Kilometer, route[i], route[i + 1]);
    }
    return total;
  }

  // Simple 2-opt improvement for better optimization
  List<LatLng> _twoOptImprove(List<LatLng> route) {
    final Distance distance = const Distance();
    bool improved = true;
    while (improved) {
      improved = false;
      for (int i = 1; i < route.length - 2; i++) {
        for (int j = i + 2; j < route.length - 1; j++) {
          final double oldDist = distance.as(LengthUnit.Meter, route[i - 1], route[i]) +
              distance.as(LengthUnit.Meter, route[j], route[j + 1]);
          final double newDist = distance.as(LengthUnit.Meter, route[i - 1], route[j]) +
              distance.as(LengthUnit.Meter, route[i], route[j + 1]);
          if (newDist < oldDist) {
            // Reverse segment i to j
            final reversed = route.sublist(i, j + 1).reversed.toList();
            route.replaceRange(i, j + 1, reversed);
            improved = true;
          }
        }
      }
    }
    return route;
  }

  /// Enhanced route optimizer with greedy + 2-opt
  Future<void> _optimizeRoute() async {
    if (_waypoints.length <= 1) {
      setState(() {
        _route
          ..clear()
          ..addAll(_waypoints.map((w) => w.point));
        _isOptimized = true;
        _totalDistanceKm = _calculateTotalDistance(_route);
      });
      return;
    }

    setState(() => _isOptimizing = true);

    final Distance distance = const Distance();
    List<LatLng> remaining = _waypoints.map((w) => w.point).toList(growable: true);
    List<LatLng> ordered = [];

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

    // Apply 2-opt for deeper optimization
    ordered = _twoOptImprove(ordered);

    // Fetch real road route using OpenRouteService
    List<LatLng> realRoute = [];
    double apiDistance = 0.0;

    try {
      final List<ORSCoordinate> orsCoords = ordered.map((p) => ORSCoordinate(latitude: p.latitude, longitude: p.longitude)).toList();
      final GeoJsonFeatureCollection geoJson = await client.directionsMultiRouteGeoJsonPost(
        coordinates: orsCoords,
        profileOverride: ORSProfile.drivingCar, // Adjust profile as needed (e.g., cyclingElectric, footWalking)
        units: 'km', // Request distances in km
      );

      if (geoJson.features.isNotEmpty) {
        final GeoJsonFeature feature = geoJson.features.first;
        final GeoJsonFeatureGeometry geometry = feature.geometry;

        if (geometry.type == 'LineString' && geometry.coordinates.isNotEmpty) {
          realRoute = geometry.coordinates.first.map((c) => LatLng(c.latitude, c.longitude)).toList();
        }

        final dynamic summary = feature.properties['summary'];
        if (summary != null && summary['distance'] != null) {
          apiDistance = (summary['distance'] as num).toDouble();
        }
      }
    } catch (e) {
      // Handle API errors (e.g., invalid key, network issue) and fall back
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to fetch road route: $e. Using straight-line fallback.'),
      ));
    }

    if (realRoute.isEmpty) {
      realRoute = ordered;
      apiDistance = _calculateTotalDistance(realRoute);
    }

    setState(() {
      _route
        ..clear()
        ..addAll(realRoute.isNotEmpty ? realRoute : ordered);
      _isOptimized = true;
      _totalDistanceKm = apiDistance > 0 ? apiDistance : _calculateTotalDistance(_route);
      _isOptimizing = false;
    });

    // Center map on route average
    if (_route.isNotEmpty) {
      final avgLat = _route.map((p) => p.latitude).reduce((a, b) => a + b) / _route.length;
      final avgLng = _route.map((p) => p.longitude).reduce((a, b) => a + b) / _route.length;
      _mapController.move(LatLng(avgLat, avgLng), _currentZoom);
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Optimized route: ${_totalDistanceKm.toStringAsFixed(2)} km'),
    ));
  }

  Future<void> _handleAdd(String type, BuildContext ctx) async {
    Widget screen;
    if (type == 'landmark') {
      screen = const AddLandmarkScreen();
    } else if (type == 'lat_lng') {
      screen = const AddLatLngScreen();
    } else if (type == 'map_location') {
      screen = const AddMapLocationScreen(); // New full-screen
    } else {
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>?>(
      ctx,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (result == null) return;

    if (type == 'map_location') {
      // Special handling: store metadata and enable picking
      _pendingLabel = result['label'] as String;
      _pendingIcon = result['icon'] as IconData? ?? Icons.location_on;

      setState(() => _isPickingFromMap = true);

      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Tap the map to place "${_pendingLabel}"'),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Landmark or Lat/Lng: direct add
      final label = result['label'] as String;
      final lat = (result['lat'] as num).toDouble();
      final lng = (result['lng'] as num).toDouble();
      final icon = result['icon'] as IconData? ?? Icons.location_on;

      _addWaypoint(LatLng(lat, lng), label: label, icon: icon);
      _mapController.move(LatLng(lat, lng), _currentZoom);

      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Added: $label')),
      );
    }
  }

  // Updated assign driver to use full screen
  Future<void> _assignDriver() async {
    final selected = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => AssignDriverScreen(current: _assignedDriver),
      ),
    );

    if (selected != null && selected != _assignedDriver) {
      setState(() => _assignedDriver = selected);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned: $selected')),
      );
    }
  }

  // Email route details
  void _emailRoute() {
    if (!_isOptimized) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Optimize route first'),
      ));
      return;
    }

    final String waypointsList = _waypoints.map((w) => '- ${w.label} (${w.point.latitude}, ${w.point.longitude})').join('\n');
    final String body = 'Optimized Route Details:\n\nWaypoints:\n$waypointsList\n\nTotal Distance: ${_totalDistanceKm.toStringAsFixed(2)} km\nAssigned Driver: ${_assignedDriver ?? 'None'}';
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'recipient@example.com', // Replace with actual email
      query: 'subject=Optimized Route&body=${Uri.encodeComponent(body)}',
    );

    launchUrl(emailUri);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    final bottomBarHeight = AdaptiveUtils.getBottomBarHeight(screenWidth);
    final fabSize = AdaptiveUtils.getButtonSize(screenWidth);
    final iconSize = AdaptiveUtils.getIconSize(screenWidth);
    final bottomMargin = MediaQuery.of(context).padding.bottom + bottomBarHeight + 50;

    final List<Marker> markers = _waypoints.map((w) {
      return Marker(
        point: w.point,
        width: 40,
        height: 40,
        child: GestureDetector(
          onLongPress: () => _showWaypointInfo(_waypoints.indexOf(w)),
          child: Icon(
            w.icon,
            size: 40,
            color:  Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.black,
          ),
        ),
      );
    }).toList();

    return AppLayout(
      title: "MAP",
      subtitle: "Route Optimization",
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
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                  onPositionChanged: (camera, _) {
                    _currentCenter = camera.center;
                    _currentZoom = camera.zoom;
                    if (mounted) setState(() {});
                  },
                  onTap: (tapPos, latlng) {
                    if (_isPickingFromMap && _pendingLabel != null) {
                      _addWaypoint(latlng, label: _pendingLabel!, icon: _pendingIcon);
                      _mapController.move(latlng, _currentZoom);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Waypoint added from map')),
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
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  if (_route.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _route,
                          strokeWidth: 4.0,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue
                              : Colors.blue,
                        ),
                      ],
                    ),
                  PopupMarkerLayerWidget(
                    options: PopupMarkerLayerOptions(
                      markers: markers,
                      popupController: _popupLayerController,
                      popupDisplayOptions: PopupDisplayOptions(
                        builder: (BuildContext context, Marker marker) {
                          final waypoint = _waypoints.firstWhere((w) => w.point == marker.point);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        animation: const PopupAnimation.fade(duration: Duration(milliseconds: 200)),
                      ),
                    ),
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
                          onPressed: () => _handleAdd('landmark', context),
                          icon: const Icon(Icons.edit),
                          label: 'Landmark',
                        ),
                        const SizedBox(width: 8),
                        TopActionButton(
                          onPressed: () => _handleAdd('map_location', context),
                          icon: const Icon(Icons.touch_app),
                          label: 'Map location',
                        ),
                        const SizedBox(width: 8),
                        TopActionButton(
                          onPressed: () => _handleAdd('lat_lng', context),
                          icon: const Icon(Icons.map),
                          label: 'Insert lat/long',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ================= RIGHT CONTROLS (Zoom, Optimize, Clear, Assign, Email) =================
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
                      message: 'Optimize Route',
                      child: _fab(
                        hero: "optimize",
                        icon: Icons.autorenew,
                        size: fabSize,
                        iconSize: iconSize,
                        onTap: () async => await _optimizeRoute(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Tooltip(
                      message: 'Clear Route',
                      child: _fab(
                        hero: "clear",
                        icon: Icons.clear,
                        size: fabSize,
                        iconSize: iconSize,
                        onTap: _clearWaypoints,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Tooltip(
                      message: 'Assign Driver',
                      child: _fab(
                        hero: "assign_driver",
                        icon: Icons.person_add,
                        size: fabSize,
                        iconSize: iconSize,
                        onTap: _assignDriver,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Tooltip(
                      message: 'Email Route',
                      child: _fab(
                        hero: "email_route",
                        icon: Icons.email,
                        size: fabSize,
                        iconSize: iconSize,
                        onTap: _emailRoute,
                      ),
                    ),
                  ],
                ),
              ),

              // ================= ROUTE INFO DISPLAY =================
              if (_isOptimized)
                Positioned(
                  bottom: bottomMargin,
                  left: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Distance: ${_totalDistanceKm.toStringAsFixed(2)} km'),
                          if (_assignedDriver != null) Text('Assigned Driver: $_assignedDriver'),
                        ],
                      ),
                    ),
                  ),
                ),

              // Loading indicator
              if (_isOptimizing)
                const Center(child: CircularProgressIndicator()),
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
    _landmarkController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}