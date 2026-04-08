import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_dashboard_summary.dart';
import 'package:fleet_stack/core/models/admin_vehicle_preview_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_dashboard_repository.dart';
import 'package:fleet_stack/core/repositories/admin_vehicle_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/card/adoption_widget.dart';
import 'package:fleet_stack/modules/admin/components/card/fleet_card.dart';
import 'package:fleet_stack/modules/admin/components/card/vehicle_status_box.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:go_router/go_router.dart';

import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AdminDashboardSummary? _summary;
  List<AdminVehiclePreviewItem>? _vehiclePreview;
  bool _loading = false;
  bool _loadingVehiclesPreview = false;
  bool _errorShown = false;
  bool _vehiclesErrorShown = false;
  CancelToken? _token;
  CancelToken? _vehiclesToken;

  ApiClient? _api;
  AdminDashboardRepository? _repo;
  AdminVehicleRepository? _vehicleRepo;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadVehiclePreview();
  }

  @override
  void dispose() {
    _token?.cancel('Admin dashboard disposed');
    _vehiclesToken?.cancel('Admin dashboard disposed');
    super.dispose();
  }

  /// Confirmed API source (FleetStack-API-Reference.md):
  /// - GET /admin/dashboard/summary?rk=0[&currency=INR]
  /// Keys used:
  /// - totals.totalVehicles
  /// - totals.totalUsers
  /// - expiry.thisMonth
  /// - expired / expiredCount (if present)
  /// - vehicleLiveStatus.running/stop/inactive/noData
  Future<void> _loadSummary() async {
    _token?.cancel('Reload dashboard summary');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= AdminDashboardRepository(api: _api!);

      final res = await _repo!.getAdminDashboardSummary(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (data) {
          if (kDebugMode) {
            debugPrint(
              '[Admin Dashboard] GET /admin/dashboard/summary status=2xx '
              'vehicles=${data.totalVehicles} users=${data.totalUsers} '
              'expiring30d=${data.expiring30d} expired=${data.expired} '
              'running=${data.running} stop=${data.stop} '
              'notWorking=${data.notWorking48h} noData=${data.noData}',
            );
          }

          if (!mounted) return;
          setState(() {
            _summary = data;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (error) {
          if (kDebugMode) {
            final status = error is ApiException ? error.statusCode : null;
            debugPrint(
              '[Admin Dashboard] GET /admin/dashboard/summary '
              'status=${status ?? 'error'}',
            );
          }

          if (!mounted) return;
          setState(() {
            _summary = null;
            _loading = false;
          });

          if (_errorShown) return;
          _errorShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't load dashboard summary.")),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary = null;
        _loading = false;
      });
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load dashboard summary.")),
      );
    }
  }

  Future<void> _loadVehiclePreview() async {
    _vehiclesToken?.cancel('Reload vehicle preview');
    final token = CancelToken();
    _vehiclesToken = token;

    if (!mounted) return;
    setState(() => _loadingVehiclesPreview = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _vehicleRepo ??= AdminVehicleRepository(api: _api!);

      final listRes = await _vehicleRepo!.getVehiclePreviewList(
        limit: 5,
        cancelToken: token,
      );
      if (!mounted) return;

      await listRes.when(
        success: (items) async {
          var merged = items;

          if (items.isNotEmpty) {
            final ids = items
                .map((e) => e.id.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            final imeis = items
                .map((e) => e.imei.trim())
                .where((e) => e.isNotEmpty)
                .toList();

            final liveRes = await _vehicleRepo!.getVehicleLiveStatus(
              vehicleIds: ids,
              imeis: imeis,
              cancelToken: token,
            );

            merged = liveRes.when(
              success: (statusMap) {
                return items.map((item) {
                  final byId = statusMap[item.id.trim()];
                  final byImei = statusMap[item.imei.trim()];
                  return item.withLiveStatus(byId ?? byImei);
                }).toList();
              },
              failure: (_) => items,
            );
          }

          if (kDebugMode) {
            debugPrint(
              '[Admin Dashboard] GET /admin/vehicles + /admin/map-telemetry '
              'status=2xx count=${merged.length}',
            );
          }

          if (!mounted) return;
          setState(() {
            _vehiclePreview = merged;
            _loadingVehiclesPreview = false;
            _vehiclesErrorShown = false;
          });
        },
        failure: (error) async {
          if (kDebugMode) {
            final status = error is ApiException ? error.statusCode : null;
            debugPrint(
              '[Admin Dashboard] GET /admin/vehicles status=${status ?? 'error'}',
            );
          }

          if (!mounted) return;
          setState(() {
            _vehiclePreview = null;
            _loadingVehiclesPreview = false;
          });

          if (_vehiclesErrorShown) return;
          _vehiclesErrorShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't load vehicles preview.")),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _vehiclePreview = null;
        _loadingVehiclesPreview = false;
      });
      if (_vehiclesErrorShown) return;
      _vehiclesErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load vehicles preview.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(screenWidth)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(screenWidth)
            ? 10.0
            : 12.0;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding + AppUtils.appBarHeightCustom + 28,
              horizontalPadding,
              84,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FleetOverviewBox(summary: _summary, loading: _loading),
                const SizedBox(height: 24),
                // const AdoptionGrowthBox(),
                // const SizedBox(height: 24),
                VehicleStatusBox(summary: _summary, loading: _loading),
                const SizedBox(height: 24),
                _RecentVehiclesSection(
                  vehicles: _vehiclePreview ?? const <AdminVehiclePreviewItem>[],
                  loading: _loadingVehiclesPreview,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: const AdminHomeAppBar(
              title: 'Dashboard',
              leadingIcon: Symbols.grid_view,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentVehiclesSection extends StatelessWidget {
  final List<AdminVehiclePreviewItem> vehicles;
  final bool loading;

  const _RecentVehiclesSection({
    required this.vehicles,
    required this.loading,
  });

  String _safeString(Object? value, {String fallback = '—'}) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _vehicleTypeLabel(AdminVehiclePreviewItem v) {
    final raw = v.raw;
    final vt = raw['vehicleType'];
    if (vt is Map) {
      final name = vt['name'] ?? vt['title'] ?? vt['type'] ?? vt['slug'];
      final s = _safeString(name, fallback: '');
      if (s.isNotEmpty) return s;
    }
    return '—';
  }

  String _formatDateOnly(Object? value) {
    final raw = _safeString(value, fallback: '');
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final date = parsed.toLocal();
    final m = months[date.month - 1];
    return '${date.day} $m ${date.year}';
  }

  String _formatDate(Object? value) {
    final raw = _safeString(value, fallback: '');
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = months[local.month - 1];
    return '${local.day} $m, $hour:$minute $amPm';
  }

  String _timeLabel(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return _formatDateOnly(raw);
    final diff = DateTime.now().toUtc().difference(parsed.toUtc());
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays <= 7) return '${diff.inDays}d ago';
    return _formatDateOnly(raw);
  }

  Widget _buildVehicleSkeletonItem(double screenWidth) {
    final itemPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final avatarSize = AdaptiveUtils.getAvatarSize(screenWidth) / 1.2;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding),
      child: Row(
        children: [
          AppShimmer(width: avatarSize, height: avatarSize, radius: avatarSize),
          SizedBox(width: itemPadding + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(
                  width: screenWidth * 0.3,
                  height: itemPadding + 10,
                  radius: 6,
                ),
                SizedBox(height: itemPadding / 1.5),
                AppShimmer(
                  width: screenWidth * 0.45,
                  height: itemPadding + 8,
                  radius: 6,
                ),
              ],
            ),
          ),
          SizedBox(width: itemPadding + 2),
          AppShimmer(
            width: screenWidth * 0.2,
            height: itemPadding + 10,
            radius: 999,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleItem(
    BuildContext context,
    AdminVehiclePreviewItem vehicle,
    double screenWidth,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool small = screenWidth < 420;
    final double scale = small ? 0.9 : 1.0;
    final double mainFontSize = 14 * scale;
    final double subFontSize = 12 * scale;
    final double badgeFontSize = 11 * scale;
    final double itemPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    final name = _safeString(vehicle.plateNumber, fallback: '—');
    final type = _vehicleTypeLabel(vehicle);
    final status = _safeString(vehicle.statusLabel, fallback: '—');
    final timeRaw = vehicle.lastSeenRaw;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding / 2),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: itemPadding,
          vertical: itemPadding,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.onSurface.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.1,
              backgroundColor: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[200]
                  : colorScheme.surfaceVariant,
              child: Icon(
                Icons.directions_car_outlined,
                size: 18 * scale,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(width: itemPadding + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: mainFontSize,
                      fontWeight: FontWeight.w600,
                      height: 20 / 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: subFontSize,
                            fontWeight: FontWeight.w500,
                            height: 16 / 12,
                            color: colorScheme.onSurface.withOpacity(0.54),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            _formatDate(timeRaw),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: subFontSize,
                              fontWeight: FontWeight.w500,
                              height: 16 / 12,
                              color: colorScheme.onSurface.withOpacity(0.54),
                            ),
                          ),
                        ),
                      ),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: itemPadding + 2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: itemPadding - 2,
                    vertical: itemPadding - 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[100]
                        : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.roboto(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.w600,
                      height: 14 / 11,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeLabel(timeRaw),
                  style: GoogleFonts.roboto(
                    fontSize: subFontSize,
                    fontWeight: FontWeight.w500,
                    height: 16 / 12,
                    color: colorScheme.onSurface.withOpacity(0.54),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cs = Theme.of(context).colorScheme;
    final pad = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final bool small = screenWidth < 420;
    final double scale = small ? 0.9 : 1.0;
    final double sectionTitleFs = 18 * scale;
    final double linkFontSize = 14 * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[100]
                      : cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.directions_car_outlined,
                  size: 18,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Recent Vehicles',
                      style: GoogleFonts.roboto(
                        fontSize: sectionTitleFs,
                        height: 24 / 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    if (loading)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: AppShimmer(
                            width: 14,
                            height: 14,
                            radius: 7,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: pad - 2),
          SizedBox(
            height: 320,
            child: loading
                ? ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, __) =>
                        _buildVehicleSkeletonItem(screenWidth),
                  )
                : vehicles.isEmpty
                    ? Center(
                        child: Text(
                          'No recent vehicles',
                          style: GoogleFonts.roboto(
                            fontSize: linkFontSize,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(0.54),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: vehicles.length > 5 ? 5 : vehicles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) => _buildVehicleItem(
                          context,
                          vehicles[index],
                          screenWidth,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
