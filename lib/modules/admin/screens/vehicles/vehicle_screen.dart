import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_vehicle_list_item.dart';
import 'package:fleet_stack/core/models/map_vehicle_point.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_vehicles_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  // Endpoint truth table (FleetStack-API-Reference.md):
  // - GET /admin/vehicles (query: search, status, page, limit)
  //   Key mapping: data.data.vehicles | data.vehicles | vehicles
  // - GET /admin/map-telemetry
  //   Key mapping: data.data | data.points | telemetry
  // - PATCH /admin/vehicles/:id  body: { isActive: bool }
  //   Used for switch toggle persistence.

  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();

  List<AdminVehicleListItem>? _items;
  bool _loading = false;
  bool _errorShown = false;

  CancelToken? _loadToken;
  final Map<String, bool> _updatingVehicle = <String, bool>{};
  final Map<String, CancelToken> _toggleTokens = <String, CancelToken>{};

  Timer? _searchDebounce;

  ApiClient? _apiClient;
  AdminVehiclesRepository? _repo;

  AdminVehiclesRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminVehiclesRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadVehicles();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Vehicles screen disposed');
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    for (final token in _toggleTokens.values) {
      token.cancel('Vehicles screen disposed');
    }
    _toggleTokens.clear();

    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _loadVehicles();
    });
  }

  String? _statusQueryForTab(String tab) {
    switch (tab) {
      case 'Running':
        return 'running';
      case 'Stopped':
        return 'stopped';
      default:
        return null;
    }
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  void _showLoadErrorOnce(String message) {
    if (_errorShown || !mounted) return;
    _errorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadVehicles() async {
    _loadToken?.cancel('Reload vehicles');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final result = await _repoOrCreate().getVehicles(
        search: _searchController.text.trim(),
        status: _statusQueryForTab(selectedTab),
        page: 1,
        limit: 100,
        cancelToken: token,
      );
      if (!mounted) return;

      await result.when(
        success: (items) async {
          var merged = items;
          if (items.isNotEmpty) {
            final telemetryResult = await _repoOrCreate().getTelemetry(
              cancelToken: token,
            );

            merged = telemetryResult.when(
              success: (points) => _mergeTelemetry(items, points),
              failure: (_) => items,
            );
          }

          if (kDebugMode) {
            debugPrint(
              '[Admin Vehicles] GET /admin/vehicles + /admin/map-telemetry '
              'status=2xx count=${merged.length}',
            );
          }

          if (!mounted) return;
          setState(() {
            _items = merged;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (err) async {
          if (!mounted) return;
          setState(() {
            _items = const <AdminVehicleListItem>[];
            _loading = false;
          });

          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load vehicles.'
              : "Couldn't load vehicles.";
          _showLoadErrorOnce(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const <AdminVehicleListItem>[];
        _loading = false;
      });
      _showLoadErrorOnce("Couldn't load vehicles.");
    }
  }

  List<AdminVehicleListItem> _mergeTelemetry(
    List<AdminVehicleListItem> source,
    List<MapVehiclePoint> points,
  ) {
    final byVehicleId = <String, MapVehiclePoint>{};
    final byImei = <String, MapVehiclePoint>{};

    for (final point in points) {
      final id = point.vehicleId.trim();
      if (id.isNotEmpty) {
        byVehicleId[id] = point;
      }
      final imei = point.imei.trim();
      if (imei.isNotEmpty) {
        byImei[imei] = point;
      }
    }

    return source.map((item) {
      final id = item.id.trim();
      final imei = item.imei.trim();
      final point = byVehicleId[id] ?? byImei[imei];
      if (point == null) return item;

      final raw = Map<String, dynamic>.from(item.raw);

      final mappedStatus = _normalizeTelemetryStatus(point.status);
      if (mappedStatus.isNotEmpty) {
        raw['motion'] = mappedStatus;
        raw['status'] = mappedStatus;
      }

      if (point.speed != null) {
        final speed = point.speed!;
        final text = speed == speed.roundToDouble()
            ? '${speed.toInt()} km/h'
            : '${speed.toStringAsFixed(1)} km/h';
        raw['speed'] = text;
      }

      final seen = point.updatedAt.trim();
      if (seen.isNotEmpty) {
        raw['lastActivityAt'] = seen;
        raw['last_activity'] = seen;
        raw['lastSeenAt'] = seen;
      }

      return AdminVehicleListItem.fromRaw(raw);
    }).toList();
  }

  String _normalizeTelemetryStatus(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return '';

    if (value.contains('run') || value.contains('move') || value == 'active') {
      return 'RUNNING';
    }
    if (value.contains('stop') ||
        value.contains('idle') ||
        value == 'inactive') {
      return 'STOPPED';
    }

    return raw.trim().toUpperCase();
  }

  List<AdminVehicleListItem> _applyLocalFilters(
    List<AdminVehicleListItem> source,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    bool tabMatch(AdminVehicleListItem item) {
      if (selectedTab == 'All') return true;
      final expected = selectedTab.toLowerCase();
      final actual = item.statusLabel.toLowerCase();
      if (expected == 'running') return actual.contains('running');
      if (expected == 'stopped') {
        return actual.contains('stop') || actual.contains('idle');
      }
      return true;
    }

    bool queryMatch(AdminVehicleListItem item) {
      if (query.isEmpty) return true;
      final fields = [
        item.nameModel,
        item.plateNumber,
        item.imei,
        item.vin,
        item.statusLabel,
        item.durationLabel,
        item.speedLabel,
        item.userDisplayName,
        item.primaryUserName,
        item.driverName,
        item.lastActivityAt,
        item.expiry,
      ];
      return fields.any((v) => v.toLowerCase().contains(query));
    }

    return source.where((v) => tabMatch(v) && queryMatch(v)).toList()..sort(
      (a, b) => _safeParseDateTime(
        b.lastActivityAt,
      ).compareTo(_safeParseDateTime(a.lastActivityAt)),
    );
  }

  DateTime _safeParseDateTime(String dateStr) {
    final text = dateStr.trim();
    if (text.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _safe(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return '—';
    if (trimmed.toLowerCase() == 'null') return '—';
    return trimmed;
  }

  Color _statusBgColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('run') || s.contains('active')) {
      return Colors.green.withOpacity(0.15);
    }
    if (s.contains('stop') || s.contains('idle') || s.contains('inactive')) {
      return Colors.red.withOpacity(0.15);
    }
    return Colors.orange.withOpacity(0.15);
  }

  Color _statusTextColor(String status, ColorScheme scheme) {
    final s = status.toLowerCase();
    if (s.contains('run') || s.contains('active')) {
      return Colors.green;
    }
    if (s.contains('stop') || s.contains('idle') || s.contains('inactive')) {
      return Colors.red;
    }
    return scheme.primary;
  }

  Future<void> _toggleVehicleActive(
    AdminVehicleListItem item,
    bool nextValue,
  ) async {
    final vehicleId = item.id.trim();
    if (vehicleId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vehicle ID is missing.')));
      return;
    }

    if (_updatingVehicle[vehicleId] == true) return;

    final previousValue = item.isActive ?? false;
    _setVehicleActiveOptimistic(vehicleId, nextValue);

    if (mounted) {
      setState(() {
        _updatingVehicle[vehicleId] = true;
      });
    }

    _toggleTokens[vehicleId]?.cancel('Replace vehicle toggle request');
    final token = CancelToken();
    _toggleTokens[vehicleId] = token;

    try {
      final result = await _repoOrCreate().updateVehicleStatus(
        vehicleId,
        nextValue,
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (_) {
          if (!mounted) return;
          setState(() {
            _updatingVehicle.remove(vehicleId);
            _toggleTokens.remove(vehicleId);
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _setVehicleActiveOptimistic(vehicleId, previousValue);
            _updatingVehicle.remove(vehicleId);
            _toggleTokens.remove(vehicleId);
          });

          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to update vehicle status.'
              : "Couldn't update vehicle status.";

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _setVehicleActiveOptimistic(vehicleId, previousValue);
        _updatingVehicle.remove(vehicleId);
        _toggleTokens.remove(vehicleId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update vehicle status.")),
      );
    }
  }

  void _setVehicleActiveOptimistic(String vehicleId, bool isActive) {
    final list = _items;
    if (list == null) return;

    final updated = list.map((item) {
      if (item.id != vehicleId) return item;

      final raw = Map<String, dynamic>.from(item.raw);
      raw['isActive'] = isActive;
      raw['active'] = isActive;
      raw['enabled'] = isActive;
      if (!isActive) {
        raw['motion'] = 'STOPPED';
        raw['status'] = 'STOPPED';
      }

      return AdminVehicleListItem.fromRaw(raw);
    }).toList();

    _items = updated;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double titleFs = AdaptiveUtils.getTitleFontSize(width);
    final double bodyFs = titleFs - 1;
    final double smallFs = titleFs - 3;
    final double iconSize = titleFs + 2;
    final double cardPadding = hp + 4;

    final allItems = _items ?? const <AdminVehicleListItem>[];
    final filteredVehicles = _applyLocalFilters(allItems);

    return AppLayout(
      title: 'ADMIN',
      subtitle: 'Vehicles Management',
      actionIcons: const [CupertinoIcons.add],
      showLeftAvatar: false,
      leftAvatarText: 'SA',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: hp * 3.5,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                  fontSize: bodyFs,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search model, IMEI, VIN, user...',
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: bodyFs,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    size: iconSize,
                    color: colorScheme.primary.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  focusColor: colorScheme.primary,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: Colors.transparent,
                      width: 0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: hp,
                    vertical: hp,
                  ),
                ),
              ),
            ),
            SizedBox(height: hp),

            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: ['All', 'Running', 'Stopped'].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () {
                    if (selectedTab == tab) return;
                    setState(() => selectedTab = tab);
                    _loadVehicles();
                  },
                );
              }).toList(),
            ),
            SizedBox(height: hp),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filteredVehicles.length} of ${allItems.length} vehicles',
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 1.5),

            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _loading
                  ? 3
                  : (filteredVehicles.isEmpty ? 1 : filteredVehicles.length),
              itemBuilder: (context, index) {
                if (_loading) {
                  return _buildShimmerCard(
                    colorScheme,
                    width,
                    hp,
                    spacing,
                    cardPadding,
                  );
                }

                if (filteredVehicles.isEmpty) {
                  return _buildEmptyStateCard(
                    colorScheme: colorScheme,
                    bodyFs: bodyFs,
                    smallFs: smallFs,
                    cardPadding: cardPadding,
                    hp: hp,
                  );
                }

                final vehicle = filteredVehicles[index];
                return _buildVehicleCardBody(
                  vehicle: vehicle,
                  colorScheme: colorScheme,
                  width: width,
                  spacing: spacing,
                  bodyFs: bodyFs,
                  smallFs: smallFs,
                  iconSize: iconSize,
                  cardPadding: cardPadding,
                  hp: hp,
                );
              },
            ),

            SizedBox(height: hp * 3),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required ColorScheme colorScheme,
    required double bodyFs,
    required double smallFs,
    required double cardPadding,
    required double hp,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(bottom: hp),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No vehicles found',
                  style: GoogleFonts.inter(
                    fontSize: bodyFs + 1,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask superadmin to assign vehicles.',
                  style: GoogleFonts.inter(
                    fontSize: smallFs + 1,
                    color: colorScheme.onSurface.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard(
    ColorScheme colorScheme,
    double width,
    double hp,
    double spacing,
    double cardPadding,
  ) {
    final avatarSize = AdaptiveUtils.getAvatarSize(width);

    return Container(
      margin: EdgeInsets.only(bottom: hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(
                  width: avatarSize,
                  height: avatarSize,
                  radius: avatarSize / 2,
                ),
                SizedBox(width: spacing * 1.5),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppShimmer(
                              width: 180,
                              height: 16,
                              radius: 8,
                            ),
                          ),
                          SizedBox(width: 8),
                          AppShimmer(width: 82, height: 24, radius: 12),
                        ],
                      ),
                      SizedBox(height: 8),
                      AppShimmer(width: 250, height: 14, radius: 7),
                      SizedBox(height: 8),
                      AppShimmer(width: 250, height: 14, radius: 7),
                      SizedBox(height: 8),
                      AppShimmer(width: 220, height: 14, radius: 7),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 2),
            Row(
              children: const [
                Expanded(child: AppShimmer(width: 140, height: 34, radius: 17)),
                SizedBox(width: 12),
                AppShimmer(width: 20, height: 20, radius: 10),
                SizedBox(width: 8),
                AppShimmer(width: 20, height: 20, radius: 10),
                SizedBox(width: 8),
                AppShimmer(width: 20, height: 20, radius: 10),
              ],
            ),
            SizedBox(height: spacing * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                AppShimmer(width: 180, height: 12, radius: 6),
                AppShimmer(width: 42, height: 22, radius: 11),
              ],
            ),
            SizedBox(height: spacing),
            Divider(color: colorScheme.outline.withOpacity(0.3)),
            SizedBox(height: spacing),
            const AppShimmer(width: 140, height: 12, radius: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCardBody({
    required AdminVehicleListItem? vehicle,
    required ColorScheme colorScheme,
    required double width,
    required double spacing,
    required double bodyFs,
    required double smallFs,
    required double iconSize,
    required double cardPadding,
    required double hp,
  }) {
    final isPlaceholder = vehicle == null;

    final vehicleId = vehicle?.id.trim() ?? '';
    final isUpdating = _updatingVehicle[vehicleId] == true;

    final model = _safe(vehicle?.nameModel);
    final motion = _safe(vehicle?.statusLabel);
    final imei = _safe(vehicle?.imei);
    final vin = _safe(vehicle?.vin);
    final duration = _safe(vehicle?.durationLabel);
    final speed = _safe(vehicle?.speedLabel);
    final initials = _safe(vehicle?.userInitials);
    final userName = _safe(vehicle?.userDisplayName);
    final lastActivity = _safe(vehicle?.lastActivityAt);
    final expiry = _safe(vehicle?.expiry);

    final ignition = vehicle?.ignitionOk;
    final gps = vehicle?.gpsOk;
    final locked = vehicle?.lockOk;

    final enabled = vehicle?.isActive ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(bottom: hp),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: isPlaceholder || vehicleId.isEmpty
                ? null
                : () => context.push('/admin/vehicles/details/$vehicleId'),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: AdaptiveUtils.getAvatarSize(width),
                        height: AdaptiveUtils.getAvatarSize(width),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.car_detailed,
                          size: AdaptiveUtils.getFsAvatarFontSize(width),
                          color: colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: spacing * 1.5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    model,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs + 2,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                SizedBox(width: spacing),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing + 4,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusBgColor(motion),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    motion,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs,
                                      fontWeight: FontWeight.w600,
                                      color: _statusTextColor(
                                        motion,
                                        colorScheme,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing / 2),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.device_laptop,
                                  size: iconSize,
                                  color: colorScheme.primary.withOpacity(0.6),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    'IMEI: $imei',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing / 2),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.tag,
                                  size: iconSize,
                                  color: colorScheme.primary.withOpacity(0.6),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    'VIN: $vin',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing / 2),
                            Row(
                              children: [
                                Icon(
                                  motion.toLowerCase().contains('run')
                                      ? CupertinoIcons.arrow_right
                                      : CupertinoIcons.stop,
                                  size: iconSize,
                                  color: motion.toLowerCase().contains('run')
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withOpacity(0.7),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    '$motion • $duration • $speed',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs - 1,
                                      color:
                                          motion.toLowerCase().contains('run')
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurface.withOpacity(
                                              0.7,
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing * 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: _userInfo(
                          initials,
                          userName,
                          width,
                          colorScheme,
                          spacing,
                          bodyFs,
                          smallFs,
                        ),
                      ),
                      SizedBox(width: spacing * 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ignition == null
                                ? CupertinoIcons.bolt_slash
                                : (ignition
                                      ? CupertinoIcons.bolt_fill
                                      : CupertinoIcons.bolt_slash_fill),
                            size: iconSize,
                            color: ignition == null
                                ? colorScheme.onSurface.withOpacity(0.45)
                                : (ignition ? colorScheme.primary : Colors.red),
                          ),
                          SizedBox(width: spacing * 2),
                          Icon(
                            gps == null
                                ? CupertinoIcons.location_slash
                                : (gps
                                      ? CupertinoIcons.location_fill
                                      : CupertinoIcons.location_slash_fill),
                            size: iconSize,
                            color: gps == null
                                ? colorScheme.onSurface.withOpacity(0.45)
                                : (gps ? colorScheme.primary : Colors.red),
                          ),
                          SizedBox(width: spacing * 2),
                          Icon(
                            locked == null
                                ? CupertinoIcons.lock_open
                                : (locked
                                      ? CupertinoIcons.lock_fill
                                      : CupertinoIcons.lock_open_fill),
                            size: iconSize,
                            color: locked == null
                                ? colorScheme.onSurface.withOpacity(0.45)
                                : (locked ? colorScheme.primary : Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: spacing * 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Last Activity: $lastActivity',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: smallFs + 1,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withOpacity(0.87),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.85,
                        child: IgnorePointer(
                          ignoring: isPlaceholder || isUpdating,
                          child: Switch(
                            value: enabled,
                            activeColor: colorScheme.onPrimary,
                            activeTrackColor: colorScheme.primary,
                            inactiveThumbColor: colorScheme.onSurfaceVariant,
                            inactiveTrackColor: colorScheme.surfaceVariant,
                            onChanged: isPlaceholder
                                ? null
                                : (v) => _toggleVehicleActive(vehicle, v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing),
                  Divider(color: colorScheme.outline.withOpacity(0.3)),
                  SizedBox(height: spacing),
                  Text(
                    'Expiry: $expiry',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: smallFs,
                      color: colorScheme.onSurface.withOpacity(0.54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _userInfo(
    String initials,
    String name,
    double width,
    ColorScheme scheme,
    double spacing,
    double bodyFs,
    double smallFs,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primary,
          child: Text(
            _safe(initials),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: scheme.onPrimary,
            ),
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Driver',
                style: GoogleFonts.inter(
                  fontSize: smallFs - 1,
                  color: scheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                _safe(name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: GoogleFonts.inter(
                  fontSize: bodyFs,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
