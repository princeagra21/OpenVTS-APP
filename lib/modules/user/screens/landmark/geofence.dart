import 'dart:ui';
import 'dart:math' as math;
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/screens/landmark/add_buffer_screen.dart';
import 'package:fleet_stack/modules/user/screens/route/add_landmark_screen.dart';
import 'package:fleet_stack/modules/user/screens/route/add_lat_lng_screen.dart';
import 'package:fleet_stack/modules/user/screens/route/add_map_location_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import '../../layout/app_layout.dart';

enum GeofenceType {
  circle,
  polygon,
  rectangle,
  line,
  poi,
  route,
}

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
              child: Icon(Icons.close, color: Theme.of(context).colorScheme.primary),
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
        return Positioned(
          right: 4.0,
          bottom: 4.0 + offset.dy,
          child: child!,
        );
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

class GeofenceScreen extends StatefulWidget {
  const GeofenceScreen({super.key});

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
  final MapController _mapController = MapController();
  // ---- MAP STATE ----
  final LatLng _initialCenter = LatLng(28.6139, 77.2090);
  late LatLng _currentCenter;
  double _currentZoom = 5.0;
  // ---- GEOFENCE STATE ----
  final List<Geofence> _geofences = [];
  bool _isAddingGeofence = false;
  GeofenceType? _pendingGeofenceType;
  final List<LatLng> _tempPoints = [];
  // ---- POI Add ----
  bool _isPickingPOIFromMap = false;
  String? _pendingPOILabel;

  @override
  void initState() {
    super.initState();
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
        if (newGeofence.points.isEmpty || existing.points.isEmpty || newGeofence.radius == null || existing.radius == null) return false;
        final d = distance.as(LengthUnit.Meter, newGeofence.points[0], existing.points[0]);
        final rDiff = (newGeofence.radius! - existing.radius!).abs();
        return d < 100 && rDiff < 50; 
      case GeofenceType.polygon:
      case GeofenceType.rectangle:
      case GeofenceType.line:
      case GeofenceType.route:
        if (newGeofence.points.length < 2 || existing.points.length < 2) return false;
        final d1 = _directedHausdorff(newGeofence.points, existing.points);
        final d2 = _directedHausdorff(existing.points, newGeofence.points);
        final hausdorff = math.max(d1, d2);
        final double nw = newGeofence.width ?? 0.0;
        final double ew = existing.width ?? 0.0;
        final wDiff = (nw - ew).abs();
        return hausdorff < 100 && wDiff < 10;
    }
  }

  // Add geofence
  void _addGeofence(Geofence g) {
    for (var existing in _geofences) {
      if (_isTooSimilar(g, existing)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geofence too similar to an existing one')),
        );
        return;
      }
    }
    setState(() {
      _geofences.add(g);
    });
  }

  // Clear all geofences
  void _clearGeofences() {
    setState(() {
      _geofences.clear();
    });
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
        message = 'Tap map to add vertices, long press to finish (min 3 points)';
        break;
      case GeofenceType.line:
      case GeofenceType.route:
        message = 'Tap map to add points, long press to finish (min 2 points)';
        break;
    }
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Show screen for radius
  Future<void> _showRadiusScreen(LatLng center, {String label = 'Geofence'}) async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(builder: (_) => AddBufferScreen(isRadius: true, initialLabel: label)),
    );

    if (result != null) {
      final double radius = result['value'];
      final String newLabel = result['label'];
      _addGeofence(Geofence(
        type: _pendingGeofenceType!,
        label: newLabel,
        points: [center],
        radius: radius,
      ));
      setState(() => _isAddingGeofence = false);
    } else {
      setState(() => _isAddingGeofence = false);
    }
  }

  // Show screen for width
  Future<void> _showWidthScreen(List<LatLng> points, {String label = 'Geofence'}) async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(builder: (_) => AddBufferScreen(isRadius: false, initialLabel: label)),
    );

    if (result != null) {
      final double width = result['value'];
      final String newLabel = result['label'];
      _addGeofence(Geofence(
        type: _pendingGeofenceType!,
        label: newLabel,
        points: points,
        width: width,
      ));
      setState(() => _isAddingGeofence = false);
    } else {
      setState(() => _isAddingGeofence = false);
    }
  }

  // Handle POI addition from screens
  Future<void> _handleAddPOI(String type, BuildContext ctx) async {
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
    if (result == null) return;
    final label = result['label'] as String;
    if (type == 'map_location') {
      // Enable map picking for location
      _pendingPOILabel = label;
      setState(() {
        _isAddingGeofence = true;
        _pendingGeofenceType = GeofenceType.poi;
        _isPickingPOIFromMap = true;
      });
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Tap the map to place POI "$label"')),
      );
    } else {
      // Direct add from lat/lng or landmark
      final lat = (result['lat'] as num).toDouble();
      final lng = (result['lng'] as num).toDouble();
      final point = LatLng(lat, lng);
      _mapController.move(point, _currentZoom);
      await _showRadiusScreen(point, label: label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomBarHeight = AdaptiveUtils.getBottomBarHeight(screenWidth);
    final fabSize = AdaptiveUtils.getButtonSize(screenWidth);
    final iconSize = AdaptiveUtils.getIconSize(screenWidth);
    final bottomMargin = MediaQuery.of(context).padding.bottom + bottomBarHeight + 50;

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
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                  onPositionChanged: (camera, _) {
                    _currentCenter = camera.center;
                    _currentZoom = camera.zoom;
                    if (mounted) setState(() {});
                  },
                  onTap: (tapPos, latlng) {
                    if (_isAddingGeofence && _pendingGeofenceType != null) {
                      _tempPoints.add(latlng);
                      switch (_pendingGeofenceType) {
                        case GeofenceType.circle:
                          _showRadiusScreen(latlng);
                          break;
                        case GeofenceType.poi:
                          if (_isPickingPOIFromMap && _pendingPOILabel != null) {
                            _showRadiusScreen(latlng, label: _pendingPOILabel!);
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
                            final minLat = p1.latitude < p2.latitude ? p1.latitude : p2.latitude;
                            final maxLat = p1.latitude > p2.latitude ? p1.latitude : p2.latitude;
                            final minLng = p1.longitude < p2.longitude ? p1.longitude : p2.longitude;
                            final maxLng = p1.longitude > p2.longitude ? p1.longitude : p2.longitude;
                            final points = [
                              LatLng(minLat, minLng),
                              LatLng(minLat, maxLng),
                              LatLng(maxLat, maxLng),
                              LatLng(maxLat, minLng),
                            ];
                            _addGeofence(Geofence(
                              type: GeofenceType.rectangle,
                              label: 'Rectangle Geofence',
                              points: points,
                            ));
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
                  onLongPress: (tapPos, latlng) {
                    if (_isAddingGeofence && _pendingGeofenceType != null) {
                      switch (_pendingGeofenceType) {
                        case GeofenceType.polygon:
                          if (_tempPoints.length >= 3) {
                            List<LatLng> points = List.from(_tempPoints);
                            points.add(_tempPoints.first); // Close polygon
                            _addGeofence(Geofence(
                              type: GeofenceType.polygon,
                              label: 'Polygon Geofence',
                              points: points,
                            ));
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
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  // Geofence layers (safe: only include when points/radius/width exist)
CircleLayer(
  circles: _geofences
      .where((g) =>
          (g.type == GeofenceType.circle || g.type == GeofenceType.poi) &&
          g.points.isNotEmpty &&
          g.radius != null)
      .map((g) => CircleMarker(
            point: g.points[0],
            radius: g.radius!,
            color: g.color.withOpacity(0.3),
            borderColor: g.color,
            borderStrokeWidth: 2,
          ))
      .toList(),
),

PolygonLayer(
  polygons: _geofences
      .where((g) =>
          (g.type == GeofenceType.polygon || g.type == GeofenceType.rectangle) &&
          g.points.length >= 3) // polygon needs >=3 (rectangle will be 4)
      .map((g) => Polygon(
            points: g.points,
            color: g.color.withOpacity(0.3),
            borderColor: g.color,
            borderStrokeWidth: 2,
          ))
      .toList(),
),

PolylineLayer(
  polylines: _geofences
      .where((g) =>
          (g.type == GeofenceType.line || g.type == GeofenceType.route) &&
          g.points.length >= 2 &&
          (g.width ?? 0) > 0)
      .map((g) => Polyline(
            points: g.points,
            color: g.color,
            strokeWidth: g.width ?? 5.0,
          ))
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
                          onPressed: () => _startAddingGeofence(GeofenceType.circle),
                          icon: const Icon(Icons.circle_outlined),
                          label: 'Circle',
                        ),
                        const SizedBox(width: 8),
                        TopActionButton(
                          onPressed: () => _startAddingGeofence(GeofenceType.polygon),
                          icon: const Icon(Icons.polyline_outlined),
                          label: 'Polygon',
                        ),
                        const SizedBox(width: 8),
                        TopActionButton(
                          onPressed: () => _startAddingGeofence(GeofenceType.rectangle),
                          icon: const Icon(Icons.rectangle_outlined),
                          label: 'Rectangle',
                        ),
                        const SizedBox(width: 8),
                        TopActionButton(
                          onPressed: () => _startAddingGeofence(GeofenceType.line),
                          icon: const Icon(Icons.timeline),
                          label: 'Line',
                        ),
                        const SizedBox(width: 8),
                        TopActionButton(
                          onPressed: () => _startAddingGeofence(GeofenceType.route),
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
                      message: 'Clear Geofences',
                      child: _fab(
                        hero: "clear",
                        icon: Icons.clear,
                        size: fabSize,
                        iconSize: iconSize,
                        onTap: _clearGeofences,
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
    _mapController.dispose();
    super.dispose();
  }
}