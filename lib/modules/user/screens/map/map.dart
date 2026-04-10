import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/map_vehicle_point.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_map_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/user/components/appbars/user_home_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../layout/app_layout.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const String _mapTypePrefKey = 'user_map_type';

  // FleetStack-API-Reference.md confirmed endpoints:
  // - GET /user/map-telemetry
  // - GET /user/vehicles/by-imei/:imei/trail
  // - GET /user/vehicles/by-imei/:imei/replay
  // - GET /user/vehicles/by-imei/:imei/history
  // Response keys handled in MapVehiclePoint:
  // - id/vehicleId, imei, plate/name, lat/lng, speed/status/heading
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  bool _showSearch = false;

  final LatLng _initialCenter = const LatLng(28.6139, 77.2090);
  late LatLng _currentCenter;
  double _currentZoom = 13.0;

  String _mapMode = 'live';
  String _mapType = 'satellite';
  bool _trafficEnabled = false;
  bool _controlPanelExpanded = false;

  final ExpansionTileController _mapModeController = ExpansionTileController();
  final ExpansionTileController _mapTypeController = ExpansionTileController();

  List<MapVehiclePoint> _points = const <MapVehiclePoint>[];
  List<MapVehiclePoint> _modePoints = const <MapVehiclePoint>[];
  bool _loading = false;
  bool _errorShown = false;
  bool _modeErrorShown = false;
  bool _isLoadingGuard = false;
  String _query = '';
  String _activeModeImei = '';
  int _playbackIndex = 0;
  DateTime? _lastModeHintAt;

  CancelToken? _token;
  Timer? _refreshTimer;
  Timer? _playbackTimer;
  Timer? _modeDebounce;

  ApiClient? _apiClient;
  UserMapRepository? _repo;

  UserMapRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserMapRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  List<MapVehiclePoint> get _filteredPoints {
    final q = _query.trim().toLowerCase();
    final source = _points.where((p) => p.hasValidPoint).toList();
    if (q.isEmpty) return source;

    return source.where((p) {
      return p.plateNumber.toLowerCase().contains(q) ||
          p.imei.toLowerCase().contains(q) ||
          p.status.toLowerCase().contains(q);
    }).toList();
  }

  DateTime _safeParseDate(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

    final numeric = int.tryParse(value);
    if (numeric != null) {
      if (numeric > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(
          numeric,
          isUtc: true,
        ).toLocal();
      }
      if (numeric > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(
          numeric * 1000,
          isUtc: true,
        ).toLocal();
      }
    }

    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  MapVehiclePoint? _resolveModeTarget() {
    final visible = _filteredPoints
        .where((p) => p.imei.trim().isNotEmpty)
        .toList();
    if (visible.isEmpty) return null;

    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      return visible.length == 1 ? visible.first : null;
    }

    final exact = visible.where((p) {
      return p.imei.toLowerCase() == q || p.plateNumber.toLowerCase() == q;
    }).toList();
    if (exact.length == 1) return exact.first;

    return visible.length == 1 ? visible.first : null;
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _playbackIndex = 0;
  }

  void _focusPoints(List<MapVehiclePoint> points) {
    if (points.isEmpty) return;
    final target = points.last;
    if (!target.hasValidPoint) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(LatLng(target.lat, target.lng), _currentZoom);
    });
  }

  void _startPlayback(List<MapVehiclePoint> points) {
    _stopPlayback();
    if (points.isEmpty) return;

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted || _mapMode != 'playback') {
        timer.cancel();
        return;
      }
      final nextIndex = _playbackIndex + 1;
      if (nextIndex >= points.length) {
        timer.cancel();
        return;
      }
      final nextPoint = points[nextIndex];
      setState(() => _playbackIndex = nextIndex);
      if (nextPoint.hasValidPoint) {
        _mapController.move(LatLng(nextPoint.lat, nextPoint.lng), _currentZoom);
      }
    });
  }

  void _showModeHint(String message) {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastModeHintAt != null &&
        now.difference(_lastModeHintAt!).inMilliseconds < 1200) {
      return;
    }
    _lastModeHintAt = now;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadMapPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedType = (prefs.getString(_mapTypePrefKey) ?? '').trim();
    if (!mounted) return;
    if (savedType == 'standard' || savedType == 'satellite') {
      setState(() => _mapType = savedType);
    }
  }

  Future<void> _setMapType(String nextType) async {
    if (nextType == _mapType) return;
    if (!mounted) return;
    setState(() => _mapType = nextType);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mapTypePrefKey, nextType);
  }

  Future<void> _loadModeData(String mode, String imei) async {
    if (_isLoadingGuard) return;
    _isLoadingGuard = true;

    _stopPlayback();
    _token?.cancel('Reload user map mode data');
    final token = CancelToken();
    _token = token;

    if (mounted) {
      setState(() => _loading = true);
    }

    final repo = _repoOrCreate();
    final now = DateTime.now();
    final from = now.subtract(const Duration(hours: 24));

    final result = mode == 'playback'
        ? await repo.getVehicleReplayByImei(
            imei,
            from: from,
            to: now,
            maxPoints: 500,
            cancelToken: token,
          )
        : mode == 'history'
        ? await repo.getVehicleHistoryByImei(
            imei,
            from: from,
            to: now,
            maxPoints: 500,
            cancelToken: token,
          )
        : await repo.getVehicleTrailByImei(
            imei,
            hours: 24,
            maxPoints: 500,
            cancelToken: token,
          );

    if (!mounted) {
      _isLoadingGuard = false;
      return;
    }

    result.when(
      success: (items) {
        final valid = items.where((p) => p.hasValidPoint).toList()
          ..sort(
            (a, b) => _safeParseDate(
              a.updatedAt,
            ).compareTo(_safeParseDate(b.updatedAt)),
          );
        setState(() {
          _modePoints = valid;
          _activeModeImei = imei;
          _playbackIndex = 0;
          _loading = false;
          _modeErrorShown = false;
        });
        _focusPoints(valid);
        if (mode == 'playback') {
          _startPlayback(valid);
        }
      },
      failure: (err) {
        setState(() => _loading = false);
        if (_isCancelled(err) || _modeErrorShown) {
          _isLoadingGuard = false;
          return;
        }
        _modeErrorShown = true;
        final message = err is ApiException
            ? err.message
            : "Couldn't load map mode data.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );

    _isLoadingGuard = false;
  }

  Future<void> _setMapMode(String nextMode) async {
    if (nextMode == _mapMode) return;

    if (nextMode == 'live') {
      _stopPlayback();
      if (mounted) {
        setState(() {
          _mapMode = 'live';
          _modePoints = const <MapVehiclePoint>[];
          _activeModeImei = '';
        });
      }
      await _loadTelemetry(showShimmer: false);
      return;
    }

    final target = _resolveModeTarget();
    if (target == null) {
      if (mounted) {
        setState(() {
          _mapMode = 'live';
          _modePoints = const <MapVehiclePoint>[];
          _activeModeImei = '';
        });
      }
      _showModeHint(
        'Search a single vehicle by plate or IMEI to use ${nextMode == 'history' ? 'History' : 'Playback'}.',
      );
      return;
    }

    if (mounted) {
      setState(() => _mapMode = nextMode);
    }
    await _loadModeData(nextMode, target.imei.trim());
  }

  Future<void> _loadTelemetry({bool showShimmer = true}) async {
    if (_isLoadingGuard) return;
    _isLoadingGuard = true;

    _token?.cancel('Reload user map telemetry');
    final token = CancelToken();
    _token = token;

    if (showShimmer && mounted) {
      setState(() => _loading = true);
    }

    final result = await _repoOrCreate().getTelemetry(cancelToken: token);

    if (!mounted) {
      _isLoadingGuard = false;
      return;
    }

    result.when(
      success: (items) {
        final valid = items.where((p) => p.hasValidPoint).toList();
        setState(() {
          _points = valid;
          if (_mapMode == 'live') {
            _modePoints = const <MapVehiclePoint>[];
            _activeModeImei = '';
          }
          _loading = false;
          _errorShown = false;
        });
      },
      failure: (err) {
        setState(() => _loading = false);
        if (_isCancelled(err) || _errorShown) {
          _isLoadingGuard = false;
          return;
        }
        _errorShown = true;
        final message = err is ApiException
            ? err.message
            : "Couldn't load map telemetry.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );

    _isLoadingGuard = false;
  }

  @override
  void initState() {
    super.initState();
    _currentCenter = _initialCenter;
    _searchController.addListener(_onSearchChanged);
    _loadMapPreferences();
    _loadTelemetry();
    _refreshTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_mapMode == 'live') {
        _loadTelemetry(showShimmer: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _playbackTimer?.cancel();
    _modeDebounce?.cancel();
    _token?.cancel('User MapScreen disposed');
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _query = _searchController.text);

    if (_mapMode == 'live') return;

    _modeDebounce?.cancel();
    _modeDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || _mapMode == 'live') return;
      final target = _resolveModeTarget();
      if (target == null) {
        _stopPlayback();
        setState(() {
          _modePoints = const <MapVehiclePoint>[];
          _activeModeImei = '';
        });
        return;
      }
      if (target.imei.trim() == _activeModeImei && _modePoints.isNotEmpty) {
        return;
      }
      _loadModeData(_mapMode, target.imei.trim());
    });
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

  void _closeControlPanel() {
    _mapModeController.collapse();
    _mapTypeController.collapse();
    setState(() => _controlPanelExpanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    final bottomBarHeight = AdaptiveUtils.getBottomBarHeight(screenWidth);
    final fabSize = AdaptiveUtils.getButtonSize(screenWidth);
    final iconSize = AdaptiveUtils.getIconSize(screenWidth);
    final topOffset =
        MediaQuery.of(context).padding.top + AppUtils.appBarHeightCustom + 16;
    final bottomMargin =
        MediaQuery.of(context).padding.bottom + bottomBarHeight + 50;

    final visiblePoints = _filteredPoints;
    final modePoints = _modePoints.where((p) => p.hasValidPoint).toList();
    final showHistory = _mapMode == 'history' && modePoints.isNotEmpty;
    final showPlayback = _mapMode == 'playback' && modePoints.isNotEmpty;

    final trailCoords = showHistory
        ? modePoints.map((p) => LatLng(p.lat, p.lng)).toList()
        : showPlayback
        ? modePoints
              .take((_playbackIndex + 1).clamp(0, modePoints.length))
              .map((p) => LatLng(p.lat, p.lng))
              .toList()
        : const <LatLng>[];

    final markers = showHistory
        ? <Marker>[
            Marker(
              point: LatLng(modePoints.last.lat, modePoints.last.lng),
              width: 80,
              height: 80,
              child: Icon(Icons.location_on, size: 40, color: cs.primary),
            ),
          ]
        : showPlayback
        ? <Marker>[
            Marker(
              point: LatLng(
                modePoints[_playbackIndex.clamp(0, modePoints.length - 1)].lat,
                modePoints[_playbackIndex.clamp(0, modePoints.length - 1)].lng,
              ),
              width: 80,
              height: 80,
              child: Icon(Icons.location_on, size: 40, color: cs.primary),
            ),
          ]
        : visiblePoints.isEmpty
        ? <Marker>[
            Marker(
              point: _initialCenter,
              width: 80,
              height: 80,
              child: Icon(Icons.location_on, size: 40, color: cs.primary),
            ),
          ]
        : visiblePoints
              .map(
                (point) => Marker(
                  point: LatLng(point.lat, point.lng),
                  width: 80,
                  height: 80,
                  child: Icon(Icons.location_on, size: 40, color: cs.primary),
                ),
              )
              .toList();

    return AppLayout(
      title: 'MAP',
      subtitle: 'Vehicle Locations',
      customTopBar: UserHomeAppBar(
        title: 'Vehicle Locations',
        leadingIcon: Icons.map_outlined,
        onClose: () => context.go('/user/home'),
      ),
      customTopBarPadding: EdgeInsets.zero,
      actionIcons: const [],
      leftAvatarText: 'MP',
      showAppBar: false,
      horizontalPadding: 0,
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
              ),
              children: [
                TileLayer(
                  urlTemplate: _mapType == 'satellite'
                      ? 'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fleek_stack_mobile',
                ),
                if (trailCoords.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: trailCoords,
                        strokeWidth: 4,
                        color: cs.primary,
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
              ],
            ),
            Positioned(
              left: 16,
              bottom: bottomMargin + 10,
              child: Column(
                children: [
                  _fab(
                    hero: 'search',
                    icon: Icons.search,
                    size: fabSize,
                    iconSize: iconSize,
                    onTap: _openSearch,
                  ),
                  const SizedBox(height: 12),
                  _fab(
                    hero: 'zoom_in',
                    icon: Icons.add,
                    size: fabSize,
                    iconSize: iconSize,
                    onTap: _zoomIn,
                  ),
                  const SizedBox(height: 12),
                  _fab(
                    hero: 'zoom_out',
                    icon: Icons.remove,
                    size: fabSize,
                    iconSize: iconSize,
                    onTap: _zoomOut,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              top: topOffset,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_controlPanelExpanded) _controlContainer(cs),
                  if (_controlPanelExpanded) const SizedBox(height: 12),
                  _fab(
                    hero: 'controls',
                    icon: Icons.tune,
                    size: fabSize,
                    iconSize: iconSize,
                    onTap: () => setState(
                      () => _controlPanelExpanded = !_controlPanelExpanded,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              top: _showSearch ? topOffset : -120,
              left: 0,
              right: 0,
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
                        border: Border.all(color: cs.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          _loading
                              ? const AppShimmer(
                                  width: 12,
                                  height: 12,
                                  radius: 6,
                                )
                              : Icon(
                                  Icons.search,
                                  color: cs.onSurface.withOpacity(0.6),
                                ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Search location',
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _closeSearch(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _closeSearch,
                            child: const Icon(Icons.close, size: 18),
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

  Widget _controlContainer(ColorScheme cs) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitleWithIcon(Icons.map, 'Map Controls'),
                GestureDetector(
                  onTap: _closeControlPanel,
                  child: Icon(Icons.close, size: 20, color: cs.onSurface),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExpansionTile(
                  controller: _mapModeController,
                  title: _sectionTitleWithIcon(Icons.location_on, 'Map Mode'),
                  initiallyExpanded: false,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(left: 16),
                  children: [
                    _radio(
                      'Live Tracking',
                      'live',
                      _mapMode,
                      _setMapMode,
                      icon: Icons.gps_fixed,
                    ),
                    _radio(
                      'History',
                      'history',
                      _mapMode,
                      _setMapMode,
                      icon: Icons.history,
                    ),
                    _radio(
                      'Playback',
                      'playback',
                      _mapMode,
                      _setMapMode,
                      icon: Icons.play_arrow,
                    ),
                  ],
                ),
                ExpansionTile(
                  controller: _mapTypeController,
                  title: _sectionTitleWithIcon(Icons.layers, 'Map Type'),
                  initiallyExpanded: false,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(left: 16),
                  children: [
                    _radio(
                      'Standard',
                      'standard',
                      _mapType,
                      (v) => _setMapType(v),
                      icon: Icons.map,
                    ),
                    _radio(
                      'Satellite',
                      'satellite',
                      _mapType,
                      (v) => _setMapType(v),
                      icon: Icons.satellite_alt,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitleWithIcon(Icons.traffic, 'Traffic'),
                    Switch(
                      value: _trafficEnabled,
                      activeColor: cs.primary,
                      onChanged: (v) {
                        setState(() => _trafficEnabled = v);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitleWithIcon(IconData icon, String title) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: textSize + 4, color: cs.onSurface.withOpacity(0.9)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: textSize,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _radio(
    String label,
    String value,
    String group,
    ValueChanged<String> onTap, {
    IconData? icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final active = value == group;
    final screenWidth = MediaQuery.of(context).size.width;
    final textSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);

    const double radioSize = 18;
    final double iconSize = (textSize + 2).clamp(12.0, 20.0);

    return InkWell(
      onTap: () => onTap(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: iconSize,
                color: active ? cs.primary : cs.onSurface.withOpacity(0.8),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? cs.primary : cs.onSurface,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  fontSize: textSize - 2,
                ),
              ),
            ),
            _buildCircularRadio(active, cs.primary, radioSize),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularRadio(bool active, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? color : Colors.grey.withOpacity(0.5),
          width: 1.6,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: active ? size * 0.55 : 0,
          height: active ? size * 0.55 : 0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : Colors.transparent,
          ),
        ),
      ),
    );
  }
}
