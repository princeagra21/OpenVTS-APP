// components/fleet/fleet_overview_box.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/superadmin_total_counts.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../../utils/adaptive_utils.dart';

class CustomBox extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double radius;

  const CustomBox({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.radius = 25.0, // default to 25 to match your design
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);

    return Container(
      width: width ?? double.infinity,
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
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
      child: child,
    );
  }
}

class FleetOverviewBox extends StatefulWidget {
  const FleetOverviewBox({super.key});

  @override
  State<FleetOverviewBox> createState() => _FleetOverviewBoxState();
}

class _FleetOverviewBoxState extends State<FleetOverviewBox> {
  SuperadminTotalCounts? _counts;
  bool _loadingCounts = false;
  bool _countsErrorShown = false;
  CancelToken? _countsCancelToken;

  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  @override
  void dispose() {
    _countsCancelToken?.cancel('FleetOverviewBox disposed');
    super.dispose();
  }

  Future<void> _loadCounts() async {
    _countsCancelToken?.cancel('Reload counts');
    final token = CancelToken();
    _countsCancelToken = token;

    if (!mounted) return;
    setState(() => _loadingCounts = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getTotalCounts(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (counts) {
          if (kDebugMode) {
            debugPrint(
              '[Home] GET /superadmin/dashboard/totalcounts status=2xx '
              'vehicles=${counts.totalVehicles} active=${counts.activeVehicles} '
              'users=${counts.totalUsers} admins=${counts.totalAdmins} '
              'issued=${counts.licensesIssued} used=${counts.licensesUsed}',
            );
          }
          if (!mounted) return;
          setState(() {
            _counts = counts;
            _loadingCounts = false;
            _countsErrorShown = false;
          });
        },
        failure: (err) {
          if (kDebugMode) {
            final status = err is ApiException ? err.statusCode : null;
            debugPrint(
              '[Home] GET /superadmin/dashboard/totalcounts status=${status ?? 'error'}',
            );
          }
          if (!mounted) return;
          setState(() => _loadingCounts = false);
          if (_countsErrorShown) return;
          _countsErrorShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't load counts.")),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCounts = false);
      if (_countsErrorShown) return;
      _countsErrorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't load counts.")));
    }
  }

  String _fmtInt(int v) => v.toString();

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    // Adaptive values from our design system
    final double titleFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) + 2;
    final double labelFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) + 1;
    final double valueFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) + 4;
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(
      screenWidth,
    ); // 6–10

    final counts = _counts;
    final totalVehicles = counts?.totalVehicles ?? 0;
    final activeVehicles = counts?.activeVehicles ?? 0;
    final totalUsers = counts?.totalUsers ?? 0;
    final totalAdmins = counts?.totalAdmins ?? 0;
    final licensesIssued = counts?.licensesIssued ?? 0;
    final licensesUsed = counts?.licensesUsed ?? 0;
    final showSkeleton = _loadingCounts;

    return CustomBox(
      radius: 25.0,
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

          // Summary cards (3 per row)
          LayoutBuilder(
            builder: (context, constraints) {
              final itemSpacing = spacing + 6;
              final maxWidth = constraints.maxWidth;
              final columns = 2;
              final totalSpacing = itemSpacing * (columns - 1);
              final itemWidth = (maxWidth - totalSpacing) / columns;

              if (showSkeleton) {
                return _summaryGridSkeleton(
                  itemWidth: itemWidth,
                  itemSpacing: itemSpacing,
                  columns: columns,
                  spacing: spacing,
                );
              }

                return Wrap(
                  spacing: itemSpacing,
                  runSpacing: itemSpacing,
                  children: [
                    _summaryCard(
                      context,
                      width: itemWidth,
                      title: 'ALL ADMINS',
                      value: _fmtInt(totalAdmins),
                      titleSize: labelFontSize,
                      valueSize: valueFontSize,
                      icon: Symbols.verified_user,
                      padding: spacing,
                    ),
                    _summaryCard(
                      context,
                      width: itemWidth,
                      title: 'TOTAL VEHICLES',
                      value: _fmtInt(totalVehicles),
                      titleSize: labelFontSize,
                      valueSize: valueFontSize,
                      icon: Symbols.directions_car,
                      padding: spacing,
                    ),
                    _summaryCard(
                      context,
                      width: itemWidth,
                      title: 'ACTIVE VEHICLES',
                      value: _fmtInt(activeVehicles),
                      titleSize: labelFontSize,
                      valueSize: valueFontSize,
                      icon: Symbols.bolt,
                      padding: spacing,
                    ),
                    _summaryCard(
                      context,
                      width: itemWidth,
                      title: 'TOTAL USERS',
                      value: _fmtInt(totalUsers),
                      titleSize: labelFontSize,
                      valueSize: valueFontSize,
                      icon: Symbols.group,
                      padding: spacing,
                    ),
                    _summaryCard(
                      context,
                      width: itemWidth,
                      title: 'LICENSES ISSUED',
                      value: _fmtInt(licensesIssued),
                      titleSize: labelFontSize,
                      valueSize: valueFontSize,
                      icon: Symbols.description,
                      padding: spacing,
                    ),
                    _summaryCard(
                      context,
                      width: itemWidth,
                      title: 'LICENSES USED',
                      value: _fmtInt(licensesUsed),
                      titleSize: labelFontSize,
                      valueSize: valueFontSize,
                      icon: Symbols.radio_button_checked,
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

  Widget _summaryGridSkeleton({
    required double itemWidth,
    required double itemSpacing,
    required int columns,
    required double spacing,
  }) {
    final itemHeight = spacing * 6 + 24;
    final totalItems = 6;
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
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 110),
      padding: EdgeInsets.symmetric(
        horizontal: padding + 2,
        vertical: padding + 20,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.onSurface.withOpacity(0.08),
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
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
              ),
              Icon(
                icon,
                size: titleSize + 6,
                color: cs.onSurface.withOpacity(0.5),
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
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
