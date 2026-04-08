// components/fleet/fleet_overview_box.dart
import 'package:fleet_stack/core/models/admin_dashboard_summary.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
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
    this.radius = 25.0,
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

class FleetOverviewBox extends StatelessWidget {
  final AdminDashboardSummary? summary;
  final bool loading;

  const FleetOverviewBox({super.key, this.summary, this.loading = false});

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
    final String users = _displayInt(summary?.totalUsers ?? 0);
    final String expiring30d = _displayInt(summary?.expiring30d ?? 0);
    final String expired = _displayInt(summary?.expired ?? 0);

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
          LayoutBuilder(
            builder: (context, constraints) {
              final itemSpacing = spacing + 6;
              final maxWidth = constraints.maxWidth;
              final columns = 2;
              final totalSpacing = itemSpacing * (columns - 1);
              final itemWidth = (maxWidth - totalSpacing) / columns;

              if (loading) {
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
                    title: 'TOTAL USERS',
                    value: users,
                    titleSize: labelFontSize,
                    valueSize: valueFontSize,
                    icon: Symbols.group,
                    padding: spacing,
                  ),
                  _summaryCard(
                    context,
                    width: itemWidth,
                    title: 'EXPIRING (30D)',
                    value: expiring30d,
                    titleSize: labelFontSize,
                    valueSize: valueFontSize,
                    icon: Symbols.schedule,
                    padding: spacing,
                  ),
                  _summaryCard(
                    context,
                    width: itemWidth,
                    title: 'EXPIRED',
                    value: expired,
                    titleSize: labelFontSize,
                    valueSize: valueFontSize,
                    icon: Symbols.cancel,
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
