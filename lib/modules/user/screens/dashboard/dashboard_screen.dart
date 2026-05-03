import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/user_fleet_status_summary.dart';
import 'package:fleet_stack/core/models/user_recent_alert_item.dart';
import 'package:fleet_stack/core/models/user_top_asset_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_home_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/user/components/appbars/user_home_appbar.dart';
import 'package:fleet_stack/modules/user/widgets/home/card/vehicle_status_box.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // FleetStack-API-Reference.md confirmed User Home endpoints:
  // - GET /user/dashboard/fleet-status
  // - GET /user/dashboard/recent-alerts
  // - GET /user/dashboard/top-performing-assets

  ApiClient? _api;
  UserHomeRepository? _repo;
  CancelToken? _loadToken;

  bool _loading = false;
  bool _errorShown = false;

  UserFleetStatusSummary? _fleetStatus;
  List<UserRecentAlertItem>? _recentAlerts;
  List<UserTopAssetItem>? _topAssets;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  @override
  void dispose() {
    _loadToken?.cancel('User home disposed');
    super.dispose();
  }

  UserHomeRepository _repoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserHomeRepository(api: _api!);
    return _repo!;
  }

  Future<void> _loadHome() async {
    _loadToken?.cancel('Reload user home');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    UserFleetStatusSummary? nextFleet = _fleetStatus;
    List<UserRecentAlertItem>? nextAlerts = _recentAlerts;
    List<UserTopAssetItem>? nextTopAssets = _topAssets;

    bool hasFailure = false;
    String? errorMessage;

    void captureFailure(Object error, String fallback) {
      if (error is ApiException &&
          error.message.trim() == 'Request cancelled') {
        return;
      }
      hasFailure = true;
      if (errorMessage == null || errorMessage!.trim().isEmpty) {
        if (error is ApiException && error.message.trim().isNotEmpty) {
          errorMessage = error.message;
        } else {
          errorMessage = fallback;
        }
      }
    }

    final repo = _repoOrCreate();

    final fleetRes = await repo.getFleetStatus(cancelToken: token);
    if (!mounted || token.isCancelled) return;
    fleetRes.when(
      success: (data) => nextFleet = data,
      failure: (error) => captureFailure(error, "Couldn't load fleet status."),
    );

    final alertsRes = await repo.getRecentAlerts(cancelToken: token);
    if (!mounted || token.isCancelled) return;
    alertsRes.when(
      success: (data) => nextAlerts = data,
      failure: (error) => captureFailure(error, "Couldn't load recent alerts."),
    );

    final topAssetsRes = await repo.getTopPerformingAssets(cancelToken: token);
    if (!mounted || token.isCancelled) return;
    topAssetsRes.when(
      success: (data) => nextTopAssets = data,
      failure: (error) =>
          captureFailure(error, "Couldn't load top performing assets."),
    );

    if (!mounted) return;
    setState(() {
      _fleetStatus = nextFleet;
      _recentAlerts = nextAlerts;
      _topAssets = nextTopAssets;
      _loading = false;
      if (!hasFailure) {
        _errorShown = false;
      }
    });

    if (!hasFailure || _errorShown || !mounted) return;
    _errorShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage ?? "Couldn't load dashboard.")),
    );
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
                UserFleetOverviewBox(
                  summary: _fleetStatus,
                  alertCount: _recentAlerts?.length,
                  loading: _loading,
                ),
                const SizedBox(height: 24),
                VehicleStatusBox(summary: _fleetStatus, loading: _loading),
                const SizedBox(height: 24),
                _RecentVehiclesSection(
                  assets: _topAssets ?? const <UserTopAssetItem>[],
                  loading: _loading,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: const UserHomeAppBar(
              title: 'Dashboard',
              leadingIcon: Symbols.grid_view,
            ),
          ),
        ],
      ),
    );
  }
}

class UserFleetOverviewBox extends StatelessWidget {
  final UserFleetStatusSummary? summary;
  final int? alertCount;
  final bool loading;

  const UserFleetOverviewBox({
    super.key,
    this.summary,
    this.alertCount,
    this.loading = false,
  });

  String _formatInt(int value) {
    final text = value.toString();
    return text.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  String _displayInt(int value) => summary == null ? '—' : _formatInt(value);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    final double titleFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) + 2;
    final double labelFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) + 1;
    final double valueFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) + 4;
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    final String totalVehicles = _displayInt(summary?.totalVehicles ?? 0);
    final String withDevice = _displayInt(summary?.withDevice ?? 0);
    final String noDevice = _displayInt(summary?.noDevice ?? 0);
    final String alerts =
        summary == null ? '—' : _formatInt(alertCount ?? 0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AdaptiveUtils.getHorizontalPadding(screenWidth)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.08),
          width: 1,
        ),
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
          Text(
            'Overview',
            style: AppUtils.headlineSmallBase.copyWith(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: spacing + 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemSpacing = spacing + 6;
              final maxWidth = constraints.maxWidth;
              final columns = 2;
              final totalSpacing = itemSpacing * (columns - 1);
              final itemWidth = (maxWidth - totalSpacing) / columns;

              if (loading) {
                final itemHeight = spacing * 6 + 24;
                final totalItems = 4;
                final rowCount = (totalItems / columns).ceil();
                final totalSlots = rowCount * columns;
                return Wrap(
                  spacing: itemSpacing,
                  runSpacing: itemSpacing,
                  children: List.generate(
                    totalSlots,
                    (_) => AppShimmer(
                      width: itemWidth,
                      height: itemHeight,
                      radius: 16,
                    ),
                  ),
                );
              }

              return Wrap(
                spacing: itemSpacing,
                runSpacing: itemSpacing,
                children: [
                  _summaryCard(
                    context,
                    width: itemWidth,
                    title: 'TOTAL VEHICLES',
                    value: totalVehicles,
                    titleSize: labelFontSize,
                    valueSize: valueFontSize,
                    icon: Symbols.directions_car,
                    padding: spacing,
                  ),
                  _summaryCard(
                    context,
                    width: itemWidth,
                    title: 'WITH DEVICE',
                    value: withDevice,
                    titleSize: labelFontSize,
                    valueSize: valueFontSize,
                    icon: Symbols.memory,
                    padding: spacing,
                  ),
                  _summaryCard(
                    context,
                    width: itemWidth,
                    title: 'NO DEVICE',
                    value: noDevice,
                    titleSize: labelFontSize,
                    valueSize: valueFontSize,
                    icon: Symbols.portable_wifi_off,
                    padding: spacing,
                  ),
                  _summaryCard(
                    context,
                    width: itemWidth,
                    title: 'ALERTS',
                    value: alerts,
                    titleSize: labelFontSize,
                    valueSize: valueFontSize,
                    icon: Symbols.notifications,
                    padding: spacing,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required double width,
    required String title,
    required String value,
    required double titleSize,
    required double valueSize,
    required IconData icon,
    required double padding,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 110),
      padding: EdgeInsets.symmetric(
        horizontal: padding + 2,
        vertical: padding + 20,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppUtils.bodySmallBase.copyWith(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ),
              Icon(
                icon,
                size: titleSize + 6,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
          SizedBox(height: padding + 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppUtils.headlineSmallBase.copyWith(
              fontSize: valueSize,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentVehiclesSection extends StatelessWidget {
  final List<UserTopAssetItem> assets;
  final bool loading;

  const _RecentVehiclesSection({
    required this.assets,
    required this.loading,
  });

  String _safeString(Object? value, {String fallback = '—'}) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _vehicleTypeLabel(UserTopAssetItem asset) {
    final raw = asset.raw;
    final vt = raw['vehicleType'];
    if (vt is Map) {
      final name = vt['name'] ?? vt['title'] ?? vt['type'] ?? vt['slug'];
      final s = _safeString(name, fallback: '');
      if (s.isNotEmpty) return s;
    }
    return _safeString(asset.subtitle, fallback: '—');
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

  String _assetTime(UserTopAssetItem item) {
    final raw = item.raw;
    return _safeString(
      raw['lastSeen'] ??
          raw['lastSeenAt'] ??
          raw['updatedAt'] ??
          raw['createdAt'] ??
          raw['timestamp'] ??
          '',
      fallback: '',
    );
  }

  String _assetStatus(UserTopAssetItem item) {
    final raw = item.raw;
    return _safeString(
      raw['statusLabel'] ??
          raw['status'] ??
          raw['vehicleStatus'] ??
          raw['state'] ??
          raw['health'] ??
          item.metricLabel,
      fallback: '—',
    );
  }

  Widget _buildVehicleSkeletonItem(double screenWidth) {
    return const AppShimmer(width: double.infinity, height: 64, radius: 12);
  }

  Widget _buildVehicleItem(
    BuildContext context,
    UserTopAssetItem asset,
    double screenWidth,
  ) {
    final cs = Theme.of(context).colorScheme;
    final bool small = screenWidth < 420;
    final double scale = small ? 0.9 : 1.0;
    final double mainRowFs = 14 * scale;
    final double secondaryFs = 12 * scale;
    final double metaFs = 11 * scale;

    final name = _safeString(
      asset.raw['plateNumber'] ?? asset.raw['vehicleNo'] ?? asset.title,
      fallback: '—',
    );
    final type = _vehicleTypeLabel(asset);
    final status = _assetStatus(asset);
    final timeRaw = _assetTime(asset);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey.shade50
                  : cs.surfaceVariant,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.directions_car_outlined,
              size: 18,
              color: cs.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  style: GoogleFonts.roboto(
                    fontSize: mainRowFs,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: secondaryFs,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey.shade50
                      : cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.roboto(
                    fontSize: metaFs,
                    height: 14 / 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _timeLabel(timeRaw),
                style: GoogleFonts.roboto(
                  fontSize: metaFs,
                  height: 14 / 11,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
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
              Text(
                'Recent Vehicles',
                style: AppUtils.headlineSmallBase.copyWith(
                  fontSize: sectionTitleFs,
                  height: 24 / 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => context.push('/user/vehicles'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: GoogleFonts.roboto(
                        fontSize: 14 * scale,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: cs.primary.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: cs.primary.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            Column(
              children: [
                _buildVehicleSkeletonItem(screenWidth),
                const SizedBox(height: 10),
                _buildVehicleSkeletonItem(screenWidth),
              ],
            )
          else if (assets.isEmpty)
            Text(
              'No recent vehicles',
              style: GoogleFonts.roboto(
                fontSize: linkFontSize,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withOpacity(0.6),
              ),
            )
          else
            Column(
              children: assets
                  .take(5)
                  .map((asset) => _buildVehicleItem(context, asset, screenWidth))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
