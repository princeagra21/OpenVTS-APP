import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/map_vehicle_point.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../layout/app_layout.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
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
            _points = items.where((e) => e.hasValidPoint).toList();
            _loading = false;
            _errorShown = false;
          });
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

  List<MapVehiclePoint> get _filteredPoints {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _points;
    return _points.where((p) {
      final plate = p.plateNumber.toLowerCase();
      final imei = p.imei.toLowerCase();
      final status = p.status.toLowerCase();
      return plate.contains(q) || imei.contains(q) || status.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double height = AdaptiveUtils.getBottomBarHeight(screenWidth);

    final fabSize = AdaptiveUtils.getButtonSize(screenWidth);
    final iconSize = AdaptiveUtils.getIconSize(screenWidth);

    final bottomMargin = MediaQuery.of(context).padding.bottom + height + 50;

    final cs = Theme.of(context).colorScheme; // <--- color scheme shortcut
    final brand = cs.primary;
    final onBrand = cs.onPrimary;
    final pointsToRender = _filteredPoints;
    final markers = pointsToRender.isEmpty
        ? [
            Marker(
              point: _initialCenter,
              width: 80,
              height: 80,
              child: Icon(Icons.location_on, size: 40, color: brand),
            ),
          ]
        : pointsToRender
              .map(
                (p) => Marker(
                  point: LatLng(p.lat, p.lng),
                  width: 80,
                  height: 80,
                  child: GestureDetector(
                    onTap: () {
                      if (p.vehicleId.trim().isEmpty) return;
                      context.push(
                        "/superadmin/vehicles/details/${p.vehicleId}",
                      );
                    },
                    child: Icon(Icons.location_on, size: 40, color: brand),
                  ),
                ),
              )
              .toList();

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
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.fleek_stack_mobile',
                  tileProvider: NetworkTileProvider(
                    cachingProvider: const DisabledMapCachingProvider(),
                  ),
                ),
                MarkerLayer(markers: markers),
              ],
            ),

            // ---------------- ACTION BUTTONS ----------------
            Positioned(
              right: 16,
              bottom: bottomMargin,
              child: Column(
                children: [
                  // Search FAB
                  SizedBox(
                    width: fabSize,
                    height: fabSize,
                    child: FloatingActionButton(
                      heroTag: "map_search",
                      backgroundColor: brand,
                      foregroundColor: onBrand,
                      onPressed: _openSearch,
                      child: Icon(Icons.search, size: iconSize),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Zoom In FAB
                  SizedBox(
                    width: fabSize,
                    height: fabSize,
                    child: FloatingActionButton(
                      heroTag: "map_zoom_in",
                      backgroundColor: brand,
                      foregroundColor: onBrand,
                      onPressed: _zoomIn,
                      child: Icon(Icons.add, size: iconSize),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Zoom Out FAB
                  SizedBox(
                    width: fabSize,
                    height: fabSize,
                    child: FloatingActionButton(
                      heroTag: "map_zoom_out",
                      backgroundColor: brand,
                      foregroundColor: onBrand,
                      onPressed: _zoomOut,
                      child: Icon(Icons.remove, size: iconSize),
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- ZOOM DEBUG BOX ----------------
            Positioned(
              right: 16,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: brand.withOpacity(0.3),
                  ), // active color
                ),
                child: Row(
                  children: [
                    Text(
                      "Zoom: ${_currentZoom.toStringAsFixed(1)}",
                      style: TextStyle(color: cs.onSurface),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: _loading
                          ? const AppShimmer(width: 12, height: 12, radius: 6)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // ---------------- SEARCH BAR ----------------
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              top: _showSearch ? 10 : -120,
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
                          color: brand.withOpacity(0.3),
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
